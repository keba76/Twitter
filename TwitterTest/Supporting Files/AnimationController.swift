//
//  AnimationController.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/12/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit

protocol ImageTransitionProtocol {
    func tranisitionSetup()
    func tranisitionCleanup()
    func imageWindowFrame() -> CGRect
}

class AnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    private var image: UIImage?
    private var alphaTabs: String?
    private var fromDelegate: ImageTransitionProtocol?
    private var toDelegate: ImageTransitionProtocol?
    private var data: SomeTweetsData?
    private var frameImage: CGRect?
    private var frameBackImage: CGRect?
    private var secondImage: UIImage?
    private var cornerRadius = true
    
    static var screenViewNav: UIView?
    static var screenViewTab: UIView?
    
    func setupImageTransition(data: SomeTweetsData, fromDelegate: ImageTransitionProtocol, toDelegate: ImageTransitionProtocol, alphaTabs: String?){
    
        self.image = data.image
        self.data = data
        self.fromDelegate = fromDelegate
        self.toDelegate = toDelegate
        self.alphaTabs = alphaTabs
        self.cornerRadius = data.cornerRadius
        if let frameImage = data.frameImage, data.frameBackImage != CGRect.zero {
            self.frameImage = frameImage
            self.frameBackImage = data.frameBackImage
            self.secondImage = data.secondImageForBanner
        } else {
            self.frameImage = nil
            self.frameBackImage = nil
            self.secondImage = nil
        }
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return alphaTabs != nil ? 0.4 : 0.3
    }
    
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
            else { return }
        fromVC.view.backgroundColor = UIColor.black
        toVC.view.backgroundColor = UIColor.black
        
        toVC.view.frame = fromVC.view.frame
        
        let fromSnapshot = fromVC.view.snapshotView(afterScreenUpdates: true)
        
        if !Profile.shotView {
            let nav = fromVC.view.snapshotView(afterScreenUpdates: true)
            let tab = fromVC.view.snapshotView(afterScreenUpdates: true)
            AnimationController.screenViewNav = nav
            AnimationController.screenViewTab = tab
            Profile.shotView = true
            let rectNav = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: containerView.frame.width, height: 65.0))
            let rectTabBar = CGRect(origin: CGPoint(x: 0.0, y: containerView.frame.height - 50.0), size: CGSize(width: containerView.frame.width, height: 50.0))
            AnimationController.screenViewNav?.mask(withRect: rectNav)
            AnimationController.screenViewTab?.mask(withRect: rectTabBar)
        }
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.frame = (fromDelegate == nil) ? CGRect.zero : fromDelegate!.imageWindowFrame()
        if cornerRadius { imageView.layer.cornerRadius = 5.0 }
        imageView.clipsToBounds = true
        containerView.addSubview(imageView)
        
        fromDelegate!.tranisitionSetup()
        toDelegate!.tranisitionSetup()
        
        fromSnapshot?.frame = fromVC.view.frame
        containerView.addSubview(fromSnapshot!)
        
        let toSnapshot = toVC.view.snapshotView(afterScreenUpdates: true)
        
        toSnapshot?.frame = fromVC.view.frame
        containerView.addSubview(toSnapshot!)
        toSnapshot?.alpha = 0
        
        if Profile.shotView {
            AnimationController.screenViewNav?.alpha = alphaTabs == "up" ? 1 : 0
      AnimationController.screenViewTab?.alpha = alphaTabs == "up" ? 1 : 0
        containerView.addSubview(AnimationController.screenViewNav!)
        containerView.addSubview(AnimationController.screenViewTab!)
        }
        
        var backView = UIView(frame: CGRect.zero)
        if let frameBackPic = self.frameBackImage {
            backView = UIView(frame: frameBackPic)
            backView.backgroundColor = UIColor.white
            backView.layer.cornerRadius = 5.0
            backView.clipsToBounds = true
            containerView.addSubview(backView)
            backView.alpha = alphaTabs == "up" ? 1 : 0
        }
        
        var avatarImage = UIImageView(frame: CGRect.zero)
        if let frameImage = self.frameImage {
            avatarImage = UIImageView(frame: frameImage)
            avatarImage.image = self.secondImage
            avatarImage.layer.cornerRadius = 5.0
            avatarImage.clipsToBounds = true
            avatarImage.contentMode = .scaleAspectFill
            containerView.addSubview(avatarImage)
            avatarImage.alpha = alphaTabs == "up" ? 1 : 0
        }
        
        containerView.bringSubview(toFront: imageView)
//        containerView.bringSubview(toFront: AnimationController.screenViewNav!)
//        containerView.bringSubview(toFront: AnimationController.screenViewTab!)
        containerView.bringSubview(toFront: backView)
        containerView.bringSubview(toFront: avatarImage)
        containerView.bringSubview(toFront: AnimationController.screenViewNav!)
        containerView.bringSubview(toFront: AnimationController.screenViewTab!)
        
        
        
        let toFrame = (self.toDelegate == nil) ? CGRect.zero : self.toDelegate!.imageWindowFrame()
        let animationDuration = transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseIn, animations: {
            toSnapshot?.alpha = 1
            imageView.frame = toFrame
            if self.alphaTabs == "up" {
                backView.alpha = 0
                avatarImage.alpha = 0
                AnimationController.screenViewNav?.alpha = 0
                AnimationController.screenViewTab?.alpha = 0

            } else if self.alphaTabs == "down" {
                AnimationController.screenViewNav?.alpha = 1
                AnimationController.screenViewTab?.alpha = 1
                backView.alpha = 1
                avatarImage.alpha = 1
               // self.screenViewNav?.alpha = 0
               // nav.alpha = 0
               // self.screenViewTab?.alpha = (self.alphaTabs?.1)!
                //tab.alpha = (self.alphaTabs?.1)!
            } else {
               // self.screenViewNav?.alpha = (self.alphaTabs?.1)!
                //nav.alpha = (self.alphaTabs?.1)!
               // self.screenViewTab?.alpha = (self.alphaTabs?.1)!
                //tab.alpha = (self.alphaTabs?.1)!
            }
        }) { (finished) in
            self.toDelegate!.tranisitionCleanup()
            self.fromDelegate!.tranisitionCleanup()
            imageView.removeFromSuperview()
            fromSnapshot?.removeFromSuperview()
            toSnapshot?.removeFromSuperview()
            AnimationController.screenViewTab?.removeFromSuperview()
            AnimationController.screenViewNav?.removeFromSuperview()
            fromVC.view.removeFromSuperview()
            backView.removeFromSuperview()
            avatarImage.removeFromSuperview()
            
            if !transitionContext.transitionWasCancelled {
                containerView.addSubview(toVC.view)
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}




