//
//  DynamicBlurViewTests.swift
//  DynamicBlurViewTests
//
//  Created by Kyohei Ito on 2015/04/08.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit
import XCTest
@testable import DynamicBlurView

class DynamicBlurViewTests: XCTestCase {
  
  func testBlurring() {
    let bundle = Bundle(for: type(of: self))
    let path = bundle.path(forResource: "cat", ofType: "jpg")
    guard let image = UIImage(contentsOfFile: path!) else {
      return XCTFail("Test image not found")
    }

    guard let blurredImage = image.blurred(radius: 17,
                                           iterations: 3,
                                           ratio: 1,
                                           blendColor: nil,
                                           blendMode: CGBlendMode.clear) else {
                                            return XCTFail("Blur method failed")
    }
    
    XCTAssertNotEqual(image, blurredImage)
  }
  
}
