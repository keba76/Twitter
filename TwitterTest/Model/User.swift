//
//  User.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/24/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import SDWebImage

class User {
    
    let id: String?
    var imageBanner: URL?
    var avatar: URL?
    var name: String?
    var screenName: String?
    var location: String?
    var folowers: String?
    var following: String?
    var description: String?
    var entities: [String: JSON]?
    var protected = false
    var followYou = false
    
    
    init(dict: JSON = nil) {
        //print(dict)
        self.id = dict["id_str"].string
        let screen = dict["profile_banner_url"].string?.appending("/mobile_retina")
        if screen != nil {
            self.imageBanner = URL(string: screen!)
        } else {
            if let banner = dict["profile_background_image_url"].string {
                self.imageBanner = URL(string: banner)
            }
        }
        if let avatar = dict["profile_image_url_https"].string {
            self.avatar = URL(string: avatar.replace(target: "_normal", withString: ""))
        }
        self.name = dict["name"].string
        self.screenName = dict["screen_name"].string
        if let lock = dict["protected"].bool {
            self.protected = lock
        }
        
        self.location = dict["location"].string
        self.description = dict["description"].string
        self.entities = dict["entities"].object
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        self.folowers = formatter.string(for: dict["followers_count"].integer)
        self.following = formatter.string(for: dict["friends_count"].integer)
    }
}
