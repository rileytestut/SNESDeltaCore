//
//  SNESEmulatorBridge.m
//  SNESDeltaCore
//
//  Created by Riley Testut on 9/12/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//

#import "SNESEmulatorBridge.h"

// Snes9x
#include "snes9x.h"
#include "apu.h"
#include "snapshot.h"
#include "snes9x/memmap.h"
#include "controls.h"
#include "display.h"
#include "snes9x/cheats.h"

// System
#include <sys/time.h>

// DeltaCore
#import <SNESDeltaCore/SNESDeltaCore.h>
#import <DeltaCore/DeltaCore.h>
#import <DeltaCore/DeltaCore-Swift.h>

#if STATIC_LIBRARY
#import "SNESDeltaCore-Swift.h"
#else
#import <SNESDeltaCore/SNESDeltaCore-Swift.h>
#endif

class ConfigFile;

@interface SNESEmulatorBridge () <DLTAEmulatorBridging>

@property (nonatomic, copy, nullable, readwrite) NSURL *gameURL;

@end

void SNESFinalizeSamplesCallback(void *context);

@implementation SNESEmulatorBridge
@synthesize gameURL = _gameURL;
@synthesize audioRenderer = _audioRenderer;
@synthesize videoRenderer = _videoRenderer;
@synthesize saveUpdateHandler = _saveUpdateHandler;

+ (instancetype)sharedBridge
{
    static SNESEmulatorBridge *_emulatorBridge = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _emulatorBridge = [[self alloc] init];
    });
    
    return _emulatorBridge;
}

#pragma mark - Emulation -

