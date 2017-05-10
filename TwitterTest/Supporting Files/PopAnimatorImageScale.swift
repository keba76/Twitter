//
//  PopAnimatorImageScale.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/9/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit

class PopAnimatorImageScale: NSObject, UIViewControllerAnimatedTransitioning {
    
    let duration = 0.3
    var presenting = true
    var originFrame = CGRect.zero
    
    var dismissCompletion: (()->Void)?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        let toView = transitionContext.view(forKey: .to)!
        
        let bigView = presenting ? toView : transitionContext.view(forKey: .from)!
        
    
       
        
        let initialFrame = presenting ? originFrame : bigView.frame
        let finalFrame = presenting ? bigView.frame : originFrame
        
        let xScaleFactor = presenting ? initialFrame.width / finalFrame.width : finalFrame.width / initialFrame.width
        
        let yScaleFactor = presenting ? initialFrame.height / finalFrame.height : finalFrame.height / initialFrame.height
        
        let scaleTransform = CGAffineTransform(scaleX: xScaleFactor, y: yScaleFactor)
        
        if presenting {
            bigView.transform = scaleTransform
            bigView.center = CGPoint(
                x: initialFrame.midX,
                y: initialFrame.midY)
            bigView.clipsToBounds = true
        }
        
        containerView.addSubview(toView)
        containerView.bringSubview(toFront: bigView)
        UIView.animate(withDuration: duration,  animations: {
            bigView.transform = self.presenting ? CGAffineTransform.identity : scaleTransform
            bigView.center = CGPoint(x: finalFrame.midX,
                                     y: finalFrame.midY)
        },
                       completion:{_ in
                        if !self.presenting {
                            self.dismissCompletion?()
                        }
                        transitionContext.completeTransition(true)
        })
        
    }
}
