//
//  SNESEmulatorBridge.h
//  SNESDeltaCore
//
//  Created by Riley Testut on 9/12/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DeltaCore/DeltaCore.h>
#import <DeltaCore/DeltaCore-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface SNESEmulatorBridge : NSObject <DLTAEmulatorBridging>

@property (class, nonatomic, readonly) SNESEmulatorBridge *sharedBridge;

@end

NS_ASSUME_NONNULL_END
