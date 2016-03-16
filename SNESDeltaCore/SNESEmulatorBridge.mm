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

// Bridge
#include "Snes9xMain.h"

// DeltaCore
#import <DeltaCore/DeltaCore.h>

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

#pragma mark - Getters/Setters -

- (void)setFastForwarding:(BOOL)fastForwarding
{
    if (_fastForwarding == fastForwarding)
    {
        return;
    }
    
    _fastForwarding = fastForwarding;
    
    Settings.TurboMode = fastForwarding;
    
    S9xClearSamples();
}

- (void)setVideoRenderer:(id<DLTAVideoRendering>)videoRenderer
{
    if ([videoRenderer isEqual:_videoRenderer])
    {
        return;
    }
    
    _videoRenderer = videoRenderer;
    
    SISetScreen(videoRenderer.videoBuffer);
}

@end


#pragma mark - C Callbacks -

extern "C" void SNESRefreshScreen()
{
    [[SNESEmulatorBridge sharedBridge] refreshScreen];
}

extern "C" void SNESFinalizeSamplesCallback(void *context)
{
    [[SNESEmulatorBridge sharedBridge] renderAudioSamples];
}