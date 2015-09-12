//
//  SNESEmulatorBridge.h
//  SNESDeltaCore
//
//  Created by Riley Testut on 9/12/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SNESEmulatorBridge;

NS_ASSUME_NONNULL_BEGIN

@protocol SNESScreenRefreshDelegate

- (void)emulatorBridgeDidRefreshScreen:(SNESEmulatorBridge *)emulatorBridge;

@end

@interface SNESEmulatorBridge : NSObject

// Screen
@property (weak, nonatomic, nullable) id<SNESScreenRefreshDelegate> screenRefreshDelegate;

+ (instancetype)sharedBridge;

@end

NS_ASSUME_NONNULL_END