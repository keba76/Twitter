//
//  MediaTableViewDelegate.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/17/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit

protocol TwitterTableViewDelegate: UITableViewDelegate {
    func profileVC(tweet: ViewModelTweet?, user: ModelUser?, users: ModelUser?, someTweetsData: SomeTweetsData?, settings: Bool, scaleAvatarImage: Bool)
}
extension TwitterTableViewDelegate {
    
    func extensionProfVC(tweet: ViewModelTweet? = nil, user: ModelUser? = nil, users: ModelUser? = nil, someTweetsData: SomeTweetsData? = nil, settings: Bool = false, scaleAvatarImage: Bool = false) {
        
        profileVC(tweet: tweet, user: user, users: users, someTweetsData: someTweetsData, settings: settings, scaleAvatarImage: scaleAvatarImage)
    }
}


