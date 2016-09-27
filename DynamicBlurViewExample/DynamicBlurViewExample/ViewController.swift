//
//  ViewController.swift
//  DynamicBlurViewExample
//
//  Created by Kyohei Ito on 2015/04/08.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit
import DynamicBlurView

class ViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollBlurView: DynamicBlurView!
    @IBOutlet weak var bottomBlurView: DynamicBlurView!
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var barTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.contentInset.top = navigationBar.bounds.height
        scrollView.contentOffset.y = 0
        
        scrollBlurView.blurRadius = CGFloat(slider.maximumValue)
        scrollBlurView.iterations = 10
        
        bottomBlurView.blurRadius = CGFloat(slider.maximumValue)
        bottomBlurView.iterations = 10
        
        barTopConstraint.constant = -scrollView.contentInset.top
        navigationBar.backgroundColor = UIColor(white: 1, alpha: 0.3)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            scrollBlurView.alpha = 1
            bottomBlurView.alpha = 1
            
            var ratio = abs(scrollView.contentOffset.y) / scrollView.contentInset.top
            if ratio > 1 {
                ratio = 1
                barTopConstraint.constant = 0
            } else {
                barTopConstraint.constant = -(scrollView.contentInset.top - abs(scrollView.contentOffset.y))
            }
            
            scrollBlurView.blurRatio = ratio
            bottomBlurView.blurRatio = ratio
        } else {
            scrollBlurView.alpha = 0
            bottomBlurView.alpha = 0
            barTopConstraint.constant = -scrollView.contentInset.top
        }
    }
    
    @IBAction func buttonTap(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            self.scrollBlurView.blurRadius = 0
            self.bottomBlurView.blurRadius = 0
            }, completion: { _ in
                UIView.animate(withDuration: 0.5, animations: {
                    self.scrollBlurView.blurRadius = CGFloat(self.slider.value)
                    self.bottomBlurView.blurRadius = CGFloat(self.slider.value)
                }) 
        })
    }
    
    @IBAction func sliderChange(_ sender: UISlider) {
        scrollBlurView.blurRadius = CGFloat(sender.value)
        bottomBlurView.blurRadius = CGFloat(sender.value)
    }
}
