//
//  SNESEmulatorBridge.h
//  SNESDeltaCore
//
//  Created by Riley Testut on 9/12/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SNESEmulatorBridge;

@protocol DLTAAudioRendering;
@protocol DLTAVideoRendering;

typedef NS_ENUM(NSInteger, SNESGameInput)
{
    SNESGameInputUp     = 1 << 0,
    SNESGameInputDown   = 1 << 1,
    SNESGameInputLeft   = 1 << 2,
    SNESGameInputRight  = 1 << 3,
    SNESGameInputA      = 1 << 4,
    SNESGameInputB      = 1 << 5,
    SNESGameInputX      = 1 << 6,
    SNESGameInputY      = 1 << 7,
    SNESGameInputL      = 1 << 8,
    SNESGameInputR      = 1 << 9,
    SNESGameInputStart  = 1 << 10,
    SNESGameInputSelect = 1 << 11,
};

typedef NS_ENUM(NSInteger, SNESEmulationState)
{
    SNESEmulationStateStopped,
    SNESEmulationStateRunning,
    SNESEmulationStatePaused,
};

NS_ASSUME_NONNULL_BEGIN

@interface SNESEmulatorBridge : NSObject

// State
@property (copy, nonatomic, nullable, readonly) NSURL *gameURL;

// Audio
@property (weak, nonatomic, nullable) id<DLTAAudioRendering> audioRenderer;

// Video
@property (weak, nonatomic, nullable) id<DLTAVideoRendering> videoRenderer;

// Emulation
@property (assign, nonatomic, getter=isFastForwarding) BOOL fastForwarding;
@property (assign, nonatomic, readonly) SNESEmulationState state;

+ (instancetype)sharedBridge;

// Emulation
- (void)startWithGameURL:(NSURL *)URL;
- (void)stop;
- (void)pause;
- (void)resume;

// Inputs
- (void)activateInput:(SNESGameInput)gameInput;
- (void)deactivateInput:(SNESGameInput)gameInput;

// Save States
- (void)saveSaveStateToURL:(NSURL *)URL;
- (void)loadSaveStateFromURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END