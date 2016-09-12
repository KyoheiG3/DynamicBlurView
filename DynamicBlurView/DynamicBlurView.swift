//
//  DynamicBlurView.swift
//  DynamicBlurView
//
//  Created by Kyohei Ito on 2015/04/08.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit
import Accelerate

open class DynamicBlurView: UIView {
    private class BlurLayer: CALayer {
        static let BlurRadiusKey = "blurRadius"
        @NSManaged var blurRadius: CGFloat
        
        override class func needsDisplay(forKey key: String) -> Bool {
            if key == BlurRadiusKey {
                return true
            }
            return super.needsDisplay(forKey: key)
        }
    }
    
    public enum DynamicMode {
        case tracking   // refresh only scrolling
        case common     // always refresh
        case none       // not refresh
        
        func mode() -> String {
            switch self {
            case .tracking:
                return RunLoopMode.UITrackingRunLoopMode.rawValue
            case .common:
                return RunLoopMode.commonModes.rawValue
            case .none:
                return ""
            }
        }
    }
    
    public enum CaptureImageQuality {
        case `default`
        case low
        case medium
        case high
        
        var imageScale: CGFloat {
            switch self {
            case .default, .high:
                return 0
            case .low, .medium:
                return  1
            }
        }
        
        var contextInterpolation: CGInterpolationQuality {
            switch self {
            case .default, .low:
                return .none
            case .medium, .high:
                return .default
            }
        }

    }
    
    private var staticImage: UIImage?
    private var fromBlurRadius: CGFloat?
    private var displayLink: CADisplayLink?
    private let DisplayLinkSelector: Selector = #selector(DynamicBlurView.displayDidRefresh(_:))
    private var blurLayer: BlurLayer {
        return layer as! BlurLayer
    }
    
    private var blurPresentationLayer: BlurLayer {
        if let layer = blurLayer.presentation() {
            return layer
        }
        
        return blurLayer
    }
    
