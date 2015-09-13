//
//  SNESGameRenderer.swift
//  SNESDeltaCore
//
//  Created by Riley Testut on 9/8/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//

import Foundation
import Accelerate

import DeltaCore

private struct VideoBufferData
{
    static let width = 256 * 2
    static let height = 224 * 2
    static let size = width * height
    
    static let inputBytesPerPixel = 2 // RGB 565
    static let outputBytesPerPixel = 4 // RGBA 8888
}

public class SNESGameRenderer
{
    public var gameView: GameView?
    
    public private(set) var activated: Bool = false
    
    private let inputImageBuffer = UnsafeMutablePointer<UInt8>.alloc(VideoBufferData.size * VideoBufferData.inputBytesPerPixel)
    private let outputImageBuffer = UnsafeMutablePointer<UInt8>.alloc(VideoBufferData.size * VideoBufferData.outputBytesPerPixel)
    
    private var displayLink: CADisplayLink! = nil
    
    init()
    {
        // An active display link is needed for the rendering process to work as expected.
        // Very hacky, but tbh I've spent way too many hours trying to figure out why this is the case
        // I know it's something stupid for sure, but ¯\_(ツ)_/¯
        self.displayLink = CADisplayLink(target: self, selector: "displayLinkDidUpdate:")
    }
    
    deinit
    {
        self.deactivate()
        
        self.inputImageBuffer.dealloc(VideoBufferData.size * VideoBufferData.inputBytesPerPixel)
        self.outputImageBuffer.dealloc(VideoBufferData.size * VideoBufferData.outputBytesPerPixel)
    }
}

extension SNESGameRenderer: SNESScreenRefreshDelegate
{
    @objc public func emulatorBridgeDidRefreshScreen(emulatorBridge: SNESEmulatorBridge)
    {
        autoreleasepool {
            
            var inputVImageBuffer = vImage_Buffer(data: self.inputImageBuffer, height: vImagePixelCount(VideoBufferData.height), width: vImagePixelCount(VideoBufferData.width), rowBytes: VideoBufferData.inputBytesPerPixel * VideoBufferData.width)
            var outputVImageBuffer = vImage_Buffer(data: self.outputImageBuffer, height: vImagePixelCount(VideoBufferData.height), width: vImagePixelCount(VideoBufferData.width), rowBytes: VideoBufferData.outputBytesPerPixel * VideoBufferData.width)
            
            vImageConvert_RGB565toRGBA8888(255, &inputVImageBuffer, &outputVImageBuffer, 0)
            
            let bitmapData = NSData(bytes: self.outputImageBuffer, length: VideoBufferData.size * VideoBufferData.outputBytesPerPixel)
            let image = CIImage(bitmapData: bitmapData, bytesPerRow: VideoBufferData.outputBytesPerPixel * VideoBufferData.width, size: CGSizeMake(CGFloat(VideoBufferData.width / 2), CGFloat(VideoBufferData.height / 2)), format: kCIFormatRGBA8, colorSpace: nil)
            
            self.gameView?.inputImage = image
        }
    }
}

public extension SNESGameRenderer
{
    func activate()
    {
        guard !self.activated else { return }
        
        self.activated = true
        
        self.displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        
        SISetScreen(self.inputImageBuffer)
        
        SNESEmulatorBridge.sharedBridge().screenRefreshDelegate = self
    }
    
    func deactivate()
    {
        guard self.activated else { return }
        
        self.activated = false
        
        self.displayLink.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        
        SNESEmulatorBridge.sharedBridge().screenRefreshDelegate = nil
    }
}

private extension SNESGameRenderer
{
    dynamic func displayLinkDidUpdate(displayLink: CADisplayLink)
    {
        // Stub method
    }
}