//
//  SlideInPresentationController.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/7/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//


import UIKit

class SlideInPresentationController: UIPresentationController {
    
    fileprivate var dimmingView: UIView!
    var keyBoard: CGFloat
    var finallySize: Bool
    
    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, keyboardHeight: CGFloat = 0, finalSize: Bool = false) {
        self.keyBoard = keyboardHeight
        self.finallySize = finalSize
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        setupDimmingView()
    }
    
    func setupDimmingView() {
        dimmingView = UIView()
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: 0.7)
        dimmingView.alpha = 0.0
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        dimmingView.addGestureRecognizer(recognizer)
    }
    dynamic func handleTap(recognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true)
    }
    
    override func presentationTransitionWillBegin() {
        containerView?.insertSubview(dimmingView, at: 0)
        
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[dimmingView]|",
                                           options: [], metrics: nil, views: ["dimmingView": dimmingView]))
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[dimmingView]|",
                                           options: [], metrics: nil, views: ["dimmingView": dimmingView]))
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1.0
            return
            
        }
        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1.0
        })
    }
    
    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0.0
            return
        }
        
        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.0
        })
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override func size(forChildContentContainer container: UIContentContainer,
                       withParentContainerSize parentSize: CGSize) -> CGSize {
        
        return finallySize ? CGSize(width: parentSize.width, height: parentSize.height) : CGSize(width: parentSize.width, height: keyBoard + 40)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController,
                          withParentContainerSize: containerView!.bounds.size)
        frame.origin.y = finallySize ? 0.0 : containerView!.frame.height - keyBoard - 40
        return frame
    }
}

class SlideInPresentationAnimator: NSObject {
    
    let isPresentation: Bool
    
    init(isPresentation: Bool, initialFrame: CGRect? = nil) {
        self.isPresentation = isPresentation
        super.init()
    }
}
extension SlideInPresentationAnimator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let key = isPresentation ? UITransitionContextViewControllerKey.to : UITransitionContextViewControllerKey.from
        let controller = transitionContext.viewController(forKey: key)!
        if isPresentation {
            transitionContext.containerView.addSubview(controller.view)
        }
        
        let presentedFrame = transitionContext.finalFrame(for: controller)
        var dismissedFrame = presentedFrame
        
        dismissedFrame.origin.y = transitionContext.containerView.frame.size.height
        
        let initialFrame = isPresentation ? dismissedFrame : presentedFrame
        let finalFrame = isPresentation ? presentedFrame : dismissedFrame
        
        controller.view.frame = initialFrame
        var duration: TimeInterval
        var springWithDamping: CGFloat
        var initialSpringVelocity: CGFloat
        var option: UIViewAnimationOptions = []
        
        if self.isPresentation {
            duration = transitionDuration(using: transitionContext)
            springWithDamping = 0.7
            initialSpringVelocity = 0.3
        } else {
            if UIDevice.current.orientation.isLandscape {
                duration = 0.2
            } else {
                duration = 0.3
            }
            springWithDamping = 1.0
            initialSpringVelocity = 1.0
            option = .curveEaseIn
        }
        UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: springWithDamping, initialSpringVelocity: initialSpringVelocity, options: option, animations: {
            controller.view.frame = finalFrame
        }) { finished in
            transitionContext.completeTransition(finished)
        }
    }
}
