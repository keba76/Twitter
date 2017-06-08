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
    let lastTweetID: String
    let userName: String
    let userScreenName: String
    let replyBtn: BehaviorSubject<Bool>
    var retweetBtn: BehaviorSubject<Bool>
    var favoriteBtn: BehaviorSubject<Bool>
    var settingsBtn: BehaviorSubject<Bool>
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
    var via: String
    var followingStatus: Bool
    var retweeted: Bool {
        didSet {
            if retweeted {
                TwitterClient.swifter.retweetTweet(forID: tweetID)
                let temp = try! retweetCount.value() + 1
                retweetCount.onNext(temp)
                retweetBtn.onNext(true)
            } else {
                TwitterClient.swifter.UnretweetTweet(forID: tweetID)
                let temp = try! retweetCount.value() - 1
                retweetCount.onNext(temp)
                retweetBtn.onNext(false)
            }
            if retweetTweetID != nil, try! retweetBtn.value(), retweetedName != Profile.account?.name{
                retweetedType = "Retweeted by \(retweetedName) and You"
            } else if retweetTweetID != nil {
                
                retweetedType = retweetedName == Profile.account?.name ? "Retweeted by You" : "Retweeted by \(retweetedName)"
            } else if try! retweetBtn.value() {
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
                favoriteBtn.onNext(true)
            } else {
                TwitterClient.swifter.unfavouriteTweet(forID: tweetID)
                let temp = try! favoriteCount.value() - 1
                favoriteCount.onNext(temp)
                favoriteBtn.onNext(false)
            }
        }
    }
    
    init(modelTweet: ModelTweet) {
        text = modelTweet.text
        dictUrlsForSafari = modelTweet.dictUrlsForSafari
        dictUrlsTap = modelTweet.dictUrlsTap
        retweetedType = modelTweet.retweetedType
        tweetID = modelTweet.tweetID
        lastTweetID = modelTweet.lastTweetID
        userName = modelTweet.userName
        userScreenName = modelTweet.userScreenName
        replyBtn = BehaviorSubject<Bool>(value: modelTweet.replyBtn)
        retweetBtn = BehaviorSubject<Bool>(value: modelTweet.retweetBtn)
        favoriteBtn = BehaviorSubject<Bool>(value: modelTweet.favoriteBtn)
        settingsBtn = BehaviorSubject<Bool>(value: modelTweet.settingsBtn)
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
        via = modelTweet.via
        followingStatus = modelTweet.followingStatus
        if modelTweet.quote != nil {quote = ViewModelTweet(modelTweet: modelTweet.quote!)}
        cellData = Variable<CellData>(CellData.tempValue(action: false))
        image = BehaviorSubject<UIImage>(value: UIImage.getEmptyImageWithColor(color: UIColor.white))
        userPicImage = BehaviorSubject<UIImage>(value: UIImage.getEmptyImageWithColor(color: UIColor.white))
        
    }
    
    init(viewModelTweet: ViewModelTweet) {
        text = viewModelTweet.text
        dictUrlsForSafari = viewModelTweet.dictUrlsForSafari
        dictUrlsTap = viewModelTweet.dictUrlsTap
        retweetedType = viewModelTweet.retweetedType
        tweetID = viewModelTweet.tweetID
        lastTweetID = viewModelTweet.lastTweetID
        userName = viewModelTweet.userName
        userScreenName = viewModelTweet.userScreenName
        replyBtn = viewModelTweet.replyBtn
        retweetBtn = BehaviorSubject<Bool>(value: try! viewModelTweet.retweetBtn.value())
        favoriteBtn = BehaviorSubject<Bool>(value: try! viewModelTweet.favoriteBtn.value())
        settingsBtn = BehaviorSubject<Bool>(value: try! viewModelTweet.settingsBtn.value())
        user = viewModelTweet.user
        mediaImageURLs = viewModelTweet.mediaImageURLs
        retweetedName = viewModelTweet.retweetedName
        retweetTweetID = viewModelTweet.retweetTweetID
        userAvatar = viewModelTweet.userAvatar
        timeStamp = viewModelTweet.timeStamp
        retweeted = viewModelTweet.retweeted
        favorited = viewModelTweet.favorited
        retweetCount = BehaviorSubject<Int>(value: try! viewModelTweet.retweetCount.value())
        favoriteCount = BehaviorSubject<Int>(value: try! viewModelTweet.favoriteCount.value())
        retweetedScreenName = viewModelTweet.retweetedScreenName
        userMentions = viewModelTweet.userMentions
        via = viewModelTweet.via
        followingStatus = viewModelTweet.followingStatus
        quote = viewModelTweet.quote
        cellData = Variable<CellData>(CellData.tempValue(action: false))
        image = viewModelTweet.image
        userPicImage = viewModelTweet.userPicImage
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
    case Retweet(index: IndexPath)
    case RetweetInProfile(index: IndexPath, convert: CGPoint)
    case Reply(tweet: ViewModelTweet, modal: Bool, replyAll: Bool)
    case MediaScale(index: IndexPath, convert: CGRect)
    case QuoteTap(tweet: ViewModelTweet)
    case TextInvokeSelectRow(index: IndexPath)
    case Safari(url: String)
    case UserPicTap(tweet: ViewModelTweet)
    case Settings(index: IndexPath, tweet: ViewModelTweet, delete: Bool, viewDetail: Bool, viewRetweets: Bool, modal: Bool)
    
}
