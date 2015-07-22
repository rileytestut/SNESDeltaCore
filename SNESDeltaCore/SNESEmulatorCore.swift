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
    //MARK: - Overrides -
    /** Overrides **/
    
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
    
    //MARK: - DynamicObject
    /// DynamicObject
    public override class func isDynamicSubclass() -> Bool
    {
        return true
    }
    
    public override class func dynamicIdentifier() -> String?
    {
        return kUTTypeSNESGame as String;
    }
}