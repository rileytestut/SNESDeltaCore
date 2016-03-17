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
                    inputs.append(SNESGameInput.Up)
                }
                
                if CGRectContainsPoint(bottomRect, point)
                {
                    inputs.append(SNESGameInput.Down)
                }
                
                if CGRectContainsPoint(leftRect, point)
                {
                    inputs.append(SNESGameInput.Left)
                }
                
                if CGRectContainsPoint(rightRect, point)
                {
                    inputs.append(SNESGameInput.Right)
                }
                
            case "a": inputs.append(SNESGameInput.A)
            case "b": inputs.append(SNESGameInput.B)
            case "x": inputs.append(SNESGameInput.X)
            case "y": inputs.append(SNESGameInput.Y)
            case "l": inputs.append(SNESGameInput.L)
            case "r": inputs.append(SNESGameInput.R)
            case "start": inputs.append(SNESGameInput.Start)
            case "select": inputs.append(SNESGameInput.Select)
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
