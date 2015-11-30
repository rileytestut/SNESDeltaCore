//
//  SNESEmulatorCore.swift
//  SNESDeltaCore
//
//  Created by Riley Testut on 3/11/15.
//  Copyright (c) 2015 Riley Testut. All rights reserved.
//

import DeltaCore

public enum GameInput: InputType
{
    case Up
    case Down
    case Left
    case Right
    case A
    case B
    case X
    case Y
    case L
    case R
    case Start
    case Select
}

public class SNESEmulatorCore: EmulatorCore
{
    private let renderer = SNESGameRenderer()
    
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
    
    public override func startEmulation()
    {
        if let path: NSString? = self.game.fileURL.path, cPath = path?.UTF8String
        {
            let emulationQueue: dispatch_queue_t = dispatch_queue_create("com.rileytestut.delta.SNESEmulatorCore.emulationQueue", DISPATCH_QUEUE_SERIAL)
            
            dispatch_async(emulationQueue) {
                SISetEmulationPaused(0);
                SISetEmulationRunning(1);
                SIStartWithROM(cPath);
                SISetEmulationRunning(0);                
            }
            
            self.renderer.activate()
        }
    }
    
    //MARK: - EmulatorCore
    /// EmulatorCore
    public override func gameController(gameController: GameControllerType, didActivateInput input: InputType)
    {
        guard let input = input as? GameInput else { return }
        
        print("Activated \(input)")
    }
    
    public override func gameController(gameController: GameControllerType, didDeactivateInput input: InputType)
    {
        guard let input = input as? GameInput else { return }
        
        print("Deactivated \(input)")
    }
    
    //MARK: - Input Transformation -
    /// Input Transformation
    public override func inputsForMFiExternalControllerInput(input: InputType) -> [InputType]
    {
        guard let input = input as? MFiExternalControllerInput else { return [] }
        
        var inputs: [InputType] = []
        
        switch input
        {
        case let .DPad(xAxis: xAxis, yAxis: yAxis): inputs.appendContentsOf(self.inputsForXAxis(xAxis, yAxis: yAxis))
        case let .LeftThumbstick(xAxis: xAxis, yAxis: yAxis): inputs.appendContentsOf(self.inputsForXAxis(xAxis, yAxis: yAxis))
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
    
    public override func addGameView(gameView: GameView)
    {
        super.addGameView(gameView)
        
        self.renderer.gameView = gameView
    }
    
    public override func removeGameView(gameView: GameView)
    {
        super.removeGameView(gameView)
        
        self.renderer.gameView = nil
    }
}

//MARK: - System Information -
/// System Information
public extension SNESEmulatorCore
{
    override var preferredRenderingSize: CGSize {
        return CGSizeMake(256, 224)
    }
}

private extension SNESEmulatorCore
{
    func inputsForXAxis(xAxis: Float, yAxis: Float) -> [InputType]
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