//
//  Tweet.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/15/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import Foundation

class Tweet {
    
    var tweetID: String
    var timeStamp: String?
    var retweetCount = 0
    var retweeted: Bool
    var favoriteCount = 0
    var favorited: Bool
    var text: String?
    var urls: [JSON]?
    var media: [JSON]?
    var user: JSON?
    var username: String?
    var userScreenName: String?
    var userAvatar: URL?
    var retweetedName: String?
    var retweetedScreenName: String?
    var retweetTweetID: String?
    var hashtag: [JSON]?
    var userMentions = [String]()
    var retweetBtn = false
    var favoriteBtn = false
    var replyBtn = false
    var quote: Tweet?
    
    
    init(dict: JSON) {
        //print(dict)
        
        self.tweetID = dict["id_str"].string ?? ""
        if let retweetName = dict["user"]["name"].string {
            self.retweetedName = retweetName
        }
        if let retweetScreenName = dict["user"]["screen_name"].string {
            self.retweetedScreenName = retweetScreenName
        }
        self.retweetBtn = dict["retweeted"].bool!
        if dict["retweeted_status"].object != nil {
            self.retweeted = dict["retweeted_status"]["retweeted"].bool ?? false
            self.favorited = dict["retweeted_status"]["favorited"].bool ?? false
            self.retweetTweetID = dict["retweeted_status"]["id_str"].string
            if self.retweetedName == Profile.account.name {
                retweetBtn = true
            }
            tweetParseDetails(some: dict["retweeted_status"])
            //          self.favoriteBtn = (dict["favorited"].bool)!
            //            self.username = dict["user"]?["name"].string
            //            self.userScreenName = dict["user"]?["screen_name"].string
            //            self.userAvatar = URL(string: (dict["user"]?["profile_image_url_https"].string?.replace(target: "_normal", withString: ""))!)
            //            self.urls = dict["entities"]?["urls"].array
            //            self.media = dict["entities"]?["media"].array
            //            self.hashtag = dict["entities"]?["hashtags"].array
            //            if let mention = dict["entities"]?["user_mentions"].array {
            //                if mention.count > 0 {
            //                    for x in mention {
            //                        let texts = "@" + x["screen_name"].string!
            //                        self.userMentions.append(texts)
            //                    }
            //                }
            //            }
            //            let textHTML = dict["text"]?.string
            //            self.text = textHTML?.stringByDecodingXMLEntities()
            //            self.user = dict["user"]
            //            self.retweetCount = dict["retweet_count"]?.integer ?? 0
            //            self.favoriteCount = dict["favorite_count"]?.integer ?? 0
            //
            //            let timeSt = dict["created_at"]?.string
            //            let formatter = DateFormatter()
            //            formatter.dateFormat = "EEE MMM d HH:mm:ss Z y"
            //            let t = formatter.date(from: timeSt!)
            //            formatter.dateFormat = "d.MM.yy, HH:mm"
            //            timeStamp = formatter.string(from: t!)
            //            if let status = dict["is_quote_status"]?.bool, status {
            //                let object = dict["quoted_status"]
            //                quote = Tweet(dict: object!)
            //            }
        } else {
            self.retweeted = dict["retweeted"].bool ?? false
            self.favorited = dict["favorited"].bool ?? false
            tweetParseDetails(some: dict)
            //            self.favoriteBtn = dict["favorited"].bool!
            //            self.retweetBtn = dict["retweeted"].bool!
            //            self.username = dict["user"]["name"].string
            //            self.userScreenName = dict["user"]["screen_name"].string
            //            if let url = dict["user"]["profile_image_url_https"].string {
            //             self.userAvatar = URL(string: url.replace(target: "_normal", withString: ""))
            //            }
            //
            //            if dict["is_quote_status"].bool! {
            //                let object = dict["quoted_status"]
            //                quote = Tweet(dict: object)
            //            }
            //
            //            //self.userAvatar = URL(string: dict["user"]["profile_image_url_https"].string!.replace(target: "_normal", withString: "_bigger"))
            //
            //            self.urls = dict["entities"]["urls"].array
            //            self.media = dict["entities"]["media"].array
            //            self.hashtag = dict["entities"]["hashtags"].array
            //            if let mention = dict["entities"]["user_mentions"].array {
            //                if mention.count > 0 {
            //                    for x in mention {
            //                        let texts = "@" + x["screen_name"].string!
            //                        self.userMentions.append(texts)
            //                    }
            //                }
            //            }
            //            let textHTML = dict["text"].string
            //            self.text = textHTML?.stringByDecodingXMLEntities()
            //            self.user = dict["user"]
            //            self.retweetCount = dict["retweet_count"].integer ?? 0
            //            self.favoriteCount = dict["favorite_count"].integer ?? 0
            //           
            //            
            //            if let timeSt = dict["created_at"].string {
            //                let formatter = DateFormatter()
            //                formatter.dateFormat = "EEE MMM d HH:mm:ss Z y"
            //                let t = formatter.date(from: timeSt)
            //                formatter.dateFormat = "d.MM.yy, HH:mm"
            //                timeStamp = formatter.string(from: t!)
            //            }
        }

//        self.tweetID = dict["id_str"].string ?? ""
//        if let retweetName = dict["user"]["name"].string {
//            self.retweetedName = retweetName
//        }
//        if let retweetScreenName = dict["user"]["screen_name"].string {
//            self.retweetedScreenName = retweetScreenName
//        }
//        self.retweetBtn = (dict["retweeted"].bool)!
//        if dict["retweeted_status"].object != nil {
//            
//            self.retweetTweetID = dict["retweeted_status"]["id_str"].string
//            if self.retweetedName == Profile.account.name {
//                retweetBtn = true
//            }
//            self.favoriteBtn = dict["retweeted_status"]["favorited"].bool!
//            self.username = dict["retweeted_status"]["user"]["name"].string
//            self.userScreenName = dict["retweeted_status"]["user"]["screen_name"].string
//            self.userAvatar = URL(string: (dict["retweeted_status"]["user"]["profile_image_url_https"].string?.replace(target: "_normal", withString: ""))!)
//            self.urls = dict["retweeted_status"]["entities"]["urls"].array
//            self.media = dict["retweeted_status"]["entities"]["media"].array
//            self.hashtag = dict["retweeted_status"]["entities"]["hashtags"].array
//            if let mention = dict["retweeted_status"]["entities"]["user_mentions"].array {
//                if mention.count > 0 {
//                    for x in mention {
//                        let texts = "@" + x["screen_name"].string!
//                        self.userMentions.append(texts)
//                    }
//                }
//            }
//            let textHTML = dict["retweeted_status"]["text"].string
//            self.text = textHTML?.stringByDecodingXMLEntities()
//            self._user = dict["retweeted_status"]["user"]
//            self.retweetCount = dict["retweeted_status"]["retweet_count"].integer ?? 0
//            self.favoriteCount = dict["retweeted_status"]["favorite_count"].integer ?? 0
//            self.retweeted = dict["retweeted_status"]["retweeted"].bool ?? false
//            self.favorited = dict["retweeted_status"]["favorited"].bool ?? false
//            
//            let timeSt = dict["retweeted_status"]["created_at"].string
//            let formatter = DateFormatter()
//            formatter.dateFormat = "EEE MMM d HH:mm:ss Z y"
//            let t = formatter.date(from: timeSt!)
//            formatter.dateFormat = "d.MM.yy, HH:mm"
//            timeStamp = formatter.string(from: t!)
//            
//            if let status = dict["retweeted_status"]["is_quote_status"].bool, status {
//                let object = dict["retweeted_status"]["quoted_status"]
//                quote = Tweet(dict: object)
//            }
//        } else {
//            // self.tweetID = dict["id_str"].string
//            self.favoriteBtn = dict["favorited"].bool!
//            self.retweetBtn = dict["retweeted"].bool!
//            self.username = dict["user"]["name"].string
//            self.userScreenName = dict["user"]["screen_name"].string
//            if let url = dict["user"]["profile_image_url_https"].string {
//                self.userAvatar = URL(string: url.replace(target: "_normal", withString: ""))
//            }
//            
//            if dict["is_quote_status"].bool! {
//                let object = dict["quoted_status"]
//                quote = Tweet(dict: object)
//            }
//            
//            
//            self.urls = dict["entities"]["urls"].array
//            self.media = dict["entities"]["media"].array
//            self.hashtag = dict["entities"]["hashtags"].array
//            if let mention = dict["entities"]["user_mentions"].array {
//                if mention.count > 0 {
//                    for x in mention {
//                        let texts = "@" + x["screen_name"].string!
//                        self.userMentions.append(texts)
//                    }
//                }
//            }
//            let textHTML = dict["text"].string
//            self.text = textHTML?.stringByDecodingXMLEntities()
//            self._user = dict["user"]
//            self.retweetCount = dict["retweet_count"].integer ?? 0
//            self.favoriteCount = dict["favorite_count"].integer ?? 0
//            self.retweeted = dict["retweeted"].bool ?? false
//            self.favorited = dict["favorited"].bool ?? false
//            
//            let timeSt = dict["created_at"].string!
//            let formatter = DateFormatter()
//            formatter.dateFormat = "EEE MMM d HH:mm:ss Z y"
//            let t = formatter.date(from: timeSt)
//            formatter.dateFormat = "d.MM.yy, HH:mm"
//            timeStamp = formatter.string(from: t!)
//        }
    }
    private func tweetParseDetails(some: JSON) {
        
        self.favoriteBtn = some["favorited"].bool!
        self.username = some["user"]["name"].string
        self.userScreenName = some["user"]["screen_name"].string
        self.userAvatar = URL(string: (some["user"]["profile_image_url_https"].string?.replace(target: "_normal", withString: ""))!)
        self.urls = some["entities"]["urls"].array
        self.media = some["entities"]["media"].array
        self.hashtag = some["entities"]["hashtags"].array
        if let mention = some["entities"]["user_mentions"].array {
            if mention.count > 0 {
                for x in mention {
                    let texts = "@" + x["screen_name"].string!
                    self.userMentions.append(texts)
                }
            }
        }
        let textHTML = some["text"].string
        self.text = textHTML?.stringByDecodingXMLEntities()
        self.user = some["user"]
        self.retweetCount = some["retweet_count"].integer ?? 0
        self.favoriteCount = some["favorite_count"].integer ?? 0
        
        let timeSt = some["created_at"].string
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d HH:mm:ss Z y"
        let t = formatter.date(from: timeSt!)
        formatter.dateFormat = "d.MM.yy, HH:mm"
        timeStamp = formatter.string(from: t!)
        if let status = some["is_quote_status"].bool, status {  // do something:)
            if some["quoted_status"].object != nil {
                quote = Tweet(dict: some["quoted_status"])
            }
        
    }
    }
}
