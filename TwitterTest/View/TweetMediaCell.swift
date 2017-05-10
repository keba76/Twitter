//
//  TweetMediaCell.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/19/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift

class TweetMediaCell: HomeCell {
    
    override func tweetSetConfigure() {
        super.tweetSetConfigure()
        
        tweet.image.asObserver().bindTo(mediaImageView.rx.image).addDisposableTo(dis)
        
        mediaImageView.layer.cornerRadius = 5.0
        mediaImageView.clipsToBounds = true
        let tapMedia = UITapGestureRecognizer()
        tapMedia.rx.event.subscribe(onNext: {[weak self] _ in
            guard let s = self else { return }
            let instinctConvert = s.convert(s.mediaImageView.frame, to: s.contentView)
            s.tweet.cellData.value = CellData.MediaScale(index: s.indexPath!, convert: instinctConvert)
        }).addDisposableTo(dis)
        self.mediaImageView.isUserInteractionEnabled = true
        self.mediaImageView.addGestureRecognizer(tapMedia)
    }
}

