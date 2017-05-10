//
//  PhotoScaleSimpleVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/21/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit

class PhotoScaleSimpleVC: UIViewController {
    
    // @IBOutlet weak var imageScale: UIImageView!
    
    var image: UIImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        view.addSubview(imageView)
        
        guard let image = self.image else { return }
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraint(NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: (image.size.width / image.size.height), constant: 0))
        view.addConstraint(NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0))
        
        // add imageview side constraints
        for attribute: NSLayoutAttribute in [.top, .bottom, .leading, .trailing] {
            let constraintLowPriority = NSLayoutConstraint(item: imageView, attribute: attribute, relatedBy: .equal, toItem: view, attribute: attribute, multiplier: 1, constant: 0)
            let constraintGreaterThan = NSLayoutConstraint(item: imageView, attribute: attribute, relatedBy: .greaterThanOrEqual, toItem: view, attribute: attribute, multiplier: 1, constant: 0)
            constraintLowPriority.priority = 750
            view.addConstraints([constraintLowPriority,constraintGreaterThan])
            
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // self.imageScale.image = image
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(actionClose(_:))))
    }
    
    func actionClose(_ tap: UITapGestureRecognizer) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
}
