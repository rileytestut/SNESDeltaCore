//
//  SNESEmulatorCore.swift
//  SNESDeltaCore
//
//  Created by Riley Testut on 3/11/15.
//  Copyright (c) 2015 Riley Testut. All rights reserved.
//

import DeltaCore
import AVFoundation

import Roxas

extension SNESGameInput: InputType {}

public class SNESEmulatorCore: EmulatorCore
{
    public required init(game: GameType)
    {
        super.init(game: game)
        
        // These MUST be set in startEmulation(), because it's possible the same emulator core might be stopped, another one started, and then resumed back to this one
        // AKA, these need to always be set at start to ensure it points to the correct managers
        // SNESEmulatorBridge.sharedBridge().audioRenderer = self.audioManager
        // SNESEmulatorBridge.sharedBridge().videoRenderer = self.videoManager
    }
    
    //MARK: - DynamicObject
    /// DynamicObject
    public override class func isDynamicSubclass() -> Bool
    {
        return true
    }
    
    public override class func dynamicIdentifier() -> String?
    {
        return kUTTypeSNESGame as String
    }
    
    //MARK: - Overrides -
    /** Overrides **/
    
    override public var bridge: DLTAEmulatorBridge
    {
        return SNESEmulatorBridge.sharedBridge()
    }
    
    public override var gameInputType: InputType.Type
    {
        return SNESGameInput.self
    }
    
    public override var gameSaveURL: URL
    {
        var gameSaveURL = self.game.fileURL.URLByDeletingPathExtension ?? self.game.fileURL
        gameSaveURL = gameSaveURL.URLByAppendingPathExtension("srm")
        return gameSaveURL
    }
    
    override public var audioBufferInfo: AudioManager.BufferInfo
    {
        let inputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 32040.5, channels: 2, interleaved: true)
        
        let bufferInfo = AudioManager.BufferInfo(inputFormat: inputFormat, preferredSize: 2132)
        return bufferInfo
    }
    
    override public var videoBufferInfo: VideoManager.BufferInfo
    {
        let bufferInfo = VideoManager.BufferInfo(inputFormat: .RGB565, inputDimensions: CGSize(width: 256 * 2, height: 224 * 2), outputDimensions: CGSize(width: 256, height: 224))
        return bufferInfo
    }
    
    override public var supportedRates: ClosedRange<Double>
    {
        return 1...4
    }
    
    override public var supportedCheatFormats: [CheatFormat]
    {
        let gameGenieFormat = CheatFormat(name: NSLocalizedString("Game Genie", comment: ""), format: "XXXX-YYYY", type: .gameGenie)
        let proActionReplayFormat = CheatFormat(name: NSLocalizedString("Pro Action Replay", comment: ""), format: "XXXXXXXX", type: .actionReplay)
        return [gameGenieFormat, proActionReplayFormat]
    }
    
    //MARK: - Input Transformation -
    /// Input Transformation
    public override func inputsForMFiExternalController(_ controller: GameControllerProtocol, input: InputType) -> [InputType]
    {
        guard let input = input as? MFiExternalControllerInput else { return [] }
        
        var inputs: [InputType] = []
        
        switch input
        {
        case let .DPad(xAxis: xAxis, yAxis: yAxis): inputs.appendContentsOf(self.inputsForXAxis(xAxis, YAxis: yAxis))
        case let .LeftThumbstick(xAxis: xAxis, yAxis: yAxis): inputs.appendContentsOf(self.inputsForXAxis(xAxis, YAxis: yAxis))
        case .RightThumbstick(xAxis: _, yAxis: _): break
        case .A: inputs.append(SNESGameInput.A)
        case .B: inputs.append(SNESGameInput.B)
        case .X: inputs.append(SNESGameInput.X)
        case .Y: inputs.append(SNESGameInput.Y)
        case .L: inputs.append(SNESGameInput.L)
        case .R: inputs.append(SNESGameInput.R)
        case .LeftTrigger: inputs.append(SNESGameInput.L)
        case .RightTrigger: inputs.append(SNESGameInput.R)
        }
        
        return inputs
    }
}

private extension SNESEmulatorCore
{
    func inputsForXAxis(_ xAxis: Float, YAxis yAxis: Float) -> [InputType]
    {
        var inputs: [InputType] = []
        
        if xAxis > 0.0
        {
            inputs.append(SNESGameInput.Right)
        }
        else if xAxis < 0.0
        {
            inputs.append(SNESGameInput.Left)
        }
        
        if yAxis > 0.0
        {
            inputs.append(SNESGameInput.Up)
        }
        else if yAxis < 0.0
        {
            inputs.append(SNESGameInput.Down)
        }
        
        return inputs
    }
}
