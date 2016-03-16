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

NS_ASSUME_NONNULL_BEGIN

@interface SNESEmulatorBridge : NSObject

// Audio
@property (weak, nonatomic, nullable) id<DLTAAudioRendering> audioRenderer;

// Video
@property (weak, nonatomic, nullable) id<DLTAVideoRendering> videoRenderer;

// Emulation
@property (assign, nonatomic, getter=isFastForwarding) BOOL fastForwarding;

+ (instancetype)sharedBridge;

// Save States
- (void)saveSaveStateToURL:(NSURL *)URL;
- (void)loadSaveStateFromURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END