//
//  SNESDeltaCore.swift
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

public struct SNESDeltaCore: DeltaCoreProtocol
{
    public static let core = SNESDeltaCore()
    
    public let supportedGameTypes: Set<GameType> = [.snes]
    
    public let emulatorBridge: EmulatorBridging = SNESEmulatorBridge.shared
    
    public let emulatorConfiguration: EmulatorConfiguration = SNESEmulatorConfiguration()
    
    public let inputManager: InputManager = SNESInputManager()
    
    private init()
    {
    }
    
}
