//
//  KeyboardStayAppearedVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 6/28/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit

class KeyboardStayAppearedVC: UIViewController {
    
    var keyboardHeight: CGFloat?
    var convert: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.clear
        self.view.isOpaque = false
    }
}


