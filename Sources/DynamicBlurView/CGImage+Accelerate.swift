//
//  CGImage+Accelerate.swift
//  DynamicBlurView
//
//  Created by Kyohei Ito on 2017/08/17.
//  Copyright © 2017年 kyohei_ito. All rights reserved.
//

import Accelerate
import UIKit

extension CGImage {
    var area: Int {
        width * height
    }

    var size: CGSize {
        CGSize(width: width, height: height)
    }

    var bytes: Int {
        bytesPerRow * height
    }

    var isARG8888: Bool {
        bitsPerPixel == 32 && bitsPerComponent == 8 && (bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue) != 0
    }

    func imageBuffer(with data: UnsafeMutableRawPointer?) -> vImage_Buffer {
        vImage_Buffer(data: data, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: bytesPerRow)
    }

    func context(with data: UnsafeMutableRawPointer?) -> CGContext? {
        colorSpace.flatMap {
            CGContext(
                data: data,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: $0,
                bitmapInfo: bitmapInfo.rawValue
            )
        }
    }

    func blurred(with boxSize: UInt32, iterations: Int, blendColor: UIColor?, blendMode: CGBlendMode) -> CGImage? {
        guard let providerData = dataProvider?.data else {
            return nil
        }

        let inData = malloc(bytes)
        var inBuffer = imageBuffer(with: inData)

        let outData = malloc(bytes)
        var outBuffer = imageBuffer(with: outData)

        let tempSize = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, nil, 0, 0, boxSize, boxSize, nil, vImage_Flags(kvImageEdgeExtend + kvImageGetTempBufferSize))
        let tempData = malloc(tempSize)

        defer {
            free(inData)
            free(outData)
            free(tempData)
        }

        let source = CFDataGetBytePtr(providerData)
        memcpy(inBuffer.data, source, bytes)

        for _ in 0..<iterations {
            vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, tempData, 0, 0, boxSize, boxSize, nil, vImage_Flags(kvImageEdgeExtend))

            let temp = inBuffer.data
            inBuffer.data = outBuffer.data
            outBuffer.data = temp
        }

        return context(with: inBuffer.data)?.makeImage(with: blendColor, blendMode: blendMode, size: size)
    }

    func convertToARG8888() -> CGImage? {
        let bitmapBytesPerRow = width * 4

        var data = Data(count: bitmapBytesPerRow * height)
        return data.withUnsafeMutableBytes { pointer in
            let context = CGContext(
                data: pointer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bitmapBytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
            )

            context?.draw(self, in: CGRect(origin: .zero, size: size))
            return context?.makeImage()
        }
    }

    func arg8888Image() -> CGImage? {
        isARG8888 ? self : convertToARG8888()
    }
}
