//
//  ScrollActivityView.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/22/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit

class ScrollActivityView: UIView {
    
    var activityIndicator = UIActivityIndicatorView()
    
    static var defaultHeight: CGFloat = 60.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupActivityIndicator()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupActivityIndicator()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.activityIndicator.center = CGPoint(x: self.bounds.width/2, y: self.bounds.height/2)
    }
    
    func setupActivityIndicator() {
         activityIndicator.activityIndicatorViewStyle = .gray
        activityIndicator.hidesWhenStopped = true
        self.addSubview(activityIndicator)
    }
    func startAnimation() {
        self.isHidden = false
        self.activityIndicator.startAnimating()
    }
    func stopAnimation() {
        self.activityIndicator.stopAnimating()
        self.isHidden = true
    }
    
}

