//
//  DetailCompactCell.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 5/20/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift
import SDWebImage

class DetailCompactCell: UITableViewCell {
    
    @IBOutlet weak var userPic: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userScreenName: UILabel!
    @IBOutlet weak var tweetContentText: UILabel!
    @IBOutlet weak var tweetTime: UILabel!
    @IBOutlet weak var retweetBtn: UIButton!
    @IBOutlet weak var favoriteBtn: UIButton!
    @IBOutlet weak var replyBtn: UIButton!
    @IBOutlet weak var settingsBtn: UIButton!
    @IBOutlet weak var imageRetweet: UIImageView!
    @IBOutlet weak var imageFavorite: UIImageView!
    @IBOutlet weak var retweetLbl: UILabel!
    @IBOutlet weak var favoriteLbl: UILabel!
    @IBOutlet weak var viaLbl: UILabel!
    @IBOutlet weak var traillingLblRetweet: NSLayoutConstraint!
    @IBOutlet weak var topImageRetweetStack: NSLayoutConstraint!
    
    var dis = DisposeBag()
    override func prepareForReuse() { dis = DisposeBag() }
    
    var indexPath: IndexPath?
    
    func tweetSetConfigure(tweet: ViewModelTweet) {
       
        
        userPic.layer.cornerRadius = 5
        userPic.clipsToBounds = true
        userPic.layer.borderColor = UIColor.darkGray.cgColor
        userPic.layer.borderWidth = 0.5
        
        userName.text = tweet.userName
        userScreenName.text = tweet.userScreenName
        if indexPath?.row != 0 { tweetContentText.attributedText = tweet.text }
        
        tweetTime.text = tweet.timeStamp
        viaLbl.text = "via \(tweet.via)"
        
        traillingLblRetweet.constant = 10.0
        if let value = try? tweet.retweetCount.value(), value > 0 {
            retweetLbl.text = String(value)
        } else {
            retweetLbl.isHidden = true
            imageRetweet.isHidden = true
        }
        if let value = try? tweet.favoriteCount.value(), value > 0 {
            favoriteLbl.text = String(value)
        } else {
            traillingLblRetweet.constant = 0
            favoriteLbl.isHidden = true
            imageFavorite.isHidden = true
        }
        if favoriteLbl.isHidden, imageFavorite.isHidden {
            topImageRetweetStack.constant = 0.0
        } else {
            topImageRetweetStack.constant = 14.0
        }
        
        let tapUserPic = UITapGestureRecognizer()
        let tapUrls = UITapGestureRecognizer()
        self.userPic.isUserInteractionEnabled = true
        self.userPic.addGestureRecognizer(tapUserPic)
        self.tweetContentText.isUserInteractionEnabled = true
        self.tweetContentText.addGestureRecognizer(tapUrls)
        
        tweet.userPicImage
            .asObserver()
            .observeOn(MainScheduler.instance)
            .bindNext { [weak self] image in
                guard let s = self else { return }
                s.userPic.image = image
            }.addDisposableTo(self.dis)
        
        
        DispatchQueue.global().async {
            tweet.replyBtn
                .asObservable()
                .observeOn(MainScheduler.instance)
                .bindNext { [weak self] data in
                    guard let s = self else { return }
                    if data {
                        s.replyBtn.setImage(UIImage(named: "replyBtnDetailPush"), for: .normal)
                    } else {
                        s.replyBtn.setImage(UIImage(named: "replyBtnDetail"), for: .normal)
                    }
                }.addDisposableTo(self.dis)
            
            tweet.retweetBtn
            .asObservable()
            .observeOn(MainScheduler.instance)
                .bindNext{ [weak self] data in
                    guard let s = self else { return }
                    if data {
                        s.retweetBtn.setImage(UIImage(named: "retweetBtnDetailPush"), for: .normal)
                    } else {
                        s.retweetBtn.setImage(UIImage(named: "retweetBtnDetail"), for: .normal)
                    }
                }.addDisposableTo(self.dis)

            tweet.favoriteBtn
                .asObservable()
                .observeOn(MainScheduler.instance)
                .bindNext{ [weak self] data in
                    guard let s = self else { return }
                    if data {
                        s.favoriteBtn.setImage(UIImage(named: "favoriteBtnDetailPush"), for: .normal)
                    } else {
                       s.favoriteBtn.setImage(UIImage(named: "favoriteBtnDetail"), for: .normal)
                    }
                }.addDisposableTo(self.dis)
            
            tweet.retweetCount
                .asObservable()
                .observeOn(MainScheduler.instance)
                .bindNext { [weak self] data in
                    guard let s = self else { return }
                    var dataString = ""
                    if data > 0 { dataString = String(data) }
                    s.retweetLbl.text = dataString
                }.addDisposableTo(self.dis)
            
            tweet.favoriteCount
                .asObservable()
                .observeOn(MainScheduler.instance)
                .bindNext { [weak self] data in
                    guard let s = self else { return }
                    var dataString = ""
                    if data > 0 { dataString = String(data) }
                    s.favoriteLbl.text = dataString
                }.addDisposableTo(self.dis)
            
//            tweet.userPicImage
//                .asObserver()
//                .observeOn(MainScheduler.instance)
//                .bindNext { [weak self] image in
//                    guard let s = self else { return }
//                    s.userPic.image = image
//                }.addDisposableTo(self.dis)
            
            self.retweetBtn.rx.controlEvent(UIControlEvents.touchDown)
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self] _ in
                    guard let s = self else { return }
                    if try! tweet.retweetBtn.value() {
                        s.retweetBtn.setImage(UIImage(named: "retweetBtnDetailPushBack"), for: .highlighted)
                        tweet.retweeted = false
                        Profile.tweetID[tweet.tweetID] = false
                        Profile.reloadingProfileTweetsWhenRetweet -= 1
                      //  tweet.cellData.value = CellData.Retweet(index: s.indexPath!)
                    } else if tweet.user.id != Profile.account?.id {
                        s.retweetBtn.setImage(UIImage(named: "retweetBtnDetailBack"), for: .highlighted)
                        tweet.retweeted = true
                        Profile.tweetID[tweet.tweetID] = true
                        Profile.reloadingProfileTweetsWhenRetweet += 1
                      //  tweet.cellData.value = CellData.Retweet(index: s.indexPath!)
                    }}.addDisposableTo(self.dis)
            
