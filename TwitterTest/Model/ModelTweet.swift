//
//  ModelTweet.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 4/21/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import Foundation
import RxSwift

class ModelTweet {
    let text: NSMutableAttributedString
    var dictUrlsForSafari = Dictionary<String, String>()
    var dictUrlsTap = Dictionary<String, NSRange>()
    let retweetedType: String
    let tweetID: String
    let userName: String
    let userScreenName: String
    var replyBtn: Bool
    let retweetBtn: Bool
    let favoriteBtn: Bool
    var retweetCount: Int
    var retweeted: Bool
    //var retweeted: Bool
    var favoriteCount: Int
    var favorited: Bool
    var user: User
    var mediaImageURLs: [URL]?
    var quote: ModelTweet?
    var retweetedName: String
    var retweetTweetID: String?
    var userAvatar: URL
    var timeStamp: String
    var retweetedScreenName: String
    var userMentions = [String]()
    
    init(parse: Tweet) {
        
        tweetID = parse.tweetID
        userName = parse.username!
        userScreenName = "@" + parse.userScreenName!
        replyBtn = parse.replyBtn
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
        if parse.quote != nil { quote = ModelTweet(parse: parse.quote!)}
       
        
        
        
        
        
        
        
        
        // TEXTATTRIBUTED
        var displayURL = [String]()
        var textParse = parse.text!
        
        if let urls = parse.urls, urls.count > 0 {
            for json in urls {
                let urlText = json["url"].string
                textParse = textParse.replace(target: urlText!, withString: "")
                let displayURLs = json["display_url"].string!
                let urlExpanded = json["expanded_url"].string!
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
        
        if displayURL.count > 0 {
            let urlText = " " + displayURL.joined(separator: " ")
            text = NSMutableAttributedString(string: textParse)
            
            text.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular), range: NSRange(location: 0, length: textParse.characters.count))
            if parse.userMentions.count > 0 {
                for texts in parse.userMentions {
                    let range = text.mutableString.range(of: texts, options: [.caseInsensitive])
                    let prefix = NSMutableAttributedString(string: texts, attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightBold), NSForegroundColorAttributeName : UIColor(red: 25/255.0, green: 109/255.0, blue: 161/255.0, alpha: 1)])
                    text.replaceCharacters(in: range, with: prefix)
                }
            }
            if let hash = parse.hashtag, (parse.hashtag?.count)! > 0 {
                for json in hash {
                    let texts = "#" + json["text"].string!
                    let hashString = NSMutableAttributedString(string: texts, attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular), NSForegroundColorAttributeName : UIColor.gray])
                    let range = text.mutableString.range(of: texts)
                    text.replaceCharacters(in: range, with: hashString)
                }
            }
            let links = NSMutableAttributedString(string: urlText)
            links.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular), range: NSRange(location: 0, length: urlText.characters.count))
            links.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 36/255.0, green: 144/255.0, blue: 212/255.0, alpha: 1), range: NSRange(location: 0, length: urlText.characters.count))
            text.append(links)
            for url in displayURL {
                let rangeNSString = text.mutableString.range(of: url)
                dictUrlsTap[url] = rangeNSString
                
            }
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 1.5
            let font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular)
            style.lineHeightMultiple = 1.0
            style.minimumLineHeight = font.lineHeight
            style.maximumLineHeight = font.lineHeight
            style.lineBreakMode = NSLineBreakMode.byWordWrapping
            text.addAttribute(NSParagraphStyleAttributeName, value: style, range: NSRange(location: 0, length: text.string.characters.count))
            
        } else if let hash = parse.hashtag, (parse.hashtag?.count)! > 0 {
            
            text = NSMutableAttributedString(string: textParse)
            
            text.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular), range: NSRange(location: 0, length: textParse.characters.count))
            for json in hash {
                let texts = "#" + json["text"].string!
                let hashString = NSMutableAttributedString(string: texts, attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular), NSForegroundColorAttributeName : UIColor.gray])
                let range = text.mutableString.range(of: texts)
                text.replaceCharacters(in: range, with: hashString)
            }
            
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 1.5
            let font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular)
            style.lineHeightMultiple = 1.0
            style.minimumLineHeight = font.lineHeight
            style.maximumLineHeight = font.lineHeight
            style.lineBreakMode = NSLineBreakMode.byWordWrapping
            text.addAttribute(NSParagraphStyleAttributeName, value: style, range: NSRange(location: 0, length: text.string.characters.count))
            
            if parse.userMentions.count > 0 {
                for texts in parse.userMentions {
                    let range = text.mutableString.range(of: texts, options: [.caseInsensitive])
                    let prefix = NSMutableAttributedString(string: texts, attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightBold), NSForegroundColorAttributeName : UIColor(red: 25/255.0, green: 109/255.0, blue: 161/255.0, alpha: 1)])
                    text.replaceCharacters(in: range, with: prefix)
                }
            }
        } else if parse.userMentions.count > 0 {
            
            text = NSMutableAttributedString(string: textParse)
            
            text.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular), range: NSRange(location: 0, length: textParse.characters.count))
            
            let style = NSMutableParagraphStyle()
            let font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular)
            style.lineHeightMultiple = 1.0
            style.minimumLineHeight = font.lineHeight
            style.maximumLineHeight = font.lineHeight
            style.lineSpacing = 1.5
            style.lineBreakMode = NSLineBreakMode.byWordWrapping
            text.addAttribute(NSParagraphStyleAttributeName, value: style, range: NSRange(location: 0, length: text.string.characters.count))
            for texts in parse.userMentions {
                let range = text.mutableString.range(of: texts, options: [.caseInsensitive])
                let prefix = NSMutableAttributedString(string: texts, attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightBold), NSForegroundColorAttributeName : UIColor(red: 25/255.0, green: 109/255.0, blue: 161/255.0, alpha: 1)])
                text.replaceCharacters(in: range, with: prefix)
            }
        } else {
            
            text = NSMutableAttributedString(string: textParse)
            
            text.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular), range: NSRange(location: 0, length: textParse.characters.count))
            
            let style = NSMutableParagraphStyle()
            let font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular)
            style.lineHeightMultiple = 1.0
            style.minimumLineHeight = font.lineHeight
            style.maximumLineHeight = font.lineHeight
            style.lineSpacing = 1.5
            style.lineBreakMode = NSLineBreakMode.byWordWrapping
            text.addAttribute(NSParagraphStyleAttributeName, value: style, range: NSRange(location: 0, length: text.string.characters.count))
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
    var location: String
    var followers: String
    var following: String
    var description: String
    var entitiesDescription: [JSON]?
    var protected: Bool
    var followYou: Bool
    var userData: Variable<UserData>
    
    init() { id = ""; name = ""; screenName = ""; location = ""; followers = ""; following = ""; description = ""; protected = false; followYou = false; userData =  Variable<UserData>(UserData.tempValue(action: false))}
    
    init(parse: User) {
        id = parse.id!
        imageBanner = parse.imageBanner
        avatar = parse.avatar!
        name = parse.name!
        screenName = parse.screenName!
        location = parse.location!
        followers = parse.folowers!
        following = parse.following!
        description = parse.description!
        protected = parse.protected
        followYou = parse.followYou
        entitiesDescription = (parse.entities?["description"]?["urls"].array)!
        userData = Variable<UserData>(UserData.tempValue(action: false))
        
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

//class CustomQuoteView: UIView {
//    
//    var view: UIView
//    var quoteNameLbl: UILabel
//    var quoteNickLbl: UILabel
//    var quoteImage: UIImageView?
//    var quoteTextLbl: UILabel
//    
////    override init(frame: CGRect) {
////        super.init(frame: frame)
////    }
//    
//    init(quote: ModelTweet) {
//        view = UIView()
//        view.backgroundColor = UIColor(red: 245/257, green: 245/257, blue: 245/257, alpha: 1.0)
//        view.layer.cornerRadius = 4.0
//     
//        
//        quoteNameLbl = UILabel()
//        quoteNameLbl.text = quote.userName
//        quoteNameLbl.textColor = UIColor.black
//        quoteNameLbl.font = UIFont.boldSystemFont(ofSize: 14.0)
//        quoteNameLbl.textAlignment = .left
//        quoteNameLbl.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(quoteNameLbl)
//        quoteNameLbl.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
//        quoteNameLbl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14.0).isActive = true
//        quoteNameLbl.topAnchor.constraint(equalTo: view.topAnchor, constant: 11.0).isActive = true
//        
//        quoteNickLbl = UILabel()
//        quoteNickLbl.text = quote.userScreenName
//        quoteNickLbl.textColor = UIColor.gray
//        quoteNickLbl.font = UIFont.systemFont(ofSize: 11.0)
//        quoteNickLbl.textAlignment = .left
//        quoteNickLbl.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(quoteNickLbl)
//        quoteNickLbl.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
//        quoteNickLbl.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
//        quoteNickLbl.leadingAnchor.constraint(equalTo: quoteNameLbl.trailingAnchor, constant: 5.0).isActive = true
//        quoteNickLbl.lastBaselineAnchor.constraint(equalTo: quoteNameLbl.lastBaselineAnchor).isActive = true
//        quoteNickLbl.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -14.0)
//        
//        quoteTextLbl = UILabel()
//        quoteTextLbl.textColor = UIColor.gray
//        quoteTextLbl.attributedText = quote.text
//        quoteTextLbl.numberOfLines = 0
//        quoteTextLbl.font = UIFont.systemFont(ofSize: 13.0)
//        quoteTextLbl.textAlignment = .left
//        quoteTextLbl.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(quoteTextLbl)
//        quoteTextLbl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14.0).isActive = true
//        quoteTextLbl.topAnchor.constraint(equalTo: quoteNameLbl.bottomAnchor, constant: 2.0).isActive = true
//        let botton = quoteTextLbl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12.0)
//        botton.isActive = true
//        var leading = quoteTextLbl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14.0)
//        leading.isActive = true
//        
//        if let image = quote.mediaImageURLs?.first {
//            quoteImage = UIImageView()
//            quoteImage?.backgroundColor = UIColor.black
//            quoteImage?.contentMode = .scaleAspectFill
//            quoteImage?.clipsToBounds = true
//            quoteImage?.layer.cornerRadius = 2.0
//            quoteImage?.translatesAutoresizingMaskIntoConstraints = false
//            view.addSubview(quoteImage!)
//            quoteImage?.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12.0).isActive = true
//            quoteImage?.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12.0).isActive = true
//            quoteImage?.widthAnchor.constraint(equalTo: (quoteImage?.heightAnchor)!, multiplier: 1.30).isActive = true
//            quoteImage?.topAnchor.constraint(equalTo: quoteNameLbl.bottomAnchor, constant: 6.0).isActive = true
//            quoteImage?.heightAnchor.constraint(equalToConstant: 58.0).isActive = true
//            quoteImage?.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
//            leading.isActive = false
//            leading = quoteTextLbl.leadingAnchor.constraint(equalTo: (quoteImage?.trailingAnchor)!, constant: 12.0)
//            leading.isActive = true
//            //botton.isActive = false
//            
//            quoteImage?.sd_setImage(with: image)
//            
//        }
//        super.init(frame: view.frame)
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    
//    
//}

