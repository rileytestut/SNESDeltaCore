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

public enum GameInput: UInt, InputType
{
    case Up     = 0x1
    case Down   = 0x10
    case Left   = 0x4
    case Right  = 0x40
    case A      = 0b1000000000000    // 1 << 12
    case B      = 0b10000000000000   // 1 << 13
    case X      = 0b100000000000000  // 1 << 14
    case Y      = 0b1000000000000000 // 1 << 15
    case L      = 0b10000000000      // 1 << 10
    case R      = 0b100000000000     // 1 << 11
    case Start  = 0b100000000        // 1 << 8
    case Select = 0b1000000000       // 1 << 9
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
        
        SNESEmulatorBridge.sharedBridge().ringBuffer = self.audioManager.ringBuffer
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
    
    override public var videoBufferInfo: VideoManager.BufferInfo {
        let bufferInfo = VideoManager.BufferInfo(inputFormat: .RGB565, inputDimensions: CGSize(width: 256 * 2, height: 224 * 2), outputDimensions: CGSize(width: 256, height: 224))
        return bufferInfo
    }
    
    public override func startEmulation()
    {        
        guard !self.running else { return }
        
        super.startEmulation()
        
        if let path: NSString? = self.game.fileURL.path, cPath = path?.UTF8String
        {
            let emulationQueue: dispatch_queue_t = dispatch_queue_create("com.rileytestut.delta.SNESEmulatorCore.emulationQueue", DISPATCH_QUEUE_SERIAL)
            
            dispatch_async(emulationQueue) {
                SISetEmulationPaused(0)
                SISetEmulationRunning(1)
                SIStartWithROM(cPath)
                SISetEmulationRunning(0)             
            }
        }
    }
    
    public override func stopEmulation()
    {
        // Don't check if we're already running; we should stop no matter what
        // guard self.running else { return }
        
        SISetEmulationRunning(0)
        SIWaitForEmulationEnd()
        
        super.stopEmulation()
    }
    
    public override func pauseEmulation()
    {
        guard self.running else { return }
        
        SISetEmulationPaused(1)
        
        super.pauseEmulation()
    }
    
    public override func resumeEmulation()
    {
        guard !self.running else { return }
        
        SISetEmulationPaused(0)
        
        super.resumeEmulation()
    }
    
    //MARK: - EmulatorCore
    /// EmulatorCore
    public override func gameController(gameController: GameControllerType, didActivateInput input: InputType)
    {
        guard let input = input as? GameInput else { return }
        
        print("Activated \(input)")
        
        SISetControllerPushButton(input.rawValue)
    }
    
    public override func gameController(gameController: GameControllerType, didDeactivateInput input: InputType)
    {
        guard let input = input as? GameInput else { return }
        
        print("Deactivated \(input)")
                
        SISetControllerReleaseButton(input.rawValue)
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
        case .A: inputs.append(GameInput.A)
        case .B: inputs.append(GameInput.B)
        case .X: inputs.append(GameInput.X)
        case .Y: inputs.append(GameInput.Y)
        case .L: inputs.append(GameInput.L)
        case .R: inputs.append(GameInput.R)
        case .LeftTrigger: inputs.append(GameInput.L)
        case .RightTrigger: inputs.append(GameInput.R)
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
        SNESEmulatorBridge.sharedBridge().loadSaveStateFromURL(saveState.fileURL)
    }
}

//MARK: - System Information -
/// System Information
public extension SNESEmulatorCore
{
    override var preferredRenderingSize: CGSize {
        return CGSizeMake(256, 224)
    }
    
    override var preferredBufferSize: Int {
        return 2132
    }
    
    override var audioFormat: AVAudioFormat {
        return AVAudioFormat(commonFormat: .PCMFormatInt16, sampleRate: 32040.5, channels: 2, interleaved: true)
    }
    
    override var fastForwardRate: Float {
        return 4.0
    }
}

private extension SNESEmulatorCore
{
    func inputsForXAxis(xAxis: Float, YAxis yAxis: Float) -> [InputType]
    {
        var inputs: [InputType] = []
        
        if xAxis > 0.0
        {
            inputs.append(GameInput.Right)
        }
        else if xAxis < 0.0
        {
            inputs.append(GameInput.Left)
        }
        
        if yAxis > 0.0
        {
            inputs.append(GameInput.Up)
        }
        else if yAxis < 0.0
        {
            inputs.append(GameInput.Down)
        }
        
        return inputs
    }
}