//
//  SNESInputTransformer.swift
//  SNESDeltaCore
//
//  Created by Riley Testut on 6/29/16.
//  Copyright © 2016 Riley Testut. All rights reserved.
//

import Foundation

@objc public enum SNESGameInput: Int, Input
{
    case up     = 1
    case down   = 2
    case left   = 4
    case right  = 8
    case a      = 16
    case b      = 32
    case x      = 64
    case y      = 128
    case l      = 256
    case r      = 512
    case start  = 1024
    case select = 2048
}

public struct SNESInputTransformer: InputTransforming
{
    public var gameInputType: Input.Type = SNESGameInput.self
    
    public func inputs(for controllerSkin: ControllerSkin, item: ControllerSkin.Item, point: CGPoint) -> [Input]
    {
        var inputs: [Input] = []
        
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
                
            case "a": inputs.append(SNESGameInput.a)
            case "b": inputs.append(SNESGameInput.b)
            case "x": inputs.append(SNESGameInput.x)
            case "y": inputs.append(SNESGameInput.y)
            case "l": inputs.append(SNESGameInput.l)
            case "r": inputs.append(SNESGameInput.r)
            case "start": inputs.append(SNESGameInput.start)
            case "select": inputs.append(SNESGameInput.select)
            case "menu": inputs.append(ControllerInput.menu)
            default: break
            }
        }
        
        return inputs
    }
    
    public func inputs(for controller: MFiExternalController, input: MFiExternalControllerInput) -> [Input]
    {
        var inputs: [Input] = []
        
        switch input
        {
        case let .dPad(xAxis: xAxis, yAxis: yAxis): inputs.append(contentsOf: self.inputs(forXAxis: xAxis, YAxis: yAxis))
        case let .leftThumbstick(xAxis: xAxis, yAxis: yAxis): inputs.append(contentsOf: self.inputs(forXAxis: xAxis, YAxis: yAxis))
        case .rightThumbstick(xAxis: _, yAxis: _): break
        case .a: inputs.append(SNESGameInput.a)
        case .b: inputs.append(SNESGameInput.b)
        case .x: inputs.append(SNESGameInput.x)
        case .y: inputs.append(SNESGameInput.y)
        case .l: inputs.append(SNESGameInput.l)
        case .r: inputs.append(SNESGameInput.r)
        case .leftTrigger: inputs.append(SNESGameInput.l)
        case .rightTrigger: inputs.append(SNESGameInput.r)
        }
        
        return inputs
    }
}

private extension SNESInputTransformer
{
    func inputs(forXAxis xAxis: Float, YAxis yAxis: Float) -> [Input]
    {
        var inputs: [Input] = []
        
        if xAxis > 0.0
        {
            inputs.append(SNESGameInput.right)
        }
        else if xAxis < 0.0
        {
            inputs.append(SNESGameInput.left)
        }
        
        if yAxis > 0.0
        {
            inputs.append(SNESGameInput.up)
        }
        else if yAxis < 0.0
        {
            inputs.append(SNESGameInput.down)
        }
        
        return inputs
    }
}
