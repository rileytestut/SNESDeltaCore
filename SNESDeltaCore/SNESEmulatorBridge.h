//
//  SNESEmulatorBridge.h
//  SNESDeltaCore
//
//  Created by Riley Testut on 9/12/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DeltaCore/DeltaCore.h>

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

typedef NS_ENUM(NSInteger, SNESCheatType)
{
    SNESCheatTypeGameGenie = 0,
    SNESCheatTypeProActionReplay = 1,
};

NS_ASSUME_NONNULL_BEGIN

@interface SNESEmulatorBridge : DLTAEmulatorBridge

// Inputs
- (void)activateInput:(SNESGameInput)gameInput;
- (void)deactivateInput:(SNESGameInput)gameInput;

// Cheats
- (BOOL)activateCheat:(NSString *)cheatCode type:(SNESCheatType)type;
- (void)deactivateCheat:(NSString *)cheatCode;

@end

NS_ASSUME_NONNULL_END