//
//  SNES.swift
//  SNESDeltaCore
//
//  Created by Riley Testut on 7/22/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//

import Foundation

public extension GameType
{
    public static let snes = "com.rileytestut.delta.game.snes" as GameType
}

public struct SNES: DeltaCoreProtocol
{
    public static let core = SNES()
    
    public let supportedGameTypes: Set<GameType> = [.snes]
    
    public let emulatorBridge: EmulatorBridging = SNESEmulatorBridge.shared
    
    public let emulatorConfiguration: EmulatorConfiguration = SNESEmulatorConfiguration()
    
    public let inputTransformer: InputTransforming = SNESInputTransformer()
    
    private init()
    {
    }
    
}
