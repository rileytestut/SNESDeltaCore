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
    
    public override func inputsForItem(item: Item, point: CGPoint) -> [InputType]
    {
        var inputs: [InputType] = []
        
        for key in item.keys
        {
            switch key
            {
            case "dpad":
                
                let topRect = CGRect(x: item.frame.minX, y: item.frame.minY, width: item.frame.width, height: item.frame.height / 3.0)
                let bottomRect = CGRect(x: item.frame.minX, y: item.frame.maxY - item.frame.height / 3.0, width: item.frame.width, height: item.frame.height / 3.0)
                let leftRect = CGRect(x: item.frame.minX, y: item.frame.minY, width: item.frame.width / 3.0, height: item.frame.height)
                let rightRect = CGRect(x: item.frame.maxX - item.frame.width / 3.0, y: item.frame.minY, width: item.frame.width / 3.0, height: item.frame.height)
                
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
                
            case "a": inputs.append(GameInput.A)
            case "b": inputs.append(GameInput.B)
            case "x": inputs.append(GameInput.X)
            case "y": inputs.append(GameInput.Y)
            case "l": inputs.append(GameInput.L)
            case "r": inputs.append(GameInput.R)
            case "start": inputs.append(GameInput.Start)
            case "select": inputs.append(GameInput.Select)
            case "menu": inputs.append(ControllerInput.Menu)
            default: break
            }
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
