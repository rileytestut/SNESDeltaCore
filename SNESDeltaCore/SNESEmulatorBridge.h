//
//  SNESEmulatorBridge.h
//  SNESDeltaCore
//
//  Created by Riley Testut on 9/12/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SNESEmulatorBridge;
@class DLTARingBuffer;

NS_ASSUME_NONNULL_BEGIN

@protocol SNESScreenRefreshDelegate

- (void)emulatorBridgeDidRefreshScreen:(SNESEmulatorBridge *)emulatorBridge;

@end

@interface SNESEmulatorBridge : NSObject

// Audio
@property (strong, nonatomic, nullable) DLTARingBuffer *ringBuffer;

// Video
@property (weak, nonatomic, nullable) id<SNESScreenRefreshDelegate> screenRefreshDelegate;

// Emulation
@property (assign, nonatomic, getter=isFastForwarding) BOOL fastForwarding;

+ (instancetype)sharedBridge;

// Save States
- (void)saveSaveStateToURL:(NSURL *)URL;
- (void)loadSaveStateFromURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END