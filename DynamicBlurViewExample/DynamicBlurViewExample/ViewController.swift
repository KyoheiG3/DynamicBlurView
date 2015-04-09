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
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var animationView: DynamicBlurView!
    @IBOutlet weak var dynamicView: DynamicBlurView!
    @IBOutlet weak var variableView: DynamicBlurView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        animationView.dynamicMode = .Common
        animationView.blurRadius = CGFloat(slider.maximumValue)
        
        dynamicView.dynamicMode = .Common
        dynamicView.blurRadius = CGFloat(slider.maximumValue)
        
        variableView.dynamicMode = .Common
        variableView.blurRadius = CGFloat(slider.maximumValue)
        
        webView.loadRequest(NSURLRequest(URL: NSURL(string: "http://www.google.com")!))
    }

    @IBAction func buttonTap(sender: UIButton) {
        UIView.animateWithDuration(0.5, animations: {
            self.animationView.blurRadius = 0
            }, completion: { _ in
                UIView.animateWithDuration(0.5) {
                    self.animationView.blurRadius = CGFloat(self.slider.value)
                }
        })
    }
    
    @IBAction func switchChange(sender: UISwitch) {
        if sender.on {
            dynamicView.dynamicMode = .Common
        } else {
            dynamicView.dynamicMode = .Tracking
        }
    }
    
    @IBAction func sliderChange(sender: UISlider) {
        variableView.blurRadius = CGFloat(sender.value)
    }
}

