//
//  ViewModelTweet.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 4/21/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

//private extension Reactive where Base: UIImageView {
//    var imageTemp: UIBindingObserver<Base, UIImage> {
//        return UIBindingObserver(UIElement: base) { x, y in
//            x.image = 
//}
//    }
//}

class ViewModelTweet {
    
    let dis = DisposeBag()
    
    let text: NSMutableAttributedString
    var dictUrlsForSafari: Dictionary<String, String>
    var dictUrlsTap: Dictionary<String, NSRange>
    var retweetedType: String
    let tweetID: String
    let userName: String
    let userScreenName: String
    let replyBtn: BehaviorSubject<Bool>
    var retweetBtn: Bool
    var favoriteBtn: Bool
    let user: ModelUser
    var mediaImageURLs: [URL]
    var quote: ViewModelTweet?
    var retweetedName: String
    var retweetTweetID: String?
    var userAvatar: URL
    var timeStamp: String
    var retweetedScreenName: String
    var userMentions = [String]()
    var cellData: Variable<CellData>
    var retweetCount: BehaviorSubject<Int>
    var image: BehaviorSubject<UIImage>
    var userPicImage: BehaviorSubject<UIImage>
    var retweeted: Bool {
        didSet {
            if retweeted {
                TwitterClient.swifter.retweetTweet(forID: tweetID)
                let temp = try! retweetCount.value() + 1
                retweetCount.onNext(temp)
                retweetBtn = true
            } else {
                TwitterClient.swifter.UnretweetTweet(forID: tweetID)
                let temp = try! retweetCount.value() - 1
                retweetCount.onNext(temp)
                retweetBtn = false
            }
            if retweetTweetID != nil, retweetBtn, retweetedName != Profile.account?.name{
                retweetedType = "Retweeted by \(retweetedName) and You"
            } else if retweetTweetID != nil {
                
                retweetedType = retweetedName == Profile.account?.name ? "Retweeted by You" : "Retweeted by \(retweetedName)"
            } else if retweetBtn {
                retweetedType = "Retweeted by You"
            } else {
                retweetedType = ""
            }
        }
    }
    var favoriteCount: BehaviorSubject<Int>
    var favorited: Bool {
        didSet {
            if favorited {
                TwitterClient.swifter.favouriteTweet(forID: tweetID)
                let temp = try! favoriteCount.value() + 1
                favoriteCount.onNext(temp)
                favoriteBtn = true
            } else {
                TwitterClient.swifter.unfavouriteTweet(forID: tweetID)
                let temp = try! favoriteCount.value() - 1
                favoriteCount.onNext(temp)
                favoriteBtn = false
            }
        }
    }
    
    
    
    init(modelTweet: ModelTweet) {
        text = modelTweet.text
        dictUrlsForSafari = modelTweet.dictUrlsForSafari
        dictUrlsTap = modelTweet.dictUrlsTap
        retweetedType = modelTweet.retweetedType
        tweetID = modelTweet.tweetID
        userName = modelTweet.userName
        userScreenName = modelTweet.userScreenName
        replyBtn = BehaviorSubject<Bool>(value: modelTweet.replyBtn)
        retweetBtn = modelTweet.retweetBtn
        favoriteBtn = modelTweet.favoriteBtn
        user = ModelUser(parse: modelTweet.user)
        mediaImageURLs = modelTweet.mediaImageURLs ?? [URL]()
        retweetedName = modelTweet.retweetedName
        retweetTweetID = modelTweet.retweetTweetID
        userAvatar = modelTweet.userAvatar
        timeStamp = modelTweet.timeStamp
        retweeted = modelTweet.retweeted
        favorited = modelTweet.favorited
        retweetCount = BehaviorSubject<Int>(value: modelTweet.retweetCount)
        favoriteCount = BehaviorSubject<Int>(value: modelTweet.favoriteCount)
        retweetedScreenName = modelTweet.retweetedScreenName
        userMentions = modelTweet.userMentions
        if modelTweet.quote != nil {quote = ViewModelTweet(modelTweet: modelTweet.quote!)}
        cellData = Variable<CellData>(CellData.tempValue(action: false))
        image = BehaviorSubject<UIImage>(value: UIImage.getEmptyImageWithColor(color: UIColor.white))
        userPicImage = BehaviorSubject<UIImage>(value: UIImage.getEmptyImageWithColor(color: UIColor.white))
        
        
    }
}
extension ViewModelTweet: Hashable {
    
    var hashValue: Int {
        return try! favoriteCount.value()
    }
    
    static func == (lhs: ViewModelTweet, rhs: ViewModelTweet) -> Bool {
        return lhs.tweetID == rhs.tweetID //&&
//            lhs.retweetedType == rhs.retweetedType &&
//            lhs.text == rhs.text &&
//            lhs.tweetTime == rhs.tweetTime &&
//            lhs.userName == rhs.userName &&
//            lhs.userScreenName == rhs.userScreenName &&
//        lhs.quote === rhs.quote &&
//        lhs.favoriteBtn == rhs.favoriteBtn &&
//        lhs.tweetTime == rhs.tweetTime &&
//        lhs.replyBtn == rhs.replyBtn &&
//        lhs.retweetBtn == rhs.retweetBtn &&
//        lhs.favoriteBtn == rhs.favoriteBtn &&
//        lhs.mediaImageURLs == rhs.mediaImageURLs &&
//        lhs.retweetedName == rhs.retweetedName &&
//        lhs.userAvatar == rhs.userAvatar &&
//        lhs.timeStamp == rhs.timeStamp &&
//        lhs.retweetedScreenName == rhs.retweetedScreenName &&
//        lhs.userMentions == rhs.userMentions
        
        
        
        
    }
}

enum CellData {
    case tempValue(action: Bool)
    case Retweet(index: IndexPath, convert: CGPoint)
    case RetweetInProfile(index: IndexPath, convert: CGPoint)
    case Reply(tweet: ViewModelTweet, modal: Bool, replyAll: Bool)
    case MediaScale(index: IndexPath, convert: CGRect)
    case QuoteTap(tweet: ViewModelTweet)
    case TextInvokeSelectRow(index: IndexPath)
    case Safari(url: String)
    case UserPicTap(tweet: ViewModelTweet)
    
}
