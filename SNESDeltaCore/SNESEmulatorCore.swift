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
    override public var fastForwarding: Bool {
        didSet
        {
            SNESEmulatorBridge.sharedBridge().fastForwarding = self.fastForwarding
        }
    }
    
    public required init(game: GameType)
    {
        super.init(game: game)
        
        SNESEmulatorBridge.sharedBridge().audioRenderer = self.audioManager
        SNESEmulatorBridge.sharedBridge().videoRenderer = self.videoManager
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
    
    public override func startEmulation()
    {        
        guard !self.running else { return }
        
        super.startEmulation()
        
        let fileURL = self.game.fileURL
        
        dispatch_async(self.emulationQueue) {
            SNESEmulatorBridge.sharedBridge().startWithGameURL(fileURL)
        }
        
    }

    public override func stopEmulation()
    {
        // Don't check if we're already running; we should stop no matter what
        // guard self.running else { return }
        
        SNESEmulatorBridge.sharedBridge().stop()
        
        super.stopEmulation()
    }
    
    public override func pauseEmulation()
    {
        guard self.running else { return }
        
        SNESEmulatorBridge.sharedBridge().pause()
        
        super.pauseEmulation()
    }
    
    public override func resumeEmulation()
    {
        guard !self.running else { return }
        
        SNESEmulatorBridge.sharedBridge().resume()
        
        super.resumeEmulation()
    }
    
    //MARK: - EmulatorCore
    /// EmulatorCore
    public override func gameController(gameController: GameControllerType, didActivateInput input: InputType)
    {
        guard let input = input as? SNESGameInput else { return }
        
        SNESEmulatorBridge.sharedBridge().activateInput(input)
    }
    
    public override func gameController(gameController: GameControllerType, didDeactivateInput input: InputType)
    {
        guard let input = input as? SNESGameInput else { return }
        
        SNESEmulatorBridge.sharedBridge().deactivateInput(input)
    }
    
    //MARK: - Input Transformation -
    /// Input Transformation
    public override func inputsForMFiExternalControllerInput(input: InputType) -> [InputType]
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
    public override func saveSaveState(completion: (SaveStateType -> Void))
    {        
        NSFileManager.defaultManager().prepareTemporaryURL { URL in
            
            SNESEmulatorBridge.sharedBridge().saveSaveStateToURL(URL)
            
            let name = self.timestampDateFormatter.stringFromDate(NSDate())
            let saveState = SaveState(name: name, fileURL: URL)
            completion(saveState)
        }
    }
    
    public override func loadSaveState(saveState: SaveStateType)
    {
        dispatch_sync(self.emulationQueue) {
            SNESEmulatorBridge.sharedBridge().loadSaveStateFromURL(saveState.fileURL)
        }
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