- (void)startWithGameURL:(NSURL *)URL
{
    [self stop];
    
    self.gameURL = URL;
    
    memset(&Settings, 0, sizeof(Settings));
    Settings.MouseMaster = YES;
    Settings.SuperScopeMaster = YES;
    Settings.JustifierMaster = YES;
    Settings.MultiPlayer5Master = YES;
    Settings.FrameTimePAL = 20000;
    Settings.FrameTimeNTSC = 16667;
    Settings.SixteenBitSound = YES;
    Settings.Stereo = YES;
    Settings.SoundPlaybackRate = 32040;
    Settings.SoundInputRate = 32040;
    Settings.SupportHiRes = NO;
    Settings.Transparency = YES;
    Settings.AutoDisplayMessages = YES;
    Settings.InitialInfoStringTimeout = 120;
    Settings.HDMATimingHack = 100;
    Settings.BlockInvalidVRAMAccessMaster = YES;
    Settings.StopEmulation = YES;
    Settings.WrongMovieStateProtection = YES;
    Settings.DumpStreamsMaxFrames = -1;
    Settings.StretchScreenshots = 1;
    Settings.SnapshotScreenshots = YES;
    Settings.SkipFrames = AUTO_FRAMERATE;
    Settings.TurboSkipFrames = 4;
    Settings.CartAName[0] = 0;
    Settings.CartBName[0] = 0;
    Settings.AutoSaveDelay = 1;
    
    S9xSetSoundMute(YES);
    
    CPU.Flags = 0;
    
    if (!Memory.Init() || !S9xInitAPU())
    {
        fprintf(stderr, "Snes9x: Memory allocation failure - not enough RAM/virtual memory available.\nExiting...\n");
        Memory.Deinit();
        S9xDeinitAPU();
        exit(1);
    }
    
    int milliseconds = 16;
    S9xInitSound(milliseconds, 0);
    
    S9xSetRenderPixelFormat(RGB565);
    
    S9xUnmapAllControls();
    S9xSetController(0, CTL_JOYPAD, 0, 0, 0, 0);
    S9xSetController(1, CTL_JOYPAD, 1, 0, 0, 0);
    
    for (int player = 1; player <= 8; player++)
    {
        NSUInteger mask = player << 16;
        
        S9xMapButton(mask | SNESGameInputUp, S9xGetCommandT([[[NSString stringWithFormat:@"Joypad%d ", player] stringByAppendingString:@"Up"] UTF8String]), NO);
        S9xMapButton(mask | SNESGameInputDown, S9xGetCommandT([[[NSString stringWithFormat:@"Joypad%d ", player] stringByAppendingString:@"Down"] UTF8String]), NO);
        S9xMapButton(mask | SNESGameInputLeft, S9xGetCommandT([[[NSString stringWithFormat:@"Joypad%d ", player] stringByAppendingString:@"Left"] UTF8String]), NO);
        S9xMapButton(mask | SNESGameInputRight, S9xGetCommandT([[[NSString stringWithFormat:@"Joypad%d ", player] stringByAppendingString:@"Right"] UTF8String]), NO);
        S9xMapButton(mask | SNESGameInputA, S9xGetCommandT([[[NSString stringWithFormat:@"Joypad%d ", player] stringByAppendingString:@"A"] UTF8String]), NO);
        S9xMapButton(mask | SNESGameInputB, S9xGetCommandT([[[NSString stringWithFormat:@"Joypad%d ", player] stringByAppendingString:@"B"] UTF8String]), NO);
        S9xMapButton(mask | SNESGameInputX, S9xGetCommandT([[[NSString stringWithFormat:@"Joypad%d ", player] stringByAppendingString:@"X"] UTF8String]), NO);
        S9xMapButton(mask | SNESGameInputY, S9xGetCommandT([[[NSString stringWithFormat:@"Joypad%d ", player] stringByAppendingString:@"Y"] UTF8String]), NO);
        S9xMapButton(mask | SNESGameInputL, S9xGetCommandT([[[NSString stringWithFormat:@"Joypad%d ", player] stringByAppendingString:@"L"] UTF8String]), NO);
        S9xMapButton(mask | SNESGameInputR, S9xGetCommandT([[[NSString stringWithFormat:@"Joypad%d ", player] stringByAppendingString:@"R"] UTF8String]), NO);
        S9xMapButton(mask | SNESGameInputStart, S9xGetCommandT([[[NSString stringWithFormat:@"Joypad%d ", player] stringByAppendingString:@"Start"] UTF8String]), NO);
        S9xMapButton(mask | SNESGameInputSelect, S9xGetCommandT([[[NSString stringWithFormat:@"Joypad%d ", player] stringByAppendingString:@"Select"] UTF8String]), NO);
    }
    
    S9xReportControllers();
    
    if (!Memory.LoadROM(URL.path.fileSystemRepresentation))
    {
        fprintf(stderr, "Error opening the ROM file.\n");
        exit(1);
    }
    
    Settings.StopEmulation = NO;
    
    GFX.Pitch = 512;
    GFX.Screen = (uint16 *)self.videoRenderer.videoBuffer;
    
    S9xGraphicsInit();
    
    sprintf(String, "\"%s\" %s: %s", Memory.ROMName, TITLE, VERSION);
    
    S9xSetSoundMute(NO);
    
    S9xSetSamplesAvailableCallback(SNESFinalizeSamplesCallback, NULL);
}

- (void)stop
{
    S9xGraphicsDeinit();
    Memory.Deinit();
    S9xDeinitAPU();
    
    Settings.Paused = YES;
}

- (void)pause
{
    S9xSetSoundMute(YES);
    
    Settings.Paused = YES;
}

- (void)resume
{
    S9xSetSoundMute(NO);
    
    Settings.Paused = NO;
}

#pragma mark - Game Loop -

- (void)runFrameAndProcessVideo:(BOOL)processVideo
{
    S9xMainLoop();
    
    if (processVideo)
    {
        [self.videoRenderer processFrame];
    }
}

#pragma mark - Inputs -

- (void)activateInput:(NSInteger)gameInput value:(double)value at:(NSInteger)playerIndex
{
    NSUInteger mask = (playerIndex + 1) << 16;
    S9xReportButton(mask | (uint32)gameInput, YES);
}

- (void)deactivateInput:(NSInteger)gameInput at:(NSInteger)playerIndex
{
    NSUInteger mask = (playerIndex + 1) << 16;
    S9xReportButton(mask | (uint32)gameInput, NO);
}

