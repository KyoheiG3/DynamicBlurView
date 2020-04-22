//
//  CALayer+Conversion.swift
//  DynamicBlurView
//
//  Created by Kyohei Ito on 2020/04/22.
//

import QuartzCore

extension CALayer {
    func convertRect(to layer: CALayer?) -> CGRect {
        convert(bounds, to: layer)
    }
}
