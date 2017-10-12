//
//  SNES.swift
//  SNESDeltaCore
//
//  Created by Riley Testut on 7/22/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//

import Foundation
import AVFoundation

import DeltaCore

public extension GameType
{
    public static let snes = GameType("com.rileytestut.delta.game.snes")
}

@objc public enum SNESGameInput: Int, Input
{
    case up     = 1
    case down   = 2
    case left   = 4
    case right  = 8
    case a      = 16
    case b      = 32
    case x      = 64
    case y      = 128
    case l      = 256
    case r      = 512
    case start  = 1024
    case select = 2048
    
    public var type: InputType {
        return .game(.snes)
    }
}

public struct SNES: DeltaCoreProtocol
{
    public static let core = SNES()
    
    public let bundleIdentifier = "com.rileytestut.SNESDeltaCore"
    
    public let gameType = GameType.snes
    
    public let gameInputType: Input.Type = SNESGameInput.self
    
    public let gameSaveFileExtension = "srm"
    
    public let frameDuration = (1.0 / 60.0)
    
    public let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 32040, channels: 2, interleaved: true)!
    
    public let videoFormat = VideoFormat(pixelFormat: .rgb565, dimensions: CGSize(width: 256, height: 224))
    
    public let supportedCheatFormats: Set<CheatFormat> = {
        let gameGenieFormat = CheatFormat(name: NSLocalizedString("Game Genie", comment: ""), format: "XXXX-YYYY", type: .gameGenie)
        let proActionReplayFormat = CheatFormat(name: NSLocalizedString("Pro Action Replay", comment: ""), format: "XXXXXXXX", type: .actionReplay)
        return [gameGenieFormat, proActionReplayFormat]
    }()
    
    public let emulatorBridge: EmulatorBridging = SNESEmulatorBridge.shared
        
    private init()
    {
    }
}
