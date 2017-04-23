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

public struct SNES: DeltaCoreProtocol
{
    public static let core = SNES()
    
    public let gameType = GameType.snes
    
    public let bundleIdentifier: String = "com.rileytestut.SNESDeltaCore"
    
    public let gameSaveFileExtension: String = "srm"
    
    public let frameDuration = (1.0 / 60.0)
    
    public let supportedRates: ClosedRange<Double> = 1...4
    
    public let supportedCheatFormats: [CheatFormat] = {
        let gameGenieFormat = CheatFormat(name: NSLocalizedString("Game Genie", comment: ""), format: "XXXX-YYYY", type: .gameGenie)
        let proActionReplayFormat = CheatFormat(name: NSLocalizedString("Pro Action Replay", comment: ""), format: "XXXXXXXX", type: .actionReplay)
        return [gameGenieFormat, proActionReplayFormat]
    }()
    
    public let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 32000, channels: 2, interleaved: true)
    
    public let videoFormat = VideoFormat(pixelFormat: .rgb565, dimensions: CGSize(width: 256, height: 224))
    
    public let emulatorBridge: EmulatorBridging = SNESEmulatorBridge.shared
    
    public let inputTransformer: InputTransforming = SNESInputTransformer()
    
    private init()
    {
    }
    
}
