//
//  ViewController.swift
//  DynamicBlurViewExample
//
//  Created by Kyohei Ito on 2015/04/08.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit
import DynamicBlurView

class ViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var blurView: DynamicBlurView!
    @IBOutlet weak var slider: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        blurView.dynamicMode = .Common
        blurView.blurRadius = CGFloat(slider.maximumValue)
        
        webView.loadRequest(NSURLRequest(URL: NSURL(string: "http://www.google.com")!))
    }

    @IBAction func buttonTap(sender: UIButton) {
        UIView.animateWithDuration(0.5, animations: {
            self.blurView.blurRadius = 0
            }, completion: { _ in
                UIView.animateWithDuration(0.5) {
                    self.blurView.blurRadius = CGFloat(self.slider.value)
                }
        })
    }
    
    @IBAction func switchChange(sender: UISwitch) {
        if sender.on {
            blurView.dynamicMode = .Common
        } else {
            blurView.dynamicMode = .Tracking
        }
    }
    
    @IBAction func sliderChange(sender: UISlider) {
        blurView.blurRadius = CGFloat(sender.value)
    }
}

