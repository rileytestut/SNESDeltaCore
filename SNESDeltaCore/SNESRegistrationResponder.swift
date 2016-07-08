//
//  SNESRegistrationResponder.swift
//  SNESDeltaCore
//
//  Created by Riley Testut on 6/30/16.
//  Copyright © 2016 Riley Testut. All rights reserved.
//

import Foundation

public class SNESRegistrationResponder: NSObject
{
    public class func handleDeltaRegistrationRequest(_ notification: Notification)
    {
        guard let object = notification.object else { return }
        
        // unsafeBitCast needed for Swift Playground support
        let response = unsafeBitCast(object, to: Delta.RegistrationResponse.self)
        response.handler(SNES.core)
    }
}
