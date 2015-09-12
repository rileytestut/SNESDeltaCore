//
//  SNESEmulatorBridge.m
//  SNESDeltaCore
//
//  Created by Riley Testut on 9/12/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//

#import "SNESEmulatorBridge.h"

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

#pragma mark - Refresh Screen -

- (void)refreshScreen
{
    [self.screenRefreshDelegate emulatorBridgeDidRefreshScreen:self];
}

@end


#pragma mark - C Callbacks -

void SNESRefreshScreen()
{
    [[SNESEmulatorBridge sharedBridge] refreshScreen];
}