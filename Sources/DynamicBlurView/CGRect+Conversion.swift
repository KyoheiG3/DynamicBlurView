//
//  CGRect+Conversion.swift
//  DynamicBlurView
//
//  Created by Kyohei Ito on 2020/04/21.
//

import CoreGraphics

extension CGRect {
    func rectangle(_ s: CGSize) -> CGRect {
        CGRect(
            x: origin.x / s.width,
            y: origin.y / s.height,
            width: size.width / s.width,
            height: size.height / s.height
        )
    }
}
