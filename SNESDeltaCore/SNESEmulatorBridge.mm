//
//  SNESEmulatorBridge.m
//  SNESDeltaCore
//
//  Created by Riley Testut on 9/12/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//

#import "SNESEmulatorBridge.h"

// Snes9x
#include "../SNES9X/snes9x.h"
#include "../Snes9x/apu/apu.h"

// Bridge
#include "Snes9xMain.h"

// DeltaCore
#import <DeltaCore/DLTARingBuffer.h>

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
    
    [self.ringBuffer writeToRingBuffer:^int32_t(void * _Nonnull ringBuffer, int32_t availableBytes) {
        
        int sampleCount = MIN(availableBytes / 2, S9xGetSampleCount());
        S9xMixSamples((uint8 *)ringBuffer, sampleCount);
        
        return sampleCount * 2; // Audio is interleaved, so we multiply by two to account for both channels
    }];
}

#pragma mark - Video -

- (void)refreshScreen
{
    [self.screenRefreshDelegate emulatorBridgeDidRefreshScreen:self];
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