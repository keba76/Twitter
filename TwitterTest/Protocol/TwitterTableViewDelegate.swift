//
//  MediaTableViewDelegate.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/17/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit

protocol TwitterTableViewDelegate: UITableViewDelegate {
    func profileVC(tweet: ViewModelTweet?, someTweetsData: SomeTweetsData?)
}
extension TwitterTableViewDelegate {
    
    func extensionProfVC(tweet: ViewModelTweet? = nil, someTweetsData: SomeTweetsData? = nil) {
        
        profileVC(tweet: tweet, someTweetsData: someTweetsData)
    }
}


