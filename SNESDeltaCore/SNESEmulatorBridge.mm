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
#import <DeltaCore/DeltaCore.h>

void SNESFinalizeSamplesCallback(void *context);

@interface SNESEmulatorBridge ()

@property (copy, nonatomic, nullable, readwrite) NSURL *gameURL;
@property (assign, nonatomic, readwrite) SNESEmulationState state;

@property (strong, nonatomic, readonly) dispatch_semaphore_t emulationStateSemaphore;

@property (strong, nonatomic, nonnull) NSMutableDictionary<NSString *, NSNumber *> *cheatCodes;

@end

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

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _emulationStateSemaphore = dispatch_semaphore_create(0);
        _cheatCodes = [NSMutableDictionary dictionary];
    }
    
    return self;
}

#pragma mark - Emulation -

- (void)startWithGameURL:(NSURL *)URL
{
    if (self.state != SNESEmulationStateStopped)
    {
        return;
    }
    
    self.state = SNESEmulationStateRunning;
    
    self.gameURL = URL;
    
    [self.cheatCodes removeAllObjects];
    
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
    
    NSURL *saveURL = [self defaultGameSaveURL];
    [self loadGameSaveFromURL:saveURL];
    
    Settings.StopEmulation = NO;
    
    GFX.Pitch = 512 * 2;
    GFX.Screen = (uint16 *)self.videoRenderer.videoBuffer;
    
    S9xGraphicsInit();
    
    sprintf(String, "\"%s\" %s: %s", Memory.ROMName, TITLE, VERSION);
    
    S9xSetSoundMute(NO);
    
    S9xSetSamplesAvailableCallback(SNESFinalizeSamplesCallback, NULL);
    
    __block SNESEmulationState previousEmulationState = SNESEmulationStateStopped;
    
    dispatch_queue_t emulationQueue = dispatch_queue_create("com.rileytestut.Delta.SNESDeltaCore.emulationQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(emulationQueue, ^{
        
        void (^signalSemaphoreIfNeeded)(void) = ^{
            
            if (previousEmulationState != self.state)
            {
                dispatch_semaphore_signal(self.emulationStateSemaphore);
            }
            
            previousEmulationState = self.state;
            
        };
        
        while (YES)
        {
            if (self.state == SNESEmulationStateRunning)
            {
                S9xMainLoop();
                
                // Only check if we should signal semaphore if the state hasn't changed out from under us
                // Otherwise, very bad things happen
                if (self.state == SNESEmulationStateRunning)
                {
                    signalSemaphoreIfNeeded();
                }
            }
            else
            {
                S9xSetSoundMute(YES);
                
                [self saveGameSaveToURL:saveURL];
                
                if (self.state == SNESEmulationStatePaused)
                {
                    while (self.state == SNESEmulationStatePaused)
                    {
                        signalSemaphoreIfNeeded();
                        usleep(100000);
                    }
                }
                else if (self.state == SNESEmulationStateStopped)
                {                    
                    S9xGraphicsDeinit();
                    Memory.Deinit();
                    S9xDeinitAPU();
                    
                    // Signal after we've finished tearing down
                    signalSemaphoreIfNeeded();
                    
                    break;
                }
                
                S9xSetSoundMute(NO);
            }
        }
    });
    
    dispatch_semaphore_wait(self.emulationStateSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)stop
{
    if (self.state == SNESEmulationStateStopped)
    {
        return;
    }
    
    self.state = SNESEmulationStateStopped;
    
    dispatch_semaphore_wait(self.emulationStateSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)pause
{
    if (self.state != SNESEmulationStateRunning)
    {
        return;
    }
    
    self.state = SNESEmulationStatePaused;
    
    dispatch_semaphore_wait(self.emulationStateSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)resume
{
    if (self.state != SNESEmulationStatePaused)
    {
        return;
    }
    
    self.state = SNESEmulationStateRunning;
    
    dispatch_semaphore_wait(self.emulationStateSemaphore, DISPATCH_TIME_FOREVER);
}

#pragma mark - Inputs -

- (void)activateInput:(SNESGameInput)gameInput
{
    S9xReportButton((uint32)gameInput, YES);
}

- (void)deactivateInput:(SNESGameInput)gameInput
{
    S9xReportButton((uint32)gameInput, NO);
}

#pragma mark - Audio -

- (void)renderAudioSamples
{
    S9xFinalizeSamples();
    
    [self.audioRenderer.ringBuffer writeToRingBuffer:^int32_t(void * _Nonnull ringBuffer, int32_t availableBytes) {
        
        int sampleCount = MIN(availableBytes / 2, S9xGetSampleCount());
        S9xMixSamples((uint8 *)ringBuffer, sampleCount);
        
        return sampleCount * 2; // Audio is interleaved, so we multiply by two to account for both channels
    }];
}

#pragma mark - Video -

- (void)refreshScreen
{
    [self.videoRenderer didUpdateVideoBuffer];
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

- (BOOL)activateCheat:(NSString *)cheatCode type:(SNESCheatType)type
{
    NSArray *codes = [cheatCode componentsSeparatedByString:@"\n"];
    for (NSString *code in codes)
    {
        BOOL success = YES;
        
        uint32 address;
        uint8 byte;
        
        switch (type)
        {
            case SNESCheatTypeGameGenie:
                success = (S9xGameGenieToRaw([code UTF8String], address, byte) == NULL);
                break;
                
            case SNESCheatTypeProActionReplay:
                success = (S9xProActionReplayToRaw([code UTF8String], address, byte) == NULL);
                break;
        }
        
        if (!success)
        {
            return NO;
        }
    }
    
    self.cheatCodes[cheatCode] = @(type);
    
    [self updateCheats];
    
    return YES;
}

- (void)deactivateCheat:(NSString *)cheatCode
{
    if (self.cheatCodes[cheatCode] == nil)
    {
        return;
    }
    
    self.cheatCodes[cheatCode] = nil;
    
    [self updateCheats];
}

- (void)updateCheats
{
    S9xDeleteCheats();
    
    [self.cheatCodes.copy enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull cheatCode, NSNumber * _Nonnull type, BOOL * _Nonnull stop) {
        
        NSArray *codes = [cheatCode componentsSeparatedByString:@"\n"];
        for (NSString *code in codes)
        {
            uint32 address = 0;
            uint8 byte = 0;
            
            switch ([type integerValue])
            {
                case SNESCheatTypeGameGenie:
                    S9xGameGenieToRaw([code UTF8String], address, byte);
                    break;
                    
                case SNESCheatTypeProActionReplay:
                    S9xProActionReplayToRaw([code UTF8String], address, byte);
                    break;
            }
            
            S9xAddCheat(true, true, address, byte);
        }
        
    }];
    
    Settings.ApplyCheats = true;
    S9xApplyCheats();
}

#pragma mark - SRAM -

- (void)saveGameSaveToURL:(NSURL *)URL
{
    Memory.SaveSRAM(URL.path.fileSystemRepresentation);
    sync();
}

- (void)loadGameSaveFromURL:(NSURL *)URL
{
    Memory.LoadSRAM(URL.path.fileSystemRepresentation);
}

- (NSURL *)defaultGameSaveURL
{
    NSURL *saveURL = [[self.gameURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"srm"];
    return saveURL;
}

#pragma mark - Getters/Setters -

- (void)setFastForwarding:(BOOL)fastForwarding
{
    if (fastForwarding == _fastForwarding)
    {
        return;
    }
    
    _fastForwarding = fastForwarding;
    
    Settings.TurboMode = fastForwarding;
    
    S9xClearSamples();
}

- (void)setState:(SNESEmulationState)state
{
    _state = state;
    
    switch (_state)
    {
        case SNESEmulationStateStopped:
            Settings.Paused = YES;
            break;
            
        case SNESEmulationStateRunning:
            Settings.Paused = NO;
            break;
            
        case SNESEmulationStatePaused:
            Settings.Paused = YES;
            break;
    }
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
    if (Settings.SoundSync)
    {
        while (!S9xSyncSound())
        {
            usleep(0);
        }
    }
    
    if (Settings.DumpStreams)
    {
        return;
    }
    
    if (Settings.HighSpeedSeek > 0)
    {
        Settings.HighSpeedSeek--;
    }
    
    if (Settings.TurboMode)
    {
        if ((++IPPU.FrameSkip >= Settings.TurboSkipFrames) && !Settings.HighSpeedSeek)
        {
            IPPU.FrameSkip = 0;
            IPPU.SkippedFrames = 0;
            IPPU.RenderThisFrame = TRUE;
        }
        else
        {
            IPPU.SkippedFrames++;
            IPPU.RenderThisFrame = FALSE;
        }
        
        return;
    }
    
    static struct timeval	next1 = { 0, 0 };
    struct timeval			now;
    
    while (gettimeofday(&now, NULL) == -1) ;
    
    // If there is no known "next" frame, initialize it now.
    if (next1.tv_sec == 0)
    {
        next1 = now;
        next1.tv_usec++;
    }
    
    // If we're on AUTO_FRAMERATE, we'll display frames always only if there's excess time.
    // Otherwise we'll display the defined amount of frames.
    unsigned	limit = (Settings.SkipFrames == AUTO_FRAMERATE) ? (timercmp(&next1, &now, <) ? 10 : 1) : Settings.SkipFrames;
    
    IPPU.RenderThisFrame = (++IPPU.SkippedFrames >= limit) ? TRUE : FALSE;
    
    if (IPPU.RenderThisFrame)
        IPPU.SkippedFrames = 0;
    else
    {
        // If we were behind the schedule, check how much it is.
        if (timercmp(&next1, &now, <))
        {
            long lag = (now.tv_sec - next1.tv_sec) * 1000000 + now.tv_usec - next1.tv_usec;
            if (lag >= 500000)
            {
                // More than a half-second behind means probably pause.
                // The next line prevents the magic fast-forward effect.
                next1 = now;
            }
        }
    }
    
    // Delay until we're completed this frame.
    // Can't use setitimer because the sound code already could be using it. We don't actually need it either.
    while (timercmp(&next1, &now, >))
    {
        // If we're ahead of time, sleep a while.
        long timeleft = (next1.tv_sec - now.tv_sec) * 1000000 + next1.tv_usec - now.tv_usec;
        usleep((unsigned int)timeleft);
        
        while (gettimeofday(&now, NULL) == -1) ;
        // Continue with a while-loop because usleep() could be interrupted by a signal.
    }
    
    // Calculate the timestamp of the next frame.
    next1.tv_usec += Settings.FrameTime;
    if (next1.tv_usec >= 1000000)
    {
        next1.tv_sec += next1.tv_usec / 1000000;
        next1.tv_usec %= 1000000;
    }
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
    NSURL *saveURL = [[SNESEmulatorBridge sharedBridge] defaultGameSaveURL];
    [[SNESEmulatorBridge sharedBridge] saveGameSaveToURL:saveURL];
}

bool8 S9xDeinitUpdate(int width, int height)
{
    [[SNESEmulatorBridge sharedBridge] refreshScreen];
    
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