    private var queue: DispatchQueue {
        if #available (iOS 8.0, *) {
            return DispatchQueue.global(qos: .userInteractive)
        } else {
            return DispatchQueue.global(priority: .high)
        }
    }
    
    open var blurRadius: CGFloat {
        set { blurLayer.blurRadius = newValue }
        get { return blurLayer.blurRadius }
    }
    
    /// Default is Tracking.
    open var dynamicMode: DynamicMode = .none {
        didSet {
            if dynamicMode != oldValue {
                linkForDisplay()
            }
        }
    }
    
    /// Blend color.
    open var blendColor: UIColor?

	/// Blend mode.
    open var blendMode: CGBlendMode = .plusLighter

    /// Default is 3.
    open var iterations: Int = 3
    
    /// Please be on true if Layer is not captured. Such as UINavigationBar and UIToolbar. Can be used only with DynamicMode.mone.
    open var fullScreenCapture: Bool = false
    
    /// Ratio of radius. Defauot is 1.
    open var blurRatio: CGFloat = 1 {
        didSet {
            if oldValue != blurRatio {
                if let image = staticImage {
                    setCaptureImage(image, radius: blurRadius)
                }
            }
        }
    }
    
    /// Quality of captured image.
    open var quality: CaptureImageQuality = .default
    
    open override class var layerClass : AnyClass {
        return BlurLayer.self
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        isUserInteractionEnabled = false
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        isUserInteractionEnabled = false
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if superview == nil {
            displayLink?.invalidate()
            displayLink = nil
        } else {
            linkForDisplay()
        }
    }
    
    open override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if event == BlurLayer.BlurRadiusKey {
            fromBlurRadius = nil
            
            if dynamicMode == .none {
                staticImage = capturedImage()
            } else {
                staticImage = nil
            }
            
            if let action = super.action(for: layer, forKey: "backgroundColor") as? CAAnimation {
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
        
        return super.action(for: layer, forKey: event)
    }
    
    open override func display(_ layer: CALayer) {
        let blurRadius: CGFloat
        
        if let radius = fromBlurRadius {
            if layer.presentation() == nil {
                blurRadius = radius
            } else {
                blurRadius = blurPresentationLayer.blurRadius
            }
        } else {
            blurRadius = blurLayer.blurRadius
        }
        
        queue.async {
            if let capture = self.staticImage ?? self.capturedImage() {
                self.setCaptureImage(capture, radius: blurRadius)
            }
        }
    }
    
    /// Get blur image again. for DynamicMode.None
    open func refresh() {
        staticImage = nil
        fromBlurRadius = nil
        blurRatio = 1
        display(blurLayer)
    }
    
    /// Delete blur image. for DynamicMode.None
    open func remove() {
        staticImage = nil
        fromBlurRadius = nil
        blurRatio = 1
        layer.contents = nil
    }
    
    private func linkForDisplay() {
        displayLink?.invalidate()
        displayLink = UIScreen.main.displayLink(withTarget: self, selector: DisplayLinkSelector)
        displayLink?.add(to: RunLoop.main, forMode: RunLoopMode(rawValue: dynamicMode.mode()))
    }
    
    private func setCaptureImage(_ image: UIImage, radius: CGFloat) {
        let setImage: (() -> Void) = {
            if let blurredImage = image.blurredImage(radius, iterations: self.iterations, ratio: self.blurRatio, blendColor: self.blendColor, blendMode: self.blendMode) {
                DispatchQueue.main.sync {
                    self.setContentImage(blurredImage)
                }
            }
        }
        
        if Thread.current.isMainThread {
            queue.async(execute: setImage)
        } else {
            setImage()
        }
    }
    
    private func setContentImage(_ image: UIImage) {
        layer.contents = image.cgImage
        layer.contentsScale = image.scale
    }
    
    private func prepareLayer() -> [CALayer]? {
        let sublayers = superview?.layer.sublayers
        
        return sublayers?.reduce([], { acc, layer -> [CALayer] in
            if acc.isEmpty {
                if layer != self.blurLayer {
                    return acc
                }
            }
            
            if layer.isHidden == false {
                layer.isHidden = true
                
                return acc + [layer]
            }
            
            return acc
        })
    }
    
    private func restoreLayer(_ layers: [CALayer]) {
        for layer in layers {
            layer.isHidden = false
        }
    }
    
    private func capturedImage() -> UIImage? {
        let bounds = blurLayer.convert(blurLayer.bounds, to: superview?.layer)
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, quality.imageScale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.interpolationQuality = quality.contextInterpolation
        context.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
        
        if Thread.current.isMainThread {
            renderInContext(context)
        } else {
            DispatchQueue.main.sync {
                self.renderInContext(context)
            }
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func renderInContext(_ ctx: CGContext!) {
        let layers = prepareLayer()
        
        if fullScreenCapture && dynamicMode == .none {
            if let superview = superview {
                UIView.setAnimationsEnabled(false)
                superview.drawHierarchy(in: superview.bounds, afterScreenUpdates: true)
                UIView.setAnimationsEnabled(true)
            }
        } else {
            superview?.layer.render(in: ctx)
        }
        
        if let layers = layers {
            restoreLayer(layers)
        }
    }
    
    func displayDidRefresh(_ displayLink: CADisplayLink) {
        display(blurLayer)
    }
}

public extension UIImage {
    func blurredImage(_ radius: CGFloat, iterations: Int, ratio: CGFloat, blendColor: UIColor?, blendMode: CGBlendMode) -> UIImage? {
        if floorf(Float(size.width)) * floorf(Float(size.height)) <= 0.0 || radius <= 0 {
            return self
        }
        
        guard let imageRef = cgImage else {
            return nil
        }
        var boxSize = UInt32(radius * scale * ratio)
        if boxSize % 2 == 0 {
            boxSize += 1
        }
        
        let height = imageRef.height
        let width = imageRef.width
        let rowBytes = imageRef.bytesPerRow
        let bytes = rowBytes * height
        
        let inData = malloc(bytes)
        var inBuffer = vImage_Buffer(data: inData, height: UInt(height), width: UInt(width), rowBytes: rowBytes)
        
        let outData = malloc(bytes)
        var outBuffer = vImage_Buffer(data: outData, height: UInt(height), width: UInt(width), rowBytes: rowBytes)
        
        let tempFlags = vImage_Flags(kvImageEdgeExtend + kvImageGetTempBufferSize)
        let tempSize = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, nil, 0, 0, boxSize, boxSize, nil, tempFlags)
        let tempBuffer = malloc(tempSize)
        
        defer {
            free(outBuffer.data)
            free(tempBuffer)
            free(inBuffer.data)
        }
        
        guard let provider = imageRef.dataProvider else {
            return nil
        }
        
        let copy = provider.data
        let source = CFDataGetBytePtr(copy)
        memcpy(inBuffer.data, source, bytes)
        
        let flags = vImage_Flags(kvImageEdgeExtend)
        for _ in 0 ..< iterations {
            vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, tempBuffer, 0, 0, boxSize, boxSize, nil, flags)
            
            let temp = inBuffer.data
            inBuffer.data = outBuffer.data
            outBuffer.data = temp
        }
        
        guard let colorSpace = imageRef.colorSpace else {
            return nil
        }
        
        let bitmapInfo = imageRef.bitmapInfo
        guard let bitmapContext = CGContext(data: inBuffer.data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: rowBytes, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        
        if let color = blendColor {
            bitmapContext.setFillColor(color.cgColor)
            bitmapContext.setBlendMode(blendMode)
            bitmapContext.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        if let bitmap = bitmapContext.makeImage() {
            return UIImage(cgImage: bitmap, scale: scale, orientation: imageOrientation)
        }
        
        return nil
    }
}
