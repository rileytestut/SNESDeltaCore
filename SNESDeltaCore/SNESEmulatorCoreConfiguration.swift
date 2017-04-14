//
//  SNESEmulatorCoreConfiguration.swift
//  SNESDeltaCore
//
//  Created by Riley Testut on 6/27/16.
//  Copyright © 2016 Riley Testut. All rights reserved.
//

import Foundation
import AVFoundation

import DeltaCore

public struct SNESEmulatorConfiguration: EmulatorConfiguration
{
    public let gameSaveFileExtension: String = "srm"
    
    public let audioBufferInfo: AudioManager.BufferInfo = {
        let inputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 32040.5, channels: 2, interleaved: true)
        
        let bufferInfo = AudioManager.BufferInfo(inputFormat: inputFormat, preferredSize: 2132)
        return bufferInfo
    }()
    
    public let videoBufferInfo: VideoManager.BufferInfo = {
        let bufferInfo = VideoManager.BufferInfo(format: .rgb565, dimensions: CGSize(width: 256, height: 224))
        return bufferInfo
    }()
    
    public let supportedCheatFormats: [CheatFormat] = {
        let gameGenieFormat = CheatFormat(name: NSLocalizedString("Game Genie", comment: ""), format: "XXXX-YYYY", type: .gameGenie)
        let proActionReplayFormat = CheatFormat(name: NSLocalizedString("Pro Action Replay", comment: ""), format: "XXXXXXXX", type: .actionReplay)
        return [gameGenieFormat, proActionReplayFormat]
    }()
    
    public let supportedRates: ClosedRange<Double> = 1...4
}

