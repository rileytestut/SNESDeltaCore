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
#include "memmap.h"
#include "controls.h"
#include "conffile.h"
#include "display.h"
#include "cheats.h"

// System
#include <sys/time.h>

// DeltaCore
#import <DeltaCore/DeltaCore-Swift.h>

void SNESFinalizeSamplesCallback(void *context);

@implementation SNESEmulatorBridge

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
    [super startWithGameURL:URL];
        
    ZeroMemory(&Settings, sizeof(Settings));
    Settings.MouseMaster = YES;
    Settings.SuperScopeMaster = YES;
    Settings.JustifierMaster = YES;
    Settings.MultiPlayer5Master = YES;
    Settings.FrameTimePAL = 20000;
    Settings.FrameTimeNTSC = 16667;
    Settings.SixteenBitSound = YES;
    Settings.Stereo = YES;
    Settings.SoundPlaybackRate = 32000;
    Settings.SoundInputRate = 32000;
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
    
    int preferredBufferSize = (Settings.SoundPlaybackRate / 60) * 4;
    S9xInitSound(preferredBufferSize, 0);
    
    S9xSetRenderPixelFormat(RGB565);
    
    S9xReset();
    
    S9xUnmapAllControls();
    S9xSetController(0, CTL_JOYPAD, 0, 0, 0, 0);
    
    S9xMapButton(SNESGameInputUp, S9xGetCommandT("Joypad1 Up"), NO);
    S9xMapButton(SNESGameInputDown, S9xGetCommandT("Joypad1 Down"), NO);
    S9xMapButton(SNESGameInputLeft, S9xGetCommandT("Joypad1 Left"), NO);
    S9xMapButton(SNESGameInputRight, S9xGetCommandT("Joypad1 Right"), NO);
    S9xMapButton(SNESGameInputA, S9xGetCommandT("Joypad1 A"), NO);
    S9xMapButton(SNESGameInputB, S9xGetCommandT("Joypad1 B"), NO);
    S9xMapButton(SNESGameInputX, S9xGetCommandT("Joypad1 X"), NO);
    S9xMapButton(SNESGameInputY, S9xGetCommandT("Joypad1 Y"), NO);
    S9xMapButton(SNESGameInputL, S9xGetCommandT("Joypad1 L"), NO);
    S9xMapButton(SNESGameInputR, S9xGetCommandT("Joypad1 R"), NO);
    S9xMapButton(SNESGameInputStart, S9xGetCommandT("Joypad1 Start"), NO);
    S9xMapButton(SNESGameInputSelect, S9xGetCommandT("Joypad1 Select"), NO);
    
    S9xReportControllers();
    
    if (!Memory.LoadROM(URL.path.fileSystemRepresentation))
    {
        fprintf(stderr, "Error opening the ROM file.\n");
        exit(1);
    }
    
    Settings.StopEmulation = NO;
    
    GFX.Pitch = 512 * 2;
    GFX.Screen = (uint16 *)self.videoRenderer.videoBuffer;
    
    S9xGraphicsInit();
    
    sprintf(String, "\"%s\" %s: %s", Memory.ROMName, TITLE, VERSION);
    
    S9xSetSoundMute(NO);
    
    S9xSetSamplesAvailableCallback(SNESFinalizeSamplesCallback, NULL);
}

- (void)stop
{
    [super stop];
    
    S9xGraphicsDeinit();
    Memory.Deinit();
    S9xDeinitAPU();
    
    Settings.Paused = YES;
}

- (void)pause
{
    [super pause];
    
    S9xSetSoundMute(YES);
    
    Settings.Paused = YES;
}

- (void)resume
{
    [super resume];
    
    S9xSetSoundMute(NO);
    
    Settings.Paused = NO;
}

#pragma mark - Game Loop -

- (void)runFrame
{
    S9xMainLoop();
}

#pragma mark - Inputs -

- (void)activateInput:(NSInteger)gameInput
{
    S9xReportButton((uint32)gameInput, YES);
}

- (void)deactivateInput:(NSInteger)gameInput
{
    S9xReportButton((uint32)gameInput, NO);
}

#pragma mark - Audio -

- (void)renderAudioSamples
{
    S9xFinalizeSamples();
    
    [self.audioRenderer.ringBuffer writeWithHandler:^int32_t(void * _Nonnull ringBuffer, int32_t availableBytes) {
        int sampleCount = MIN(availableBytes / 2, S9xGetSampleCount());
        S9xMixSamples((uint8 *)ringBuffer, sampleCount);
        
        return sampleCount * 2; // Audio is interleaved, so we multiply by two to account for both channels
    }];
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

- (BOOL)addCheatCode:(NSString *)cheatCode type:(NSInteger)type
{
    BOOL success = YES;
    
    uint32 address = 0;
    uint8 byte = 0;
    
    switch ((CheatType)type)
    {
        case CheatTypeGameGenie:
            success = (S9xGameGenieToRaw([cheatCode UTF8String], address, byte) == NULL);
            break;
            
        case CheatTypeActionReplay:
            success = (S9xProActionReplayToRaw([cheatCode UTF8String], address, byte) == NULL);
            break;
            
        default:
            success = NO;
            break;
    }
    
    if (success)
    {
        S9xAddCheat(true, true, address, byte);
    }
        
    return success;
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
