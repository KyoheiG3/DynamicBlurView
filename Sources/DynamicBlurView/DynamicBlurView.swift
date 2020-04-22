//
//  DynamicBlurView.swift
//  DynamicBlurView
//
//  Created by Kyohei Ito on 2015/04/08.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit

open class DynamicBlurView: UIView {
    open override class var layerClass: AnyClass {
        BlurLayer.self
    }

    private var blurLayer: BlurLayer {
        layer as! BlurLayer
    }

    private var staticImage: UIImage?
    private var displayLink: CADisplayLink? {
        didSet {
            oldValue?.invalidate()
        }
    }

    private var renderingTarget: UIView? {
        window != nil
            ? (isDeepRendering ? window : superview)
            : nil
    }

    private var relativeLayerRect: CGRect {
        blurLayer.current.convertRect(to: renderingTarget?.layer)
    }

    /// Radius of blur.
    open var blurRadius: CGFloat {
        get { blurLayer.blurRadius }
        set { blurLayer.blurRadius = newValue }
    }

    /// Default is none.
    open var trackingMode: TrackingMode = .none {
        didSet {
            if trackingMode != oldValue {
                linkForDisplay()
            }
        }
    }

    /// Blend color.
    open var blendColor: UIColor?

	/// Blend mode.
    open var blendMode: CGBlendMode = .plusLighter

    /// Default is 3.
    open var iterations = 3

    /// If the view want to render beyond the layer, should be true.
    open var isDeepRendering = false

    /// When none of tracking mode, it can change the radius of blur with the ratio. Should set from 0 to 1.
    open var blurRatio: CGFloat = 1 {
        didSet {
            if oldValue != blurRatio, let blurredImage = staticImage.flatMap(imageBlurred) {
                blurLayer.draw(blurredImage)
            }
        }
    }

    /// Quality of captured image.
    open var quality: CaptureQuality {
        get { blurLayer.quality }
        set { blurLayer.quality = newValue }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isUserInteractionEnabled = false
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()

        if trackingMode == .none {
            renderingTarget?.layoutIfNeeded()
            staticImage = currentImage()
        }
    }

    open override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if superview == nil {
            displayLink = nil
        } else {
            linkForDisplay()
        }
    }

    func imageBlurred(_ image: UIImage) -> UIImage? {
        image.blurred(
            radius: blurLayer.currentBlurRadius,
            iterations: iterations,
            ratio: blurRatio,
            blendColor: blendColor,
            blendMode: blendMode
        )
    }

    func currentImage() -> UIImage? {
        renderingTarget.flatMap { view in
            blurLayer.snapshotImageBelowLayer(view.layer, in: isDeepRendering ? view.bounds : relativeLayerRect)
        }
    }
}

extension DynamicBlurView {
    open override func display(_ layer: CALayer) {
        if let blurredImage = (staticImage ?? currentImage()).flatMap(imageBlurred) {
            blurLayer.draw(blurredImage)

            if isDeepRendering {
                blurLayer.contentsRect = relativeLayerRect.rectangle(blurredImage.size)
            }
        }
    }
}

extension DynamicBlurView {
    private func linkForDisplay() {
        displayLink = UIScreen.main.displayLink(withTarget: self, selector: #selector(DynamicBlurView.displayDidRefresh(_:)))
        displayLink?.add(to: .main, forMode: RunLoop.Mode(rawValue: trackingMode.description))
    }

    @objc private func displayDidRefresh(_ displayLink: CADisplayLink) {
        display(layer)
    }
}

extension DynamicBlurView {
    /// Remove cache of blur image then get it again.
    open func refresh() {
        blurLayer.refresh()
        staticImage = nil
        blurRatio = 1
        display(layer)
    }

    /// Remove cache of blur image.
    open func remove() {
        blurLayer.refresh()
        staticImage = nil
        blurRatio = 1
        layer.contents = nil
    }

    /// Should use when needs to change layout with animation when is set none of tracking mode.
    public func animate() {
        blurLayer.animate()
    }
}
