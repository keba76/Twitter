//
//  PhotoScaleVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/9/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit

class PhotoScaleVC: UIViewController {
    
    @IBOutlet weak var baseView: UIView!
    
    // @IBOutlet weak var imageScale: UIImageView!
    
    var image: UIImage?
    
    override func viewDidLoad() {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        baseView.addSubview(imageView)
        
        guard let image = self.image else { return }
        imageView.translatesAutoresizingMaskIntoConstraints = false
        baseView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: (image.size.width / image.size.height), constant: 0))
        baseView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: baseView, attribute: .centerX, multiplier: 1, constant: 0))
        baseView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: baseView, attribute: .centerY, multiplier: 1, constant: 0))
        
        // add imageview side constraints
        for attribute: NSLayoutAttribute in [.top, .bottom, .leading, .trailing] {
            let constraintLowPriority = NSLayoutConstraint(item: imageView, attribute: attribute, relatedBy: .equal, toItem: baseView, attribute: attribute, multiplier: 1, constant: 0)
            let constraintGreaterThan = NSLayoutConstraint(item: imageView, attribute: attribute, relatedBy: .greaterThanOrEqual, toItem: baseView, attribute: attribute, multiplier: 1, constant: 0)
            constraintLowPriority.priority = 750
            baseView.addConstraints([constraintLowPriority,constraintGreaterThan])
            
            
        }
        baseView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(actionClose(_:))))
    }
    
    func actionClose(_ tap: UITapGestureRecognizer) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    
}


extension PhotoScaleVC: ImageTransitionProtocol {
    
    func tranisitionSetup() {
        baseView.isHidden = true
        
    }
    
    func tranisitionCleanup() {
        
        baseView.isHidden = false
    }
    
    //return the imageView window frame
    func imageWindowFrame() -> CGRect {
        
        let baseViewFrame = baseView.superview!.convert(baseView.frame, to: nil)
        
        let baseViewRatio = baseView.frame.size.width / baseView.frame.size.height
        let imageRatio = (image?.size.width)! / (image?.size.height)!
        let touchesSides = (imageRatio > baseViewRatio)
        
        if touchesSides {
            let height = baseViewFrame.size.width / imageRatio
            let yPoint = baseViewFrame.origin.y + (baseViewFrame.size.height - height) / 2
            return CGRect(x:baseViewFrame.origin.x, y:yPoint, width:baseViewFrame.size.width, height:height)
        } else {
            let width = baseViewFrame.size.height * imageRatio
            let xPoint = baseViewFrame.origin.x + (baseViewFrame.size.width - width) / 2
            return CGRect(x:xPoint, y:baseViewFrame.origin.y, width:width, height:baseViewFrame.size.height)
        }
    }
}