- (void)resetInputs
{
    for (int playerIndex = 0; playerIndex < 8; playerIndex++)
    {
        [self deactivateInput:SNESGameInputUp at:playerIndex];
        [self deactivateInput:SNESGameInputDown at:playerIndex];
        [self deactivateInput:SNESGameInputLeft at:playerIndex];
        [self deactivateInput:SNESGameInputRight at:playerIndex];
        [self deactivateInput:SNESGameInputA at:playerIndex];
        [self deactivateInput:SNESGameInputB at:playerIndex];
        [self deactivateInput:SNESGameInputX at:playerIndex];
        [self deactivateInput:SNESGameInputY at:playerIndex];
        [self deactivateInput:SNESGameInputL at:playerIndex];
        [self deactivateInput:SNESGameInputR at:playerIndex];
        [self deactivateInput:SNESGameInputStart at:playerIndex];
        [self deactivateInput:SNESGameInputSelect at:playerIndex];
    }
}

#pragma mark - Audio -

- (void)renderAudioSamples
{
    S9xFinalizeSamples();
    
    int sampleCount = MIN((int)self.audioRenderer.audioBuffer.availableBytesForWriting / 2, S9xGetSampleCount());
    
    void *buffer = malloc(sampleCount * 2); // Audio is interleaved, so we multiply by two to account for both channels
    S9xMixSamples((uint8 *)buffer, sampleCount);
    
    [self.audioRenderer.audioBuffer writeBuffer:(uint8_t *)buffer size:sampleCount * 2];
    
    free(buffer);
}

#pragma mark - Save States -

- (void)saveSaveStateToURL:(NSURL *)URL
{
    S9xFreezeGame(URL.path.fileSystemRepresentation);
}

- (void)loadSaveStateFromURL:(NSURL *)URL
{
    S9xUnfreezeGame(URL.path.fileSystemRepresentation);
}

#pragma mark - Cheats -

- (BOOL)addCheatCode:(NSString *)cheatCode type:(NSString *)type
{
    NSArray<NSString *> *codes = [cheatCode componentsSeparatedByString:@"\n"];
    for (NSString *code in codes)
    {
        BOOL success = YES;
        
        uint32 address = 0;
        uint8 byte = 0;
        
        if ([type isEqualToString:CheatTypeGameGenie])
        {
            success = (S9xGameGenieToRaw([code UTF8String], address, byte) == NULL);
        }
        else if ([type isEqualToString:CheatTypeActionReplay])
        {
            success = (S9xProActionReplayToRaw([code UTF8String], address, byte) == NULL);
        }
        else
        {
            success = NO;
        }
        
        if (!success)
        {
            return NO;
        }
        
        S9xAddCheat(true, true, address, byte);
    }
        
    return YES;
}

- (void)resetCheats
{
    S9xDeleteCheats();
}

- (void)updateCheats
{
    Settings.ApplyCheats = true;
    S9xApplyCheats();
}

#pragma mark - Game Saves -

- (void)saveGameSaveToURL:(NSURL *)URL
{
    Memory.SaveSRAM(URL.path.fileSystemRepresentation);
    sync();
}

- (void)loadGameSaveFromURL:(NSURL *)URL
{
    Memory.LoadSRAM(URL.path.fileSystemRepresentation);
}

#pragma mark - Getters/Setters -

- (NSTimeInterval)frameDuration
{
    NSTimeInterval frameDuration = Settings.PAL ? (1.0 / 50.0) : (1.0 / 60.0);
    return frameDuration;
}

@end

#pragma mark - SNESEmulatorBridge Callbacks -

void SNESFinalizeSamplesCallback(void *context)
{
    [[SNESEmulatorBridge sharedBridge] renderAudioSamples];
}

#pragma mark - Snes9x Callbacks -

void S9xSyncSpeed()
{
}

void _splitpath(const char *path, char *drive, char *dir, char *fname, char *ext)
{
    char *slash = strrchr ((char *) path, SLASH_CHAR);
    char *dot   = strrchr ((char *) path, '.');
    
    *drive = '\0';
    
    if (dot && slash && dot < slash)
    {
        dot = 0;
    }
    
    if (!slash)
    {
        *dir = '\0';
        strcpy (fname, path);
        
        if (dot)
        {
            fname[dot - path] = '\0';
            strcpy (ext, dot + 1);
        }
        else
        {
            *ext = '\0';
        }
    }
    else
    {
        strcpy (dir, path);
        dir[slash - path] = '\0';
        strcpy (fname, slash + 1);
        
        if (dot)
        {
            fname[(dot - slash) - 1] = '\0';
            strcpy (ext, dot + 1);
        }
        else
        {
            *ext = '\0';
        }
    }
}

