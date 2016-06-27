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

extension SNESGameInput: InputProtocol {}

public class SNESEmulatorCoreConfiguration: EmulatorCoreConfiguration
{
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
        case .a: inputs.append(SNESGameInput.A)
        case .b: inputs.append(SNESGameInput.B)
        case .x: inputs.append(SNESGameInput.X)
        case .y: inputs.append(SNESGameInput.Y)
        case .l: inputs.append(SNESGameInput.L)
        case .r: inputs.append(SNESGameInput.R)
        case .leftTrigger: inputs.append(SNESGameInput.L)
        case .rightTrigger: inputs.append(SNESGameInput.R)
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
