//
//  ModelTweet.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 4/21/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import Foundation
import RxSwift
import Kanna

class ModelTweet {
    let text: NSMutableAttributedString
    var dictUrlsForSafari = Dictionary<String, String>()
    var dictUrlsTap = Dictionary<String, NSRange>()
    let retweetedType: String
    let tweetID: String
    let lastTweetID: String
    let userName: String
    let userScreenName: String
    var replyBtn: Bool
    var settingsBtn: Bool
    let retweetBtn: Bool
    let favoriteBtn: Bool
    var retweetCount: Int
    var retweeted: Bool
    var favoriteCount: Int
    var favorited: Bool
    var user: User
    var mediaImageURLs: [URL]?
    var youtubeURL: URL?
    var videoURL: URL?
    var instagramVideo: URL?
    var quote: ModelTweet?
    var retweetedName: String
    var retweetTweetID: String?
    var userAvatar: URL
    var timeStamp: String
    var retweetedScreenName: String
    var userMentions = [String]()
    var via: String
    var followingStatus: Bool
    var replyConversation: String
    
    init(parse: Tweet) {
        
        tweetID = parse.tweetID
        lastTweetID = parse.lastTweetID
        userName = parse.username!
        userScreenName = "@" + parse.userScreenName!
        replyBtn = parse.replyBtn
        settingsBtn = parse.settingsBtn
        retweetBtn = parse.retweetBtn
        favoriteBtn = parse.favoriteBtn
        retweetCount = parse.retweetCount
        retweeted = parse.retweeted
        favoriteCount = parse.favoriteCount
        favorited = parse.favorited
        user = User(dict: parse.user!)
        retweetedName = parse.retweetedName!
        retweetTweetID = parse.retweetTweetID
        userAvatar = parse.userAvatar!
        timeStamp = parse.timeStamp!
        retweetedScreenName = parse.retweetedScreenName!
        userMentions = parse.userMentions
        followingStatus = parse.followingStatus
        replyConversation = parse.replyConversation
        if parse.quote != nil {
            quote = ModelTweet(parse: parse.quote!)
            let text = quote!.text
            let attribute = NSMutableAttributedString(attributedString: text)
            attribute.beginEditing()
            attribute.enumerateAttribute(NSAttributedString.Key(rawValue: convertFromNSAttributedStringKey(NSAttributedString.Key.font)), in: NSRange(location: 0, length: text.length), using: { (value, range, stop) in
                if let oldFont = value as? UIFont {
                    let newFont = oldFont.withSize(12.5)
                    attribute.removeAttribute(NSAttributedString.Key.font, range: range)
                    attribute.addAttribute(NSAttributedString.Key.font, value: newFont, range: range)
                }
            })
            attribute.endEditing()
            quote!.text = attribute
        }
        
        var tempVia = parse.via!
        if !tempVia.isEmpty {
            tempVia.removeFirst(1)
            let rangeStart = tempVia.indexOf(">")
            let rangeEnd = tempVia.indexOf("<")
            via = tempVia.substringBetween(from: rangeStart, to: rangeEnd)
        } else {
            via = "Hadron Collider"
        }
        if let extendedMedia = parse.extendedMedia {
            for json in extendedMedia {
                if json["type"].string == "video" || json["type"].string == "animated_gif" {
                    let urlArrayVideo = json["video_info"]["variants"].array
                    if let urlVideo = urlArrayVideo?.first?["url"].string {
                        self.videoURL = URL(string: urlVideo)
                    }
                }
            }
        }
        
        // TEXTATTRIBUTED
        var displayURL = [String]()
        var textParse = parse.text!
        textParse = textParse.replace(target: "\n\n", withString: "\n")
        if let urls = parse.urls, urls.count > 0 {
            for json in urls {
                let urlText = json["url"].string
                textParse = textParse.replace(target: urlText!, withString: "")
                let displayURLs = json["display_url"].string!
                let urlExpanded = json["expanded_url"].string!
                if urlExpanded.contains("instagram.com") {
                    if let doc = try? HTML(url: URL(string: urlExpanded)! , encoding: .utf8) {
                        if let image = doc.at_xpath("//meta[@property='og:image']/@content") {
                            mediaImageURLs = [URL]()
                            mediaImageURLs?.append(URL(string: image.text!)!)
                        }
                        if let video = doc.at_xpath("//meta[@property='og:video']/@content") {
                            self.instagramVideo = URL(string: video.text!)
                        }
                    }
                }
                if urlExpanded.contains("youtube") {
                    let rangeStart = urlExpanded.indexOf("=")
                    let rangeEnd = urlExpanded.indexOf("&")
                    let youtubeURLpart = urlExpanded.substringBetween(from: rangeStart, to: rangeEnd)
                    let youtubeURLString = "https://img.youtube.com/vi/\(youtubeURLpart)/hqdefault.jpg"
                    youtubeURL = URL(string: urlExpanded)
                    mediaImageURLs = [URL]()
                    mediaImageURLs?.append(URL(string: youtubeURLString)!)
                    self.videoURL = youtubeURL
                }
                dictUrlsForSafari[displayURLs] = urlExpanded
                displayURL.append(displayURLs)
            }
        }
        if let media = parse.media {
            mediaImageURLs = [URL]()
            for json in media {
                let urlText = json["url"].string
                textParse = textParse.replace(target: urlText!, withString: "")
                if json["type"].string == "photo" {
                    let mediaURL = json["media_url_https"].string
                    mediaImageURLs?.append(URL(string: mediaURL!)!)
                }
            }
        }
        textParse = textParse.replace(target: "\n\n", withString: "\n")
        textParse = textParse.trimmingCharacters(in: .whitespacesAndNewlines)
        text = NSMutableAttributedString(string: textParse)
        text.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.regular), range: NSRange(location: 0, length: text.length))
        
        if displayURL.count > 0 {
            let urlText = " " + displayURL.joined(separator: " ")
            if parse.userMentions.count > 0 {
                for texts in parse.userMentions {
                    let range = text.mutableString.range(of: texts, options: [.caseInsensitive])
                    let prefix = NSMutableAttributedString(string: texts, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font) : UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.bold), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor) : UIColor(red: 25/255.0, green: 109/255.0, blue: 161/255.0, alpha: 1)]))
                    text.replaceCharacters(in: range, with: prefix)
                }
            }
            if let hash = parse.hashtag, (parse.hashtag?.count)! > 0 {
                for json in hash {
                    let texts = "#" + json["text"].string!
                    let hashString = NSMutableAttributedString(string: texts, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font) : UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.regular), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor) : UIColor.gray]))
                    let range = text.mutableString.range(of: texts)
                    text.replaceCharacters(in: range, with: hashString)
                }
            }
            let links = NSMutableAttributedString(string: urlText)
            links.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.regular), range: NSRange(location: 0, length: links.length))
            links.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(red: 36/255.0, green: 144/255.0, blue: 212/255.0, alpha: 1), range: NSRange(location: 0, length: links.length))
            text.append(links)
            for url in displayURL {
                let rangeNSString = text.mutableString.range(of: url)
                dictUrlsTap[url] = rangeNSString
                
            }
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 1.5
            let font = UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.regular)
            style.lineHeightMultiple = 1.0
            style.minimumLineHeight = font.lineHeight
            style.maximumLineHeight = font.lineHeight
            style.lineBreakMode = NSLineBreakMode.byWordWrapping
            text.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: text.length))
            
        } else if let hash = parse.hashtag, (parse.hashtag?.count)! > 0 {
            for json in hash {
                let texts = "#" + json["text"].string!
                let hashString = NSMutableAttributedString(string: texts, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font) : UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.regular), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor) : UIColor.gray]))
                let range = text.mutableString.range(of: texts)
                text.replaceCharacters(in: range, with: hashString)
            }
            if parse.userMentions.count > 0 {
                for texts in parse.userMentions {
                    let range = text.mutableString.range(of: texts, options: [.caseInsensitive])
                    let prefix = NSMutableAttributedString(string: texts, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font) : UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.bold), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor) : UIColor(red: 25/255.0, green: 109/255.0, blue: 161/255.0, alpha: 1)]))
                    text.replaceCharacters(in: range, with: prefix)
                }
            }
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 1.5
            let font = UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.regular)
            style.lineHeightMultiple = 1.0
            style.minimumLineHeight = font.lineHeight
            style.maximumLineHeight = font.lineHeight
            style.lineBreakMode = NSLineBreakMode.byWordWrapping
            text.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: text.length))
        } else if parse.userMentions.count > 0 {
            for texts in parse.userMentions {
                let range = text.mutableString.range(of: texts, options: [.caseInsensitive])
                let prefix = NSMutableAttributedString(string: texts, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font) : UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.bold), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor) : UIColor(red: 25/255.0, green: 109/255.0, blue: 161/255.0, alpha: 1)]))
                text.replaceCharacters(in: range, with: prefix)
            }
            let style = NSMutableParagraphStyle()
            let font = UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.regular)
            style.lineHeightMultiple = 1.0
            style.minimumLineHeight = font.lineHeight
            style.maximumLineHeight = font.lineHeight
            style.lineSpacing = 1.5
            style.lineBreakMode = NSLineBreakMode.byWordWrapping
            text.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: text.length))
        } else {
            let style = NSMutableParagraphStyle()
            let font = UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.regular)
            style.lineHeightMultiple = 1.0
            style.minimumLineHeight = font.lineHeight
            style.maximumLineHeight = font.lineHeight
            style.lineSpacing = 1.5
            style.lineBreakMode = NSLineBreakMode.byWordWrapping
            text.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: text.length))
        }
        
        if parse.retweetTweetID != nil, parse.retweetBtn, parse.retweetedName != Profile.account.name{
            retweetedType = "Retweeted by \(parse.retweetedName!) and You"
        } else if parse.retweetTweetID != nil {
            
            retweetedType = parse.retweetedName == Profile.account.name ? "Retweeted by You" : "Retweeted by \(parse.retweetedName!)"
        } else if parse.retweetBtn {
            retweetedType = "Retweeted by You"
        } else {
            retweetedType = ""
        }
    }
}

