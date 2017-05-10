//
//  ProfileLeftVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/25/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ProfileLeftVC: UIViewController, UIViewControllerTransitioningDelegate {
    
    // @IBOutlet weak var userName: UILabel!
    // @IBOutlet weak var userScreenName: UILabel!
    @IBOutlet weak var followingCountLbl: UILabel!
    @IBOutlet weak var followersCountLbl: UILabel!
    @IBOutlet weak var connection: InsetLabel!
    @IBOutlet weak var location: UILabel!
    
    @IBOutlet weak var followersBtn: UIButton!
    @IBOutlet weak var followingBtn: UIButton!
    
    var user = ModelUser()
    
    var dis = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        followersBtn.rx.controlEvent(UIControlEvents.touchDown).subscribe(onNext: { [weak self] _ in
            self?.followersBtn.setImage(UIImage(named: "followersPushBtn"), for: .highlighted)
        }).addDisposableTo(dis)
        followingBtn.rx.controlEvent(UIControlEvents.touchDown).subscribe(onNext: { [weak self] _ in
            self?.followingBtn.setImage(UIImage(named: "followingPushBtn"), for: .highlighted)
        }).addDisposableTo(dis)
        
        self.stuffingViews(data: Profile.arrayIdFollowers)
    }
    
    private func stuffingViews(data: [JSON]) {
        if !Profile.arrayIdFollowers.isEmpty, Profile.arrayIdFollowers.contains(where: {$0.integer == Int(user.id)}) {
            self.connection.text = "follows you"
            self.connection.backgroundColor = UIColor(red: 33/255, green: 150/255, blue: 243/255, alpha: 1)
            self.user.followYou = true
        } else {
            self.connection.text = "does not follow you"
            self.connection.backgroundColor = UIColor(red: 190/255, green: 190/255, blue: 190/255, alpha: 1)
        }
        if Profile.account.id == user.id {
            self.connection.isHidden = true
        }
        
        self.followingCountLbl.text = user.following
        self.followersCountLbl.text = user.followers
        self.location.text = user.location != "" ? user.location : "somewere in space..."
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "followers" {
            if let controller = segue.destination as? FollowersAndFollowingVC {
                controller.user = user
                controller.typeUser = "Followers"
            } 
        } else {
            if segue.identifier == "following" {
                if let controller = segue.destination as? FollowersAndFollowingVC {
                    controller.user = user
                    controller.typeUser = "Following"
                }
            }
        }
    }
    
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return LeftTransition()
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let leftTransiton = LeftTransition()
        leftTransiton.dismiss = true
        return leftTransiton
    }
}

class InsetLabel: UILabel {
    let topInset = CGFloat(0)
    let bottomInset = CGFloat(0)
    let leftInset = CGFloat(10)
    let rightInset = CGFloat(10)
    
    override func drawText(in rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override public var intrinsicContentSize: CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize
        intrinsicSuperViewContentSize.height += topInset + bottomInset
        intrinsicSuperViewContentSize.width += leftInset + rightInset
        return intrinsicSuperViewContentSize
    }
}

class LeftTransition: NSObject ,UIViewControllerAnimatedTransitioning {
    var dismiss = false
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning){
        // Get the two view controllers
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let containerView = transitionContext.containerView
        
        
        var originRect = containerView.bounds
        originRect.origin = CGPoint(x: originRect.width, y: 0)
        
        let view = UIView(frame: fromVC.view.frame)
        view.backgroundColor = UIColor(red: 214/255, green: 214/255, blue: 214/255, alpha: 1)
        view.alpha = dismiss ? 1 : 0
        
        containerView.addSubview(fromVC.view)
        containerView.addSubview(view)
        containerView.addSubview(toVC.view)
        
        
        if dismiss{
            containerView.bringSubview(toFront: view)
            containerView.bringSubview(toFront: fromVC.view)
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { () -> Void in
                fromVC.view.frame = originRect
                view.alpha = 0
            }, completion: { (_ ) -> Void in
                fromVC.view.removeFromSuperview()
                view.removeFromSuperview()
                transitionContext.completeTransition(true )
            })
        }else{
            toVC.view.frame = originRect
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           animations: { () -> Void in
                            view.alpha = 1
                            toVC.view.center = containerView.center
                            
            }) { (_) -> Void in
                fromVC.view.removeFromSuperview()
                view.removeFromSuperview()
                transitionContext.completeTransition(true )
            }
        }
    }
}



