//
//  SNESGame+Dynamic.m
//  SNESDeltaCore
//
//  Created by Riley Testut on 3/9/15.
//  Copyright (c) 2015 Riley Testut. All rights reserved.
//

#import "SNESGame+Dynamic.h"
#import "SNESDeltaCoreConstants.h"

@import DeltaCore;

@implementation SNESGame (Dynamic)

+ (void)load
{
    NSString *UTI = (__bridge __nonnull NSString *)(kUTTypeSNESGame);
    [Game registerSubclass:self forUTI:UTI.lowercaseString];
}

@end
