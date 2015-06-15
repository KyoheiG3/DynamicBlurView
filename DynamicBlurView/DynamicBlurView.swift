//
//  DynamicBlurView.swift
//  DynamicBlurView
//
//  Created by Kyohei Ito on 2015/04/08.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit
import Accelerate

public class DynamicBlurView: UIView {
    private class BlurLayer: CALayer {
        @NSManaged var blurRadius: CGFloat
        
        override class func needsDisplayForKey(key: String) -> Bool {
            if key == "blurRadius" {
                return true
            }
            return super.needsDisplayForKey(key)
        }
    }
    
    public enum DynamicMode {
        case Tracking   // refresh only scrolling
        case Common     // always refresh
        case None       // not refresh
        
        func mode() -> String {
            switch self {
            case .Tracking:
                return UITrackingRunLoopMode
            case .Common:
                return NSRunLoopCommonModes
            case .None:
                return ""
            }
        }
    }
    
    private var staticImage: UIImage?
    private var fromBlurRadius: CGFloat?
    private var displayLink: CADisplayLink?
    private let DisplayLinkSelector: Selector = "displayDidRefresh:"
    private var blurLayer: BlurLayer {
        return layer as! BlurLayer
    }
    
    private var blurPresentationLayer: BlurLayer {
        if let layer = blurLayer.presentationLayer() as? BlurLayer {
            return layer
        }
        
        return blurLayer
    }
    
    public var blurRadius: CGFloat {
        set { blurLayer.blurRadius = newValue }
        get { return blurLayer.blurRadius }
    }
    
    /// Default is Tracking.
    public var dynamicMode: DynamicMode = .None {
        didSet {
            if dynamicMode != oldValue {
                linkForDisplay()
            }
        }
    }
    
    /// Blend color.
    public var blendColor: UIColor?
    
    /// Default is 3.
    public var iterations: Int = 3
    
    /// Please be on true if the if Layer is not captured. Such as UINavigationBar and UIToolbar. Can be used only with DynamicMode.None.
    public var fullScreenCapture: Bool = false
    
    /// Ratio of radius. Defauot is 1.
    public var blurRatio: CGFloat = 1 {
        didSet {
            if oldValue != blurRatio {
                if let image = staticImage {
                    setCaptureImage(image, radius: blurRadius)
                }
            }
        }
    }
    
    public override class func layerClass() -> AnyClass {
        return BlurLayer.self
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        userInteractionEnabled = false
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        userInteractionEnabled = false
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if superview == nil {
            displayLink?.invalidate()
            displayLink = nil
        } else {
            linkForDisplay()
        }
    }
    
    public override func actionForLayer(layer: CALayer!, forKey event: String!) -> CAAction! {
        if event == "blurRadius" {
            fromBlurRadius = nil
            
            if dynamicMode == .None {
                staticImage = capturedImage()
            } else {
                staticImage = nil
            }
            
            if let action = super.actionForLayer(layer, forKey: "backgroundColor") as? CAAnimation {
                fromBlurRadius = blurPresentationLayer.blurRadius
                
                let animation = CABasicAnimation()
                animation.fromValue = fromBlurRadius
                animation.beginTime = CACurrentMediaTime() + action.beginTime
                animation.duration = action.duration
                animation.speed = action.speed
                animation.timeOffset = action.timeOffset
                animation.repeatCount = action.repeatCount
                animation.repeatDuration = action.repeatDuration
                animation.autoreverses = action.autoreverses
                animation.fillMode = action.fillMode
                
                //CAAnimation attributes
                animation.timingFunction = action.timingFunction
                animation.delegate = action.delegate
                
                return animation
            }
        }
        
        return super.actionForLayer(layer, forKey: event)
    }
    
    public override func displayLayer(layer: CALayer!) {
        let blurRadius: CGFloat
        
        if let radius = fromBlurRadius {
            if layer.presentationLayer() == nil {
                blurRadius = radius
            } else {
                blurRadius = blurPresentationLayer.blurRadius
            }
        } else {
            blurRadius = blurLayer.blurRadius
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if let capture = self.staticImage ?? self.capturedImage() {
                self.setCaptureImage(capture, radius: blurRadius)
            }
        }
    }
    
    /// Get blur image again. for DynamicMode.None
    public func refresh() {
        staticImage = nil
        fromBlurRadius = nil
        blurRatio = 1
        displayLayer(blurLayer)
    }
    
    /// Delete blur image. for DynamicMode.None
    public func remove() {
        staticImage = nil
        fromBlurRadius = nil
        blurRatio = 1
        layer.contents = nil
    }
    
