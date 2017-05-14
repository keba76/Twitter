//
//  HomeCell.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/14/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class HomeCell: UITableViewCell {
    
    @IBOutlet weak var userPic: UIImageView!
    @IBOutlet weak var userPicBack: UIView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userScreenName: UILabel!
    @IBOutlet weak var tweetContentText: UILabel!
    @IBOutlet weak var tweetTime: UILabel!
    @IBOutlet weak var retweetLbl: UILabel!
    @IBOutlet weak var mediaImageView: UIImageView!
    @IBOutlet weak var favoriteLbl: UILabel!
    @IBOutlet weak var retweetBtn: DOFavoriteButton!
    @IBOutlet weak var favoriteBtn: DOFavoriteButton!
    @IBOutlet weak var replyBtn: DOFavoriteButton!
    @IBOutlet weak var retweetedLbl: UILabel!
    
    @IBOutlet weak var logoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var lblHeihtConstraint: NSLayoutConstraint!
    @IBOutlet weak var picBackConstraint: NSLayoutConstraint!
    
    var indexPath: IndexPath?
    
    var dis = DisposeBag()
    override func prepareForReuse() {
        dis = DisposeBag()
    }
    
    var tweet: ViewModelTweet! {
        didSet {
            tweetSetConfigure()
        }
    }
    
    func tweetSetConfigure() {
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
        
        tweet.retweetCount.asObservable().map {$0 > 0 ? String($0) : ""}.bindTo(retweetLbl.rx.text).addDisposableTo(dis)
        tweet.favoriteCount.asObservable().map {$0 > 0 ? String($0) : ""}.bindTo(favoriteLbl.rx.text).addDisposableTo(dis)
        
        tweet.userPicImage.asObserver().bindTo(userPic.rx.image).addDisposableTo(dis)
        
        userPic.layer.cornerRadius = 5
        userPic.clipsToBounds = true
        userPicBack.layer.cornerRadius = 5
        
        userName.text = tweet.userName
        userScreenName.text = tweet.userScreenName
        tweetContentText.attributedText = tweet.text
        
        tweetTime.text = tweet.timeStamp
        
        tweet.replyBtn.asObservable().bindTo(replyBtn.rx.isSelected).addDisposableTo(dis)
        retweetBtn.isSelected = tweet.retweetBtn
        favoriteBtn.isSelected = tweet.favoriteBtn
        
        retweetBtn.rx.tap.asObservable().subscribe { [weak self] _ in
            guard let s = self else { return }
            if TabBarVC.tab == .profileVC {
                let point = s.convert(s.userName.frame.origin, to: s.contentView.superview?.superview)
                if s.retweetBtn.isSelected {
                    s.retweetBtn.deselect()
                    s.tweet.retweeted = false
                    s.tweet.cellData.value = CellData.Retweet(index: s.indexPath!, convert: point)
                    Profile.reloadingProfileTweetsWhenRetweet -= 1
                } else if !Profile.profileAccount {
                    s.retweetBtn.select()
                    s.tweet.retweeted = true
                    s.tweet.cellData.value = CellData.Retweet(index: s.indexPath!, convert: point)
                    Profile.reloadingProfileTweetsWhenRetweet += 1
                }
            } else if s.retweetBtn.isSelected {
                s.retweetBtn.deselect()
                s.tweet.retweeted = false
                s.tweet.cellData.value = CellData.Retweet(index: s.indexPath!, convert: CGPoint.zero)
                if TabBarVC.tab == .profileVC {
                    //Profile.reloadingProfileTweetsWhenRetweet = false
                }
            } else if s.tweet.user.id != Profile.account.id {
                s.retweetBtn.select()
                s.tweet.retweeted = true
                s.tweet.cellData.value = CellData.Retweet(index: s.indexPath!, convert: CGPoint.zero)
            }
            }.addDisposableTo(dis)
        
        favoriteBtn.rx.tap.bindNext { [weak self] _ in
            guard let s = self else { return }
            if s.favoriteBtn.isSelected {
                s.favoriteBtn.deselect()
                s.tweet.favorited = false
            } else {
                s.favoriteBtn.select()
                s.tweet.favorited = true
            }
            }.addDisposableTo(dis)
        
        replyBtn.rx.tap.bindNext { [weak self] _ in
            guard let s = self else { return }
            s.tweet.replyBtn.onNext(true)
            if Profile.profileAccount {
                s.tweet.cellData.value = s.tweet.userMentions.count > 0 ? CellData.Reply(tweet: s.tweet, modal: true, replyAll: false) : CellData.Reply(tweet: s.tweet, modal: false, replyAll: false)
            } else {
                s.tweet.cellData.value = s.tweet.userMentions.count > 0 || s.tweet.retweetTweetID != nil ? CellData.Reply(tweet: s.tweet, modal: true, replyAll: false) : CellData.Reply(tweet: s.tweet, modal: false, replyAll: false)
            }
            }.addDisposableTo(dis)
        
        
        let tapUserPic = UITapGestureRecognizer()
        tapUserPic.rx.event.subscribe(onNext: {[weak self] _ in
            guard let s = self else { return }
            s.tweet.cellData.value = CellData.UserPicTap(tweet: s.tweet)
        }).addDisposableTo(dis)
        self.userPic.isUserInteractionEnabled = true
        self.userPic.addGestureRecognizer(tapUserPic)
        
        let tapUrls = UITapGestureRecognizer()
        tapUrls.rx.event.subscribe(onNext: {[weak self] _ in
            guard let s = self else { return }
            if !s.tweet.dictUrlsTap.isEmpty {
                s.tweet.dictUrlsTap.forEach({ (key, range) in
                    if tapUrls.didTapAttributedTextInLabel(label: s.tweetContentText, inRange: range) {
                        s.tweet.cellData.value = CellData.Safari(url: s.tweet.dictUrlsForSafari[key]!)
                    } else {
                        s.tweet.cellData.value = CellData.TextInvokeSelectRow(index: s.indexPath!)
                    }
                })
            } else {
                s.tweet.cellData.value = CellData.TextInvokeSelectRow(index: s.indexPath!)
            }
        }).addDisposableTo(dis)
        self.tweetContentText.isUserInteractionEnabled = true
        self.tweetContentText.addGestureRecognizer(tapUrls)
    }
}





