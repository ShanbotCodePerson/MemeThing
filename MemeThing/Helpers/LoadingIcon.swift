//
//  LoadingIcon.swift
//  MemeThing
//
//  Created by Shannon Draeker on 7/3/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UIView {
    
    func startLoadingIcon(color: UIColor = .loadingIcon) {
        let backgroundView = UIView()
        backgroundView.frame = CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        backgroundView.backgroundColor = UIColor.loadingIconBackground.withAlphaComponent(0.15)
        backgroundView.tag = 475647
        
        let activityIndicator = UIActivityIndicatorView(frame: backgroundView.frame)
        activityIndicator.center = backgroundView.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .large
        activityIndicator.color = color
        activityIndicator.startAnimating()
        self.isUserInteractionEnabled = false
        
        backgroundView.addSubview(activityIndicator)
        
        self.addSubview(backgroundView)
    }
    
    func stopLoadingIcon() {
        if let background = self.viewWithTag(475647){
            background.removeFromSuperview()
        }
        self.isUserInteractionEnabled = true
    }
}
