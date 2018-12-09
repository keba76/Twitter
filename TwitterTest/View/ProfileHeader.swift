//
//  ProfileHeader.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/25/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift
import SDWebImage

class ProfileHeader: UIView {
    
    let dis = DisposeBag()
    
    var images: UIImage?
    var imageBanner: UIImage?
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileImageSuperView: UIView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var settingsBtn: UIButton!
    
    var user: ModelUser? {
        didSet {
            profileSetConfigure()
        }
    }
    
    func profileSetConfigure() {
        
        settingsBtn.rx.controlEvent(UIControl.Event.touchDown).subscribe(onNext: { [weak self] _ in
            self?.settingsBtn.setImage(UIImage(named: "settingsPushBtn"), for: .highlighted)
        }).disposed(by: self.dis)
        self.profileImageView.layer.cornerRadius = 5.0
        self.profileImageView.clipsToBounds = true
        self.profileImageSuperView.layer.cornerRadius = 5.0
        self.name.text = user?.name
        self.userName.text = "@" + (user?.screenName)!
        
        if user?.imageBanner == nil {
            self.backgroundImage.image = UIImage.getEmptyImageWithColor(color: UIColor(red: 3/255, green: 169/255, blue: 244/255, alpha: 1))
        } else {
            SDWebImageManager.shared().loadImage(with: user?.imageBanner, options: .continueInBackground, progress: { (_ , _, _) in
                self.backgroundImage.image = nil
            }, completed: { (image, error, cache, _ , _, _) in
                DispatchQueue.main.async {
                    self.backgroundImage.image = image
                    self.imageBanner = image
                }
            })
        }
        
        SDWebImageManager.shared().loadImage(with: user?.avatar, progress: { (_ , _, _) in
        }) { (image, error, cache , _ , _, _) in
            
            if image == nil {
                let urlString = self.user?.avatar?.absoluteString
                if let url = urlString, url.contains("profile_images") {
                    let newUrl = url.replace(target: ".jpg", withString: "_bigger.jpg")
                    SDWebImageManager.shared().loadImage(with: URL(string: newUrl), progress: { (_ , _, _) in
                    }) { (image, error, cache , _ , _, _) in
                        DispatchQueue.main.async {
                        self.profileImageView.image = image
                        self.images = image
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                self.profileImageView.image = image
                self.images = image
                }
            }
        }
        
        settingsBtn.rx.tap.asObservable().subscribe(onNext: { [weak self] _ in
            guard let s = self else { return }
            s.user?.userData.value = UserData.TapSettingsBtn(user: s.user!, modal: true, showMute: false, publicReply: false, mute: false, follow: false)
        }).disposed(by: self.dis)
        
        let tapUserPic = UITapGestureRecognizer()
        tapUserPic.rx.event.subscribe(onNext: {[weak self] _ in
            guard let s = self else { return }
            let intrinsicImage = s.convert(s.profileImageView.frame, to: s)
            let intrinsicBackView = s.backgroundImage.convert(s.profileImageSuperView.frame, to: s.backgroundImage)
            let backgroundImageFrame = s.convert(s.backgroundImage.frame, to: s)
            let offset = s.convert(s.backgroundImage.frame, to: s.superview?.superview)
            let finalFrame = CGRect(
                x: intrinsicImage.origin.x + intrinsicBackView.origin.x,
                y: backgroundImageFrame.size.height + (intrinsicImage.origin.y + intrinsicBackView.origin.y) + offset.origin.y,
                width: intrinsicImage.size.width,
                height: intrinsicImage.size.height)
            
            s.user?.userData.value = UserData.ImageUserScale(data: SomeTweetsData(convert: finalFrame))
            
        }).disposed(by: self.dis)
        self.profileImageView.isUserInteractionEnabled = true
        self.profileImageView.addGestureRecognizer(tapUserPic)
        
        let tapBackgroundImage = UITapGestureRecognizer()
        tapBackgroundImage.rx.event.subscribe(onNext: {[weak self] _ in
            guard let s = self else { return }
            let intrinsicImage = s.convert(s.profileImageView.frame, to: s)
            let intrinsicBackView = s.backgroundImage.convert(s.profileImageSuperView.frame, to: s.backgroundImage)
            let backgroundImageFrame = s.convert(s.backgroundImage.frame, to: s)
            let offset = s.convert(s.backgroundImage.frame, to: s.superview?.superview)
            let finalFrameBanner = CGRect(
                x: backgroundImageFrame.origin.x,
                y: backgroundImageFrame.origin.y + offset.origin.y,
                width: backgroundImageFrame.size.width,
                height: backgroundImageFrame.size.height)
            let finalFrameImage = CGRect(
                x: intrinsicImage.origin.x + intrinsicBackView.origin.x,
                y: backgroundImageFrame.size.height + (intrinsicImage.origin.y + intrinsicBackView.origin.y) + offset.origin.y,
                width: intrinsicImage.size.width,
                height: intrinsicImage.size.height)
            let finalFrameBackImage = CGRect(
                x: intrinsicBackView.origin.x,
                y: backgroundImageFrame.size.height + intrinsicBackView.origin.y + offset.origin.y,
                width: intrinsicBackView.size.width,
                height: intrinsicBackView.size.height)
            
            s.user?.userData.value = UserData.ImageBannerScale(data: SomeTweetsData(convert: finalFrameBanner, frameImage: finalFrameImage, frameBackImage: finalFrameBackImage))
            
        }).disposed(by: self.dis)
        self.backgroundImage.isUserInteractionEnabled = true
        self.backgroundImage.addGestureRecognizer(tapBackgroundImage)
    }
}
