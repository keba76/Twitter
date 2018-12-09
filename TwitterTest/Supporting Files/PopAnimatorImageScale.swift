//
//  PopAnimatorImageScale.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/9/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit

protocol KeyTop { func keyboardTop() }

class PopAnimatorImageScale: NSObject, UIViewControllerAnimatedTransitioning {
    
    let duration = 0.3
    var presenting = true
    var originFrame = CGRect.zero
    var delegate: KeyTop?
    var deltaOffsetHeightInitial: CGFloat = 0.0
    var deltaOffsetHeightFinale: CGFloat = 0.0
    
    var dismissCompletion: (()->Void)?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        let toView = transitionContext.view(forKey: .to)!
        
        let bigView = presenting ? toView : transitionContext.view(forKey: .from)!
        
        var finalFrame: CGRect
        if presenting {
            finalFrame = bigView.frame
        } else {
            if self.deltaOffsetHeightInitial == self.deltaOffsetHeightFinale {
                finalFrame = originFrame
            } else {
                finalFrame = originFrame
                finalFrame.origin.y = self.deltaOffsetHeightFinale - (self.deltaOffsetHeightInitial - self.originFrame.origin.y)
            }
        }
        let initialFrame = presenting ? originFrame : bigView.frame
        
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
        containerView.bringSubviewToFront(bigView)
        
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseIn, animations: {
            bigView.transform = self.presenting ? CGAffineTransform.identity : scaleTransform
            bigView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
            if !self.presenting { bigView.alpha = 0.2 }
        }) { finished in
            if !self.presenting {
                self.dismissCompletion?()
                self.delegate?.keyboardTop()
            }
            transitionContext.completeTransition(true)
        }
    }
}
