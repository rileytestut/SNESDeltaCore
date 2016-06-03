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

private extension SNESCheatType
{
    init(_ type: CheatType)
    {
        switch type
        {
        case .gameGenie: self = .GameGenie
        case .actionReplay: self = .ProActionReplay
        }
    }
}

public class SNESEmulatorCore: EmulatorCore
{
    override public var fastForwarding: Bool {
        didSet
        {
            SNESEmulatorBridge.sharedBridge().fastForwarding = self.fastForwarding
        }
    }
    
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
    
    override public var audioBufferInfo: AudioManager.BufferInfo{
        let inputFormat = AVAudioFormat(commonFormat: .PCMFormatInt16, sampleRate: 32040.5, channels: 2, interleaved: true)
        
        let bufferInfo = AudioManager.BufferInfo(inputFormat: inputFormat, preferredSize: 2132)
        return bufferInfo
    }
    
    override public var videoBufferInfo: VideoManager.BufferInfo {
        let bufferInfo = VideoManager.BufferInfo(inputFormat: .RGB565, inputDimensions: CGSize(width: 256 * 2, height: 224 * 2), outputDimensions: CGSize(width: 256, height: 224))
        return bufferInfo
    }
    
    override public var preferredRenderingSize: CGSize {
        return CGSizeMake(256, 224)
    }
    override public var fastForwardRate: Float {
        return 4.0
    }
    
    override public var supportedCheatFormats: [CheatFormat] {
        let gameGenieFormat = CheatFormat(name: NSLocalizedString("Game Genie", comment: ""), format: "XXXX-YYYY", type: .gameGenie)
        let proActionReplayFormat = CheatFormat(name: NSLocalizedString("Pro Action Replay", comment: ""), format: "XXXXXXXX", type: .actionReplay)
        return [gameGenieFormat, proActionReplayFormat]
    }
    
    public override func startEmulation() -> Bool
    {        
        guard super.startEmulation() else { return false }
        
        SNESEmulatorBridge.sharedBridge().emulatorCore = self
        SNESEmulatorBridge.sharedBridge().audioRenderer = self.audioManager
        SNESEmulatorBridge.sharedBridge().videoRenderer = self.videoManager
        
        SNESEmulatorBridge.sharedBridge().startWithGameURL(self.game.fileURL)
        
        return true
    }

    public override func stopEmulation() -> Bool
    {
        guard super.stopEmulation() else { return false }
        
        SNESEmulatorBridge.sharedBridge().stop()
        
        return true
    }
    
    public override func pauseEmulation() -> Bool
    {
        guard super.pauseEmulation() else { return false }
        
        SNESEmulatorBridge.sharedBridge().pause()
        
        return true
    }
    
    public override func resumeEmulation() -> Bool
    {
        guard super.resumeEmulation() else { return false }
        
        SNESEmulatorBridge.sharedBridge().resume()
        
        return true
    }
    
    //MARK: - EmulatorCore
    /// EmulatorCore
    public override func gameController(gameController: GameControllerProtocol, didActivateInput input: InputType)
    {
        guard let input = input as? SNESGameInput else { return }
        
        SNESEmulatorBridge.sharedBridge().activateInput(input)
    }
    
    public override func gameController(gameController: GameControllerProtocol, didDeactivateInput input: InputType)
    {
        guard let input = input as? SNESGameInput else { return }
        
        SNESEmulatorBridge.sharedBridge().deactivateInput(input)
    }
    
    //MARK: - Input Transformation -
    /// Input Transformation
    public override func inputsForMFiExternalController(controller: GameControllerProtocol, input: InputType) -> [InputType]
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
    
    //MARK: - Save States -
    /// Save States
    public override func saveSaveState(completion: (SaveStateType -> Void)) -> Bool
    {
        guard super.saveSaveState(completion) else { return false }
        
        NSFileManager.defaultManager().prepareTemporaryURL { URL in
            
            SNESEmulatorBridge.sharedBridge().saveSaveStateToURL(URL)
            
            let name = self.timestampDateFormatter.stringFromDate(NSDate())
            let saveState = SaveState(name: name, fileURL: URL)
            completion(saveState)
        }
        
        return true
    }
    
    public override func loadSaveState(saveState: SaveStateType) -> Bool
    {
        guard super.loadSaveState(saveState) else { return false }
        
        SNESEmulatorBridge.sharedBridge().loadSaveStateFromURL(saveState.fileURL)
        
        return true
    }
    
    //MARK: - Cheats -
    /// Cheats
    public override func activateCheat(cheat: CheatProtocol) throws
    {
        if !SNESEmulatorBridge.sharedBridge().activateCheat(cheat.code, type: SNESCheatType(cheat.type))
        {
            throw CheatError.invalid
        }
    }
    
    public override func deactivateCheat(cheat: CheatProtocol)
    {
        SNESEmulatorBridge.sharedBridge().deactivateCheat(cheat.code)
    }
}

private extension SNESEmulatorCore
{
    func inputsForXAxis(xAxis: Float, YAxis yAxis: Float) -> [InputType]
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