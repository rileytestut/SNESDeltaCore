//
//  SNESControllerSkin.swift
//  SNESDeltaCore
//
//  Created by Riley Testut on 7/5/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//

import DeltaCore

public class SNESControllerSkin: ControllerSkin
{
    //MARK: - Overrides -
    /** Overrides **/
    
    //MARK: - ControllerSkin
    /// ControllerSkin
    public override class func defaultControllerSkinForGameUTI(UTI: String) -> ControllerSkin?
    {
        let URL = NSBundle(forClass: self).URLForResource("Default", withExtension: "deltaskin")
        let controllerSkin = ControllerSkin(URL: URL!)
        
        return controllerSkin
    }
    
    public override func inputsForPoint(point: CGPoint, inRect rect: CGRect, key: String) -> [InputType]
    {
        var inputs: [InputType] = []
        
        switch key
        {
        case "D-Pad":
            
            let topRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height / 3.0)
            let bottomRect = CGRect(x: rect.minX, y: rect.maxY - rect.height / 3.0, width: rect.width, height: rect.height / 3.0)
            let leftRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width / 3.0, height: rect.height)
            let rightRect = CGRect(x: rect.maxX - rect.width / 3.0, y: rect.minY, width: rect.width / 3.0, height: rect.height)
            
            if CGRectContainsPoint(topRect, point)
            {
                inputs.append(GameInput.Up)
            }
            
            if CGRectContainsPoint(bottomRect, point)
            {
                inputs.append(GameInput.Down)
            }
            
            if CGRectContainsPoint(leftRect, point)
            {
                inputs.append(GameInput.Left)
            }
            
            if CGRectContainsPoint(rightRect, point)
            {
                inputs.append(GameInput.Right)
            }
            
        case "A":
            inputs.append(GameInput.A)
        case "B":
            inputs.append(GameInput.B)
        case "X":
            inputs.append(GameInput.X)
        case "Y":
            inputs.append(GameInput.Y)
        case "L":
            inputs.append(GameInput.L)
        case "R":
            inputs.append(GameInput.R)
        case "Start":
            inputs.append(GameInput.Start)
        case "Select":
            inputs.append(GameInput.Select)
        case "Menu":
            inputs.append(ControllerInput.Menu)
        default:
            inputs = []
        }
        
        return inputs
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