class ModelUser {
    let id: String
    var imageBanner: URL?
    var avatar: URL?
    var name: String
    var screenName: String
    var screenNameAt: String
    var location: String
    var followers: String
    var following: String
    var description: String
    var entitiesDescription: [JSON]?
    var protected: Bool
    var followYou: Bool
    var userPicImage: BehaviorSubject<UIImage>
    var userData: Variable<UserData>
    
    init() { id = ""; name = ""; screenName = ""; screenNameAt = ""; location = ""; followers = ""; following = ""; description = ""; protected = false; followYou = false; userPicImage = BehaviorSubject<UIImage>(value: UIImage.getEmptyImageWithColor(color: UIColor.white)); userData =  Variable<UserData>(UserData.tempValue(action: false))}
    
    init(parse: User) {
        id = parse.id!
        imageBanner = parse.imageBanner
        avatar = parse.avatar!
        name = parse.name!
        screenName = parse.screenName!
        screenNameAt = "@\(screenName)"
        location = parse.location!
        followers = parse.folowers!
        following = parse.following!
        description = parse.description!
        protected = parse.protected
        followYou = parse.followYou
        entitiesDescription = (parse.entities?["description"]?["urls"].array)!
        userData = Variable<UserData>(UserData.tempValue(action: false))
        userPicImage = BehaviorSubject<UIImage>(value: UIImage.getEmptyImageWithColor(color: UIColor.white))
    }
    
}
extension ModelUser: Equatable {
    public static func ==(lhs: ModelUser, rhs: ModelUser) -> Bool {
        return lhs.id == rhs.id
    }
}

enum UserData: Equatable {
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func ==(lhs: UserData, rhs: UserData) -> Bool {
        switch (lhs, rhs) {
        case (let .tempValue(action1), let .tempValue(action2)):
            return action1 == action2
            
        case (let .TapSettingsBtn(user1, modal1, showMute1, publicReply1, mute1, follow1), let .TapSettingsBtn(user2, modal2, showMute2, publicReply2, mute2, follow2)):
            return user1 == user2 && modal1 == modal2 && showMute1 == showMute2 && publicReply1 == publicReply2 && mute1 == mute2 && follow1 == follow2
        default:
            return false
        }
    }
    
    case tempValue(action: Bool)
    case TapSettingsBtn(user: ModelUser, modal: Bool, showMute: Bool, publicReply: Bool, mute: Bool, follow: Bool)
    case ImageUserScale(data: SomeTweetsData)
    case ImageBannerScale(data: SomeTweetsData)
}




// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
