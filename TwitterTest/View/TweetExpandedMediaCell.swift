//
//  TweetExpandedMediaCell.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/28/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SDWebImage

class TweetExpandedMediaCell: TweetMediaCell {
    
    var disposes = DisposeBag()
    
    @IBOutlet weak var retweetBTN: UIButton!
    @IBOutlet weak var favoriteBTN: UIButton!
    @IBOutlet weak var replyBTN: UIButton!
    @IBOutlet weak var imageRetweet: UIImageView!
    @IBOutlet weak var imageFavorite: UIImageView!
    
    var tweets: ViewModelTweet! {
        didSet {
            tweetsSetsConfigure()
        }
    }
    
    override func prepareForReuse() {
        disposes = DisposeBag()
    }
    
    func tweetsSetsConfigure() {
        
        
        //tweetID = tweets.tweetID
        userPic.sd_setImage(with: tweets.userAvatar)
        
        userPic.layer.cornerRadius = 5
        userPic.clipsToBounds = true
        userPicBack.layer.cornerRadius = 5
        
        userName.text = tweets.userName
        userScreenName.text = tweets.userScreenName
        tweetContentText.attributedText = tweets.text
        
        tweetTime.text = tweets.timeStamp
        
        
        mediaImageView.layer.cornerRadius = 5.0
        mediaImageView.clipsToBounds = true
        
        
        mediaImageView.sd_setImage(with: tweets.mediaImageURLs.first)
        
        
//        if tweets.retweetCount > 0 {
//            retweetLbl.text = String(tweets.retweetCount)         // важно проверить
//        } else {
//            retweetLbl.text = ""
            imageRetweet.isHidden = true
            
       // }
//        if tweets.favoriteCount > 0 {
//            favoriteLbl.text = String(tweets.favoriteCount)
//        } else {
//            favoriteLbl.text = ""
//            imageFavorite.isHidden = true
//        }
        favoriteBTN.roundDifferentCorner(topLeftRadius: 3.0, topRightRadius: 5.0, bottomRightRadius: 5.0, bottomLeftRadius: 3.0, borderColor: .black, borderWidth: 1.3)
        retweetBTN.round(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 2.0, borderColor: .black, borderWidth: 1.3)
        replyBTN.roundDifferentCorner(topLeftRadius: 5.0, topRightRadius: 3.0, bottomRightRadius: 3.0, bottomLeftRadius: 5.0, borderColor: .black, borderWidth: 1.3)
        favoriteBTN.rx.tap.asObservable().subscribe(onNext: { _ in
            if self.favoriteBTN.isSelected {
                self.favoriteBTN.isSelected = false
                self.favoriteBTN.setImage(UIImage(named :"love"), for: .normal)
                self.tweets.favorited = false
                self.favoriteLbl.text = String(try! self.tweets.favoriteCount.value())
            } else {
                self.favoriteBTN.isSelected = true
                self.favoriteBTN.setImage(UIImage(named: "loveColor"), for: .selected)
                self.tweets.favorited = true
                self.favoriteLbl.text = String(try! self.tweets.favoriteCount.value())
            }
        }).addDisposableTo(disposes)
    }
}
