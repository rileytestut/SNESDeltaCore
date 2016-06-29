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

@objc public enum SNESGameInput: Int, InputProtocol
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
}

public class SNESEmulatorCoreConfiguration: EmulatorCoreConfiguration
{
    //MARK: - DynamicObject
    /// DynamicObject
    public class override var isDynamicSubclass: Bool {
        return true
    }
    
    public class override var dynamicIdentifier: String {
        return GameType.snes.rawValue
    }
    
    //MARK: - EmulatorCoreConfiguration
    /// EmulatorCoreConfiguration
    public override var bridge: DLTAEmulatorBridge {
        return SNESEmulatorBridge.shared()
    }
    
    public override var gameInputType: InputProtocol.Type {
        return SNESGameInput.self
    }
    
    public override var audioBufferInfo: AudioManager.BufferInfo {
        let inputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 32040.5, channels: 2, interleaved: true)
        
        let bufferInfo = AudioManager.BufferInfo(inputFormat: inputFormat, preferredSize: 2132)
        return bufferInfo
    }
    
    public override var videoBufferInfo: VideoManager.BufferInfo {
        let bufferInfo = VideoManager.BufferInfo(inputFormat: .rgb565, inputDimensions: CGSize(width: 256 * 2, height: 224 * 2), outputDimensions: CGSize(width: 256, height: 224))
        return bufferInfo
    }
    
    public override var supportedCheatFormats: [CheatFormat] {
        let gameGenieFormat = CheatFormat(name: NSLocalizedString("Game Genie", comment: ""), format: "XXXX-YYYY", type: .gameGenie)
        let proActionReplayFormat = CheatFormat(name: NSLocalizedString("Pro Action Replay", comment: ""), format: "XXXXXXXX", type: .actionReplay)
        return [gameGenieFormat, proActionReplayFormat]
    }
    
    public override var supportedRates: ClosedRange<Double> {
        return 1...4
    }
    
    public override func gameSaveURL(for game: GameProtocol) -> URL?
    {
        let gameURL = (try? game.fileURL.deletingPathExtension()) ?? game.fileURL
        let gameSaveURL = try? gameURL.appendingPathExtension("srm")
        return gameSaveURL
    }
    
    public override func inputs(for controller: MFiExternalController, input: InputProtocol) -> [InputProtocol]
    {
        guard let input = input as? MFiExternalControllerInput else { return [] }
        
        var inputs: [InputProtocol] = []
        
        switch input
        {
        case let .dPad(xAxis: xAxis, yAxis: yAxis): inputs.append(contentsOf: self.inputs(forXAxis: xAxis, YAxis: yAxis))
        case let .leftThumbstick(xAxis: xAxis, yAxis: yAxis): inputs.append(contentsOf: self.inputs(forXAxis: xAxis, YAxis: yAxis))
        case .rightThumbstick(xAxis: _, yAxis: _): break
        case .a: inputs.append(SNESGameInput.a)
        case .b: inputs.append(SNESGameInput.b)
        case .x: inputs.append(SNESGameInput.x)
        case .y: inputs.append(SNESGameInput.y)
        case .l: inputs.append(SNESGameInput.l)
        case .r: inputs.append(SNESGameInput.r)
        case .leftTrigger: inputs.append(SNESGameInput.l)
        case .rightTrigger: inputs.append(SNESGameInput.r)
        }
        
        return inputs
    }
}

private extension SNESEmulatorCoreConfiguration
{
    func inputs(forXAxis xAxis: Float, YAxis yAxis: Float) -> [InputProtocol]
    {
        var inputs: [InputProtocol] = []
        
        if xAxis > 0.0
        {
            inputs.append(SNESGameInput.right)
        }
        else if xAxis < 0.0
        {
            inputs.append(SNESGameInput.left)
        }
        
        if yAxis > 0.0
        {
            inputs.append(SNESGameInput.up)
        }
        else if yAxis < 0.0
        {
            inputs.append(SNESGameInput.down)
        }
        
        return inputs
    }
}