    private func linkForDisplay() {
        displayLink?.invalidate()
        displayLink = UIScreen.mainScreen().displayLinkWithTarget(self, selector: DisplayLinkSelector)
        displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: dynamicMode.mode())
    }
    
    private func setCaptureImage(image: UIImage, radius: CGFloat) {
        var setImage: (() -> Void) = {
            if let blurredImage = image.blurredImage(radius, iterations: self.iterations, ratio: self.blurRatio, blendColor: self.blendColor) {
                dispatch_sync(dispatch_get_main_queue()) {
                    self.setContentImage(blurredImage)
                }
            }
        }
        
        if NSThread.currentThread().isMainThread {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), setImage)
        } else {
            setImage()
        }
    }
    
    private func setContentImage(image: UIImage) {
        layer.contents = image.CGImage
        layer.contentsScale = image.scale
    }
    
    private func prepareLayer() -> [CALayer]? {
        let sublayers = superview?.layer.sublayers as? [CALayer]
        
        return sublayers?.reduce([], combine: { acc, layer -> [CALayer] in
            if acc.isEmpty {
                if layer != self.blurLayer {
                    return acc
                }
            }
            
            if layer.hidden == false {
                layer.hidden = true
                
                return acc + [layer]
            }
            
            return acc
        })
    }
    
    private func restoreLayer(layers: [CALayer]) {
        layers.map { $0.hidden = false }
    }
    
    private func capturedImage() -> UIImage! {
        let bounds = blurLayer.convertRect(blurLayer.bounds, toLayer: superview?.layer)
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 1)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetInterpolationQuality(context, kCGInterpolationNone)
        CGContextTranslateCTM(context, -bounds.origin.x, -bounds.origin.y)
        
        if NSThread.currentThread().isMainThread {
            renderInContext(context)
        } else {
            dispatch_sync(dispatch_get_main_queue()) {
                self.renderInContext(context)
            }
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func renderInContext(ctx: CGContext!) {
        let layers = prepareLayer()
        
        if fullScreenCapture && dynamicMode == .None {
            if let superview = superview {
                UIView.setAnimationsEnabled(false)
                superview.drawViewHierarchyInRect(superview.bounds, afterScreenUpdates: true)
                UIView.setAnimationsEnabled(true)
            }
        } else {
            superview?.layer.renderInContext(ctx)
        }
        
        if let layers = layers {
            restoreLayer(layers)
        }
    }
    
    func displayDidRefresh(displayLink: CADisplayLink) {
        displayLayer(blurLayer)
    }
}

public extension UIImage {
    func blurredImage(radius: CGFloat, iterations: Int, ratio: CGFloat, blendColor: UIColor?) -> UIImage! {
        if floorf(Float(size.width)) * floorf(Float(size.height)) <= 0.0 {
            return self
        }
        
        let imageRef = CGImage
        var boxSize = UInt32(radius * scale * ratio)
        if boxSize % 2 == 0 {
            boxSize++
        }
        
        let height = CGImageGetHeight(imageRef)
        let width = CGImageGetWidth(imageRef)
        let rowBytes = CGImageGetBytesPerRow(imageRef)
        let bytes = rowBytes * height
        
        let inData = malloc(bytes)
        var inBuffer = vImage_Buffer(data: inData, height: UInt(height), width: UInt(width), rowBytes: rowBytes)
        
        let outData = malloc(bytes)
        var outBuffer = vImage_Buffer(data: outData, height: UInt(height), width: UInt(width), rowBytes: rowBytes)
        
        let tempFlags = vImage_Flags(kvImageEdgeExtend + kvImageGetTempBufferSize)
        let tempSize = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, nil, 0, 0, boxSize, boxSize, nil, tempFlags)
        let tempBuffer = malloc(tempSize)
        
        let provider = CGImageGetDataProvider(imageRef)
        let copy = CGDataProviderCopyData(provider)
        let source = CFDataGetBytePtr(copy)
        memcpy(inBuffer.data, source, bytes)
        
        let flags = vImage_Flags(kvImageEdgeExtend)
        for index in 0 ..< iterations {
            vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, tempBuffer, 0, 0, boxSize, boxSize, nil, flags)
            
            let temp = inBuffer.data
            inBuffer.data = outBuffer.data
            outBuffer.data = temp
        }
        
        free(outBuffer.data)
        free(tempBuffer)
        
        let colorSpace = CGImageGetColorSpace(imageRef)
        let bitmapInfo = CGImageGetBitmapInfo(imageRef)
        let bitmapContext = CGBitmapContextCreate(inBuffer.data, width, height, 8, rowBytes, colorSpace, bitmapInfo)
        
        if let color = blendColor {
            CGContextSetFillColorWithColor(bitmapContext, color.CGColor)
            CGContextSetBlendMode(bitmapContext, kCGBlendModePlusLighter)
            CGContextFillRect(bitmapContext, CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        let bitmap = CGBitmapContextCreateImage(bitmapContext)
        let image = UIImage(CGImage: bitmap, scale: scale, orientation: imageOrientation)
        free(inBuffer.data)
        
        return image
    }
}
