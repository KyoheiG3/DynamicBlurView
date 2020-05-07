//
//  BlurLayer.swift
//  DynamicBlurView
//
//  Created by Kyohei Ito on 2017/08/14.
//  Copyright © 2017年 kyohei_ito. All rights reserved.
//

import UIKit

class BlurLayer: CALayer {
    private static let blurRadiusKey = "blurRadius"
    private static let blurLayoutKey = "blurLayout"
    private static let opacityKey = "opacity"
    @NSManaged var blurRadius: CGFloat
    @NSManaged private var blurLayout: CGFloat

    private var fromBlurRadius: CGFloat?
    var currentBlurRadius: CGFloat {
        presentation()?.blurRadius ?? fromBlurRadius ?? blurRadius
    }

    var current: BlurLayer {
        presentation() ?? self
    }

    var quality: CaptureQuality = .medium

    override class func needsDisplay(forKey key: String) -> Bool {
        key == blurRadiusKey || key == blurLayoutKey
            ? true
            : super.needsDisplay(forKey: key)
    }

    open override func action(forKey event: String) -> CAAction? {
        if event == BlurLayer.blurRadiusKey {
            fromBlurRadius = nil

            if let action = super.action(forKey: BlurLayer.opacityKey) as? CABasicAnimation {
                fromBlurRadius = current.blurRadius

                action.keyPath = event
                action.fromValue = fromBlurRadius
                return action
            }
        }

        if event == BlurLayer.blurLayoutKey, let action = super.action(forKey: BlurLayer.opacityKey) as? CABasicAnimation {
            action.keyPath = event
            action.fromValue = 0
            action.toValue = 1
            return action
        }

        return super.action(forKey: event)
    }
}

extension BlurLayer {
    func refresh() {
        fromBlurRadius = nil
    }

    func animate() {
        UIView.performWithoutAnimation {
            blurLayout = 0
        }
        blurLayout = 1
    }

    func snapshotImageBelowLayer(_ layer: CALayer, in rect: CGRect) -> UIImage? {
        guard let context = CGContext.imageContext(in: rect, isOpaque: isOpaque, quality: quality) else {
            return nil
        }

        renderBelowLayer(layer, in: context)

        defer {
            UIGraphicsEndImageContext()
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension CALayer {
    func draw(_ image: UIImage) {
        contents = image.cgImage
        contentsScale = image.scale
    }

    func renderBelowLayer(_ layer: CALayer, in context: CGContext) {
        let layers = hideOverlappedLayers(layer.sublayers)
        layer.render(in: context)
        layers.forEach {
            $0.isHidden = false
        }
    }

    func hideOverlappedLayers(_ layers: [CALayer]?) -> [CALayer] {
        var hiddenLayers: [CALayer] = []
        for layer in layers?.reversed() ?? [] {
            if isHung(in: layer) {
                hiddenLayers.append(contentsOf: hideOverlappedLayers(layer.sublayers))
                break
            }

            if !layer.isHidden {
                layer.isHidden = true
                hiddenLayers.append(layer)
            }

            if layer === self {
                break
            }
        }
        return hiddenLayers
    }

    func isHung(in target: CALayer) -> Bool {
        var layer = superlayer
        while layer != nil {
            if layer === target {
                return true
            }
            layer = layer?.superlayer
        }

        return false
    }
}
