//
//  MediaCell.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 5/17/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift

class MediaCell: UITableViewCell {
    
    @IBOutlet weak var userPic: UIImageView!
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
    @IBOutlet weak var settingsBtn: DOFavoriteButton!
    @IBOutlet weak var retweetedLbl: UILabel!
    @IBOutlet weak var speechBuble: UIImageView!
    
    @IBOutlet weak var logoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var lblHeihtConstraint: NSLayoutConstraint!
    @IBOutlet weak var picBackConstraint: NSLayoutConstraint!
    @IBOutlet weak var speechBubleConstraint: NSLayoutConstraint!
    
    var indexPath: IndexPath?
    
    lazy var viewPlay: UIImageView = self.arrowImage()
    
    var delegate: TwitterTableViewDelegate?
    
    var dis = DisposeBag()
    override func prepareForReuse() { dis = DisposeBag() }
    
    func tweetSetConfigure(tweet: ViewModelTweet) {
        if speechBuble != nil {
            if tweet.tweetContainMentionsProfile, !tweet.replyConversation.isEmpty {
                
                speechBuble.isHidden = false
                speechBubleConstraint.constant = 16.0
                speechBuble.image = UIImage(named: "speechBubleBlue")
            } else if !tweet.replyConversation.isEmpty {
                speechBuble.isHidden = false
                speechBubleConstraint.constant = 16.0
                speechBuble.image = UIImage(named: "speechBuble")
            } else {
                speechBuble.isHidden = true
                speechBubleConstraint.constant = 0.0
            }
        }
        
        if tweet.videoURL != nil || tweet.instagramVideo != nil {
            viewPlay.isHidden = false
         viewPlay.image = UIImage(named: "playBtnAlpha")
        } else {
            viewPlay.isHidden = true
        }
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
        userPic.layer.cornerRadius = 5.0
        userPic.clipsToBounds = true
        userPic.layer.borderColor = UIColor.darkGray.cgColor
        userPic.layer.borderWidth = 0.5
        
        mediaImageView.layer.cornerRadius = 5.0
        mediaImageView.clipsToBounds = true
        
        userName.text = tweet.userName
        userScreenName.text = tweet.userScreenName
        tweetTime.text = tweet.timeStamp
        
        let tapUserPic = UITapGestureRecognizer()
        let tapUrls = UITapGestureRecognizer()
        let tapMedia = UITapGestureRecognizer()
        self.userPic.isUserInteractionEnabled = true
        self.userPic.addGestureRecognizer(tapUserPic)
        self.tweetContentText.isUserInteractionEnabled = true
        self.tweetContentText.addGestureRecognizer(tapUrls)
        self.mediaImageView.isUserInteractionEnabled = true
        self.mediaImageView.addGestureRecognizer(tapMedia)
        
        tweet.image
            .asObservable()
            .observeOn(MainScheduler.instance)
            .bind { [weak self] image in
                guard let s = self else { return }
                s.mediaImageView.image = image
            }.disposed(by: self.dis)
        
        tweet.userPicImage
            .asObserver()
            .observeOn(MainScheduler.instance)
            .bind { [weak self] image in
                guard let s = self else { return }
                s.userPic.image = image
            }.disposed(by: self.dis)
        
        DispatchQueue.global().async {
            tweet.settingsBtn
                .asObservable()
                .observeOn(MainScheduler.instance)
                .bind { [weak self] data in
                    guard let s = self else { return }
                    s.settingsBtn.isSelected = data
                }.disposed(by: self.dis)
            
            tweet.replyBtn
                .asObservable()
                .observeOn(MainScheduler.instance)
                .bind { [weak self] data in
                    guard let s = self else { return }
                    s.replyBtn.isSelected = data
                }.disposed(by: self.dis)
            
            tweet.retweetBtn
                .asObservable()
                .observeOn(MainScheduler.instance)
                .bind{ [weak self] data in
                    guard let s = self else { return }
                    s.retweetBtn.isSelected = data
                }.disposed(by: self.dis)
            
            tweet.favoriteBtn
                .asObservable()
                .observeOn(MainScheduler.instance)
                .bind{ [weak self] data in
                    guard let s = self else { return }
                    s.favoriteBtn.isSelected = data
                }.disposed(by: self.dis)
            
            tweet.retweetCount
                .asObservable()
                .observeOn(MainScheduler.instance)
                .bind { [weak self] data in
                    guard let s = self else { return }
                    var dataString = ""
                    if data > 0 { dataString = String(data) }
                    s.retweetLbl.text = dataString
                }.disposed(by: self.dis)
            
            tweet.favoriteCount
                .asObservable()
                .observeOn(MainScheduler.instance)
                .bind { [weak self] data in
                    guard let s = self else { return }
                    var dataString = ""
                    if data > 0 { dataString = String(data) }
                    s.favoriteLbl.text = dataString
                }.disposed(by: self.dis)
            
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
                    } else if tweet.user.id != Profile.account.id {
                        s.retweetBtn.select()
                        tweet.retweeted = true
                        Profile.tweetID[tweet.tweetID] = true
                        Profile.reloadingProfileTweetsWhenRetweet += 1
                        tweet.cellData.value = CellData.Retweet(index: s.indexPath!)
                    }}.disposed(by: self.dis)
            
            self.favoriteBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .bind { [weak self] _ in
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
                }.disposed(by: self.dis)
            
            self.replyBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .bind { [weak self] _ in
                    guard let s = self else { return }
                    if !s.replyBtn.isSelected { s.replyBtn.select() }
                    tweet.replyBtn.onNext(true)
                    Profile.reloadingProfileTweetsWhenReply += 1
                    if Profile.profileAccount {
                        tweet.cellData.value = tweet.userMentions.count > 0 ? CellData.Reply(tweet: tweet, modal: true, replyAll: false) : CellData.Reply(tweet: tweet, modal: false, replyAll: false)
                    } else {
                        tweet.cellData.value = tweet.userMentions.count > 0 || tweet.retweetTweetID != nil ? CellData.Reply(tweet: tweet, modal: true, replyAll: false) : CellData.Reply(tweet: tweet, modal: false, replyAll: false)
                    }
                }.disposed(by: self.dis)
            
            self.settingsBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .bind { [weak self] _ in
                    guard let s = self else { return }
                    if !s.settingsBtn.isSelected { s.settingsBtn.select() }
                    tweet.settingsBtn.onNext(true)
                    tweet.cellData.value = CellData.Settings(index: s.indexPath!, tweet: tweet, delete: false, viewDetail: false, viewRetweets: false, modal: true)
                }.disposed(by: self.dis)
            
            tapUserPic.rx.event
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    tweet.cellData.value = CellData.UserPicTap(tweet: tweet)
                }).disposed(by: self.dis)
            
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
                }).disposed(by: self.dis)
            
            tapMedia.rx.event
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: {[weak self] _ in
                    guard let s = self else { return }
                    let instinctConvert = s.convert(s.mediaImageView.frame, to: s.contentView)
                    
                    tweet.cellData.value = CellData.MediaScale(index: s.indexPath!, convert: instinctConvert)
                }).disposed(by: self.dis)
        }
    }
    
    func arrowImage() -> UIImageView {
        let image = UIImageView(frame: CGRect(x: mediaImageView.bounds.center.x - 15, y: mediaImageView.bounds.center.y - 15, width: 30.0, height: 30.0))
        image.alpha = 0.7
        mediaImageView.addSubview(image)
        return image
        
    }
}