            self.favoriteBtn.rx.controlEvent(UIControlEvents.touchDown)
            .observeOn(MainScheduler.instance)
                .subscribe { [weak self] _ in
                    guard let s = self else { return }
                    if try! tweet.favoriteBtn.value() {
                        s.favoriteBtn.setImage(UIImage(named: "favoriteBtnDetailPushBack"), for: .highlighted)
                        tweet.favorited = false
                        Profile.tweetIDForFavorite[tweet.tweetID] = false
                    } else  {
                        s.favoriteBtn.setImage(UIImage(named: "favoriteBtnDetailBack"), for: .highlighted)
                        tweet.favorited = true
                         Profile.tweetIDForFavorite[tweet.tweetID] = true
                    }
            }.addDisposableTo(self.dis)
            
            self.replyBtn.rx.controlEvent(UIControlEvents.touchDown)
                .observeOn(MainScheduler.instance)
                .bindNext { [weak self] _ in
                    guard let s = self else { return }
                    s.replyBtn.setImage(UIImage(named: "replyBtnDetailPushBack"), for: .highlighted)
                    tweet.replyBtn.onNext(true)
                    Profile.reloadingProfileTweetsWhenReply += 1
                        tweet.cellData.value = tweet.userMentions.count > 0 || tweet.retweetTweetID != nil ? CellData.Reply(tweet: tweet, modal: true, replyAll: false) : CellData.Reply(tweet: tweet, modal: false, replyAll: false)
                }.addDisposableTo(self.dis)
            
            tapUserPic.rx.event
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    tweet.cellData.value = CellData.UserPicTap(tweet: tweet)
                }).addDisposableTo(self.dis)
            
            tapUrls.rx.event
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: {[weak self] _ in
                    guard let s = self else { return }
                    var tapWithinTweetUrl = false
                    if !tweet.dictUrlsTap.isEmpty {
                        for (key, range) in tweet.dictUrlsTap {
                            if tapUrls.didTapAttributedTextInLabel(label: s.tweetContentText, inRange: range) {
                                tweet.cellData.value = CellData.Safari(url: tweet.dictUrlsForSafari[key]!)
                                tapWithinTweetUrl = true
                                break
                            }
                        }
                        if !tapWithinTweetUrl {
                            tweet.cellData.value = CellData.TextInvokeSelectRow(index: s.indexPath!)
                        }
                    } else {
                        tweet.cellData.value = CellData.TextInvokeSelectRow(index: s.indexPath!)
                    }
                }).addDisposableTo(self.dis)
        }

    }
}
