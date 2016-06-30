//
//  SNESRegistrationResponder+Dynamic.m
//  SNESDeltaCore
//
//  Created by Riley Testut on 6/30/16.
//  Copyright © 2016 Riley Testut. All rights reserved.
//

#import "SNESRegistrationResponder+Dynamic.h"

@implementation SNESRegistrationResponder (Dynamic)

+ (void)load
{    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeltaRegistrationRequest:) name:DeltaRegistrationRequestNotification object:nil];
}

@end
