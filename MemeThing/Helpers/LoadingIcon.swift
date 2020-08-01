//
//  LoadingIcon.swift
//  MemeThing
//
//  Created by Shannon Draeker on 7/3/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UIView {
    
    func startLoadingIcon() {
        let backgroundView = UIView()
        backgroundView.frame = CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        backgroundView.tag = 475647
        
        let view = UIView()
        view.frame = CGRect(x: self.bounds.width / 2 - 45, y: self.bounds.height / 2 - 45, width: 90, height: 90)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.addCornerRadius(18)
        
        let activityIndicator = UIActivityIndicatorView(frame: backgroundView.frame)
        activityIndicator.center = backgroundView.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .large
        activityIndicator.color = .white
        activityIndicator.startAnimating()
        self.isUserInteractionEnabled = false
        
        backgroundView.addSubview(view)
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
