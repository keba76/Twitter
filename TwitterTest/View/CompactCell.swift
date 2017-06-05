//
//  CompactCell.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 5/17/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift

class CompactCell: UITableViewCell {
    
    @IBOutlet weak var userPic: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userScreenName: UILabel!
    @IBOutlet weak var tweetContentText: UILabel!
    @IBOutlet weak var tweetTime: UILabel!
    @IBOutlet weak var retweetLbl: UILabel!
    @IBOutlet weak var favoriteLbl: UILabel!
    @IBOutlet weak var retweetBtn: DOFavoriteButton!
    @IBOutlet weak var favoriteBtn: DOFavoriteButton!
    @IBOutlet weak var replyBtn: DOFavoriteButton!
    @IBOutlet weak var retweetedLbl: UILabel!
    
    @IBOutlet weak var logoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var lblHeihtConstraint: NSLayoutConstraint!
    @IBOutlet weak var picBackConstraint: NSLayoutConstraint!
    
    var indexPath: IndexPath?
    
    var delegate: TwitterTableViewDelegate?
    
    var dis = DisposeBag()
    override func prepareForReuse() { dis = DisposeBag() }
    
    func tweetSetConfigure(tweet: ViewModelTweet) {
        if logoHeightConstraint != nil {
            if tweet.retweetedType.isEmpty {
                logoHeightConstraint.constant = 0
                lblHeihtConstraint.constant = 0
                picBackConstraint.constant = 6
            } else {
                retweetedLbl.text = tweet.retweetedType
                logoHeightConstraint.constant = 12
                lblHeihtConstraint.constant = 12
                picBackConstraint.constant = 18
            }
        }
        tweetContentText.attributedText = tweet.text
        userPic.layer.cornerRadius = 5
        userPic.clipsToBounds = true
        userPic.layer.borderColor = UIColor.darkGray.cgColor
        userPic.layer.borderWidth = 0.5
        
        userName.text = tweet.userName
        userScreenName.text = tweet.userScreenName
        tweetTime.text = tweet.timeStamp
        
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
                    s.replyBtn.isSelected = data
                }.addDisposableTo(self.dis)
            
            tweet.retweetBtn
                .asObservable()
                .observeOn(MainScheduler.instance)
                .bindNext{ [weak self] data in
                    guard let s = self else { return }
                    s.retweetBtn.isSelected = data
                }.addDisposableTo(self.dis)
            
            tweet.favoriteBtn
                .asObservable()
                .observeOn(MainScheduler.instance)
                .bindNext{ [weak self] data in
                    guard let s = self else { return }
                    s.favoriteBtn.isSelected = data
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
            
            self.retweetBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self] _ in
                    guard let s = self else { return }
                    if s.retweetBtn.isSelected {
                        s.retweetBtn.deselect()
                        tweet.retweeted = false
                        Profile.tweetID[tweet.tweetID] = false
                        Profile.reloadingProfileTweetsWhenRetweet -= 1
                        tweet.cellData.value = CellData.Retweet(index: s.indexPath!)
                    } else if tweet.user.id != Profile.account?.id {
                        s.retweetBtn.select()
                        tweet.retweeted = true
                        Profile.tweetID[tweet.tweetID] = true
                        Profile.reloadingProfileTweetsWhenRetweet += 1
                        tweet.cellData.value = CellData.Retweet(index: s.indexPath!)
                    }}.addDisposableTo(self.dis)
            
            self.favoriteBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .bindNext { [weak self] _ in
                    guard let s = self else { return }
                    if s.favoriteBtn.isSelected {
                        s.favoriteBtn.deselect()
                        tweet.favorited = false
                        Profile.tweetIDForFavorite[tweet.tweetID] = false
                        s.delegate?.extensionProfVC(someTweetsData: SomeTweetsData(indexPath: s.indexPath, switchBool: false))
                    } else {
                        s.favoriteBtn.select()
                        tweet.favorited = true
                        Profile.tweetIDForFavorite[tweet.tweetID] = true
                        s.delegate?.extensionProfVC(someTweetsData: SomeTweetsData(indexPath: s.indexPath, switchBool: true))
                    }
                }.addDisposableTo(self.dis)
            
            self.replyBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .bindNext { [weak self] _ in
                    guard let s = self else { return }
                    if !s.replyBtn.isSelected { s.replyBtn.select() }
                    tweet.replyBtn.onNext(true)
                    Profile.reloadingProfileTweetsWhenReply += 1
                    if Profile.profileAccount {
                        tweet.cellData.value = tweet.userMentions.count > 0 ? CellData.Reply(tweet: tweet, modal: true, replyAll: false) : CellData.Reply(tweet: tweet, modal: false, replyAll: false)
                    } else {
                        tweet.cellData.value = tweet.userMentions.count > 0 || tweet.retweetTweetID != nil ? CellData.Reply(tweet: tweet, modal: true, replyAll: false) : CellData.Reply(tweet: tweet, modal: false, replyAll: false)
                    }
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