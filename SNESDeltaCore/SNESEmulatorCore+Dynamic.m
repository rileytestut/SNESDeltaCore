//
//  SNESEmulatorCore+Dynamic.m
//  SNESDeltaCore
//
//  Created by Riley Testut on 3/11/15.
//  Copyright (c) 2015 Riley Testut. All rights reserved.
//

#import "SNESEmulatorCore+Dynamic.h"

@implementation SNESEmulatorCore (Dynamic)

+ (void)load
{
    [EmulatorCore registerSubclass:self forGameType:[SNESGame class]];
}

@end
