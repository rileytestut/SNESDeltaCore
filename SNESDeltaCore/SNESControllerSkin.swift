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
    //MARK: - DynamicObject
    /// DynamicObject
    var dynamicSubclass: Bool {
        return true
    }
    
    var dynamicIndentifier: String {
        return GameType.snes.rawValue
    }

    
    //MARK: - ControllerSkin
    /// ControllerSkin
    public override class func defaultControllerSkinForGameUTI(_ UTI: String) -> ControllerSkin?
    {
        let URL = Bundle(for: self).urlForResource("Default", withExtension: "deltaskin")
        let controllerSkin = ControllerSkin(URL: URL!)
        
        return controllerSkin
    }
    
    public override func inputsForItem(_ item: Item, point: CGPoint) -> [InputProtocol]
    {
        var inputs: [InputProtocol] = []
        
        for key in item.keys
        {
            switch key
            {
            case "dpad":
                
                let topRect = CGRect(x: item.frame.minX, y: item.frame.minY, width: item.frame.width, height: item.frame.height / 3.0)
                let bottomRect = CGRect(x: item.frame.minX, y: item.frame.maxY - item.frame.height / 3.0, width: item.frame.width, height: item.frame.height / 3.0)
                let leftRect = CGRect(x: item.frame.minX, y: item.frame.minY, width: item.frame.width / 3.0, height: item.frame.height)
                let rightRect = CGRect(x: item.frame.maxX - item.frame.width / 3.0, y: item.frame.minY, width: item.frame.width / 3.0, height: item.frame.height)
                
                if topRect.contains(point)
                {
                    inputs.append(SNESGameInput.up)
                }
                
                if bottomRect.contains(point)
                {
                    inputs.append(SNESGameInput.down)
                }
                
                if leftRect.contains(point)
                {
                    inputs.append(SNESGameInput.left)
                }
                
                if rightRect.contains(point)
                {
                    inputs.append(SNESGameInput.right)
                }
                
            case "a": inputs.append(SNESGameInput.A)
            case "b": inputs.append(SNESGameInput.B)
            case "x": inputs.append(SNESGameInput.X)
            case "y": inputs.append(SNESGameInput.Y)
            case "l": inputs.append(SNESGameInput.L)
            case "r": inputs.append(SNESGameInput.R)
            case "start": inputs.append(SNESGameInput.start)
            case "select": inputs.append(SNESGameInput.select)
            case "menu": inputs.append(ControllerInput.menu)
            default: break
            }
        }
        
        return inputs
    }
}
