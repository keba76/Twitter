//
//  FollowersAndFollowingCell.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/18/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift

class EmptyCell: UITableViewCell {}

class LockCell: UITableViewCell {}

class FollowersAndFollowingCell: UITableViewCell {
    
    @IBOutlet weak var userPic: UIImageView!
    @IBOutlet weak var userPicBack: UIView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var followersCount: UILabel!
    @IBOutlet weak var followingCount: UILabel!
    @IBOutlet weak var settingsBtn: UIButton!
    
    var dis = DisposeBag()
    override func prepareForReuse() { dis = DisposeBag() }
    
    var user: ModelUser! {
        didSet { userSetConfigure() }
    }
    
    func userSetConfigure() {
        
        user.userPicImage.asObservable().observeOn(MainScheduler.instance).bind(to: userPic.rx.image).disposed(by: self.dis)
        
        userPic.layer.cornerRadius = 5
        userPic.clipsToBounds = true
        userPic.layer.borderColor = UIColor.darkGray.cgColor
        userPic.layer.borderWidth = 0.5
        
        userName.text = user.name
        followersCount.text = user.followers
        followingCount.text = user.following
        
        settingsBtn.rx.tap.asObservable().subscribe(onNext: { [weak self] _ in
            guard let s = self else { return }
            s.user?.userData.value = UserData.TapSettingsBtn(user: s.user!, modal: true, showMute: false, publicReply: false, mute: false, follow: false)
        }).disposed(by: self.dis)
}
}