void _makepath(char *path, const char *drive, const char *dir, const char *fname, const char *ext)
{
    if (dir && *dir)
    {
        strcpy (path, dir);
        strcat (path, "/");
    }
    else
        *path = '\0';
    
    strcat (path, fname);
    
    if (ext && *ext)
    {
        strcat (path, ".");
        strcat (path, ext);
    }
}

bool8 S9xOpenSnapshotFile(const char *fname, bool8 read_only, STREAM *file)
{
    if (read_only)
    {
        if (0 != (*file = OPEN_STREAM(fname, "rb")))
        {
            return YES;
        }
        
    }
    else
    {
        if (0 != (*file = OPEN_STREAM(fname, "wb")))
        {
            return YES;
        }
    }
    
    return NO;
}

void S9xCloseSnapshotFile(STREAM file)
{
    CLOSE_STREAM(file);
}

void S9xToggleSoundChannel(int c)
{
    static int sound_switch = 255;
    
    if (c == 8)
    {
        sound_switch = 255;
    }
    else
    {
        sound_switch ^= 1 << c;
    }
    
    S9xSetSoundControl (sound_switch);
}

bool S9xPollPointer(uint32 identifier, int16 *x, int16 *y)
{
    *x = 0;
    *y = 0;
    
    return YES;
}

void S9xMessage(int type, int number, const char *message)
{
    printf("%s\n", message);
}

const char *S9xBasename(const char *path)
{
    NSString *filename = [[[SNESEmulatorBridge sharedBridge] gameURL] lastPathComponent];
    return filename.fileSystemRepresentation;
}

const char *S9xGetDirectory (enum s9x_getdirtype dirtype)
{
    NSURL *directoryURL = [[[SNESEmulatorBridge sharedBridge] gameURL] URLByDeletingLastPathComponent];
    return directoryURL.path.fileSystemRepresentation;
}

void S9xAutoSaveSRAM()
{
    [SNESEmulatorBridge sharedBridge].saveUpdateHandler();
}

bool8 S9xDeinitUpdate(int width, int height)
{    
    return YES;
}

const char *S9xGetFilename(const char* UTF8Extension, enum s9x_getdirtype dirtype)
{
    NSString *extension = [NSString stringWithUTF8String:UTF8Extension];
    
    NSURL *fileURL = [[[[SNESEmulatorBridge sharedBridge] gameURL] URLByDeletingPathExtension] URLByAppendingPathExtension:extension];
    return fileURL.path.fileSystemRepresentation;
}

const char *S9xGetFilenameInc(const char *UTF8Extension, enum s9x_getdirtype dirtype)
{
    return NULL;
}

const char *S9xStringInput(const char* s)
{
    return NULL;
}

const char *S9xChooseFilename(bool8 read_only)
{
    return NULL;
}

const char *S9xChooseMovieFilename(bool8 read_only)
{
    return NULL;
}

bool8 S9xOpenSoundDevice()
{
    return YES;
}

bool8 S9xInitUpdate()
{
    return YES;
}

bool8 S9xDoScreenshot(int width, int height)
{
    return YES;
}

bool8 S9xContinueUpdate(int width, int height)
{
    return YES;
}

bool S9xPollButton(uint32 identifier, bool *pressed)
{
    return YES;
}

bool S9xPollAxis(uint32 id, int16* value)
{
    return NO;
}

void S9xHandlePortCommand(s9xcommand_t cmd, int16 data1, int16 data2)
{

}

void S9xParsePortConfig(ConfigFile &a, int pass)
{
    
}

void S9xParseArg(char** a, int &b, int c)
{
    
}

void S9xExtraUsage()
{
    
}

void S9xSetPalette()
{
    
}

void S9xExit()
{
    
}
