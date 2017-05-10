//
//  QuoteCell.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 4/14/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift
import SDWebImage

class QuoteCell: TweetCompactCell {
    
    @IBOutlet weak var quoteView: UIView!
    
    var quoteNameLbl: UILabel?
    var quoteNickLbl: UILabel?
    var quoteImage: UIImageView?
    var quoteTextLbl: UILabel?
    var stackViewText: UIStackView?
    
    var bottom: NSLayoutConstraint?
    var leading: NSLayoutConstraint?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        quoteView.backgroundColor = UIColor(red: 245/257, green: 245/257, blue: 245/257, alpha: 1.0)
        quoteView.layer.cornerRadius = 4.0
        quoteView.addSubview(quoteNameLbl!)
        quoteView.addSubview(quoteNickLbl!)
        quoteView.addSubview(stackViewText!)
        quoteView.addSubview(quoteImage!)
        quoteNameLbl?.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        quoteNickLbl?.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        quoteNickLbl?.trailingAnchor.constraint(lessThanOrEqualTo: quoteView.trailingAnchor, constant: -14.0)
        quoteTextLbl?.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        quoteTextLbl?.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        quoteImage?.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        quoteImage?.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        quoteNameLbl?.leadingAnchor.constraint(equalTo: quoteView.leadingAnchor, constant: 14.0).isActive = true
        quoteNameLbl?.topAnchor.constraint(equalTo: quoteView.topAnchor, constant: 11.0).isActive = true
        quoteNickLbl?.leadingAnchor.constraint(equalTo: (quoteNameLbl?.trailingAnchor)!, constant: 5.0).isActive = true
        quoteNickLbl?.lastBaselineAnchor.constraint(equalTo: (quoteNameLbl?.lastBaselineAnchor)!).isActive = true
        stackViewText?.trailingAnchor.constraint(equalTo: quoteView.trailingAnchor, constant: -14.0).isActive = true
        stackViewText?.topAnchor.constraint(equalTo: (quoteNameLbl?.bottomAnchor)!, constant: 2.0).isActive = true
        stackViewText?.bottomAnchor.constraint(equalTo: quoteView.bottomAnchor, constant: -12.0).isActive = true
        stackViewText?.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)
        stackViewText?.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .vertical)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        quoteNameLbl = UILabel()
        quoteNameLbl?.textColor = UIColor.black
        quoteNameLbl?.font = UIFont.boldSystemFont(ofSize: 14.0)
        quoteNameLbl?.textAlignment = .left
        quoteNameLbl?.translatesAutoresizingMaskIntoConstraints = false
        
        quoteNickLbl = UILabel()
        quoteNickLbl?.textColor = UIColor.gray
        quoteNickLbl?.font = UIFont.systemFont(ofSize: 11.0)
        quoteNickLbl?.textAlignment = .left
        quoteNickLbl?.translatesAutoresizingMaskIntoConstraints = false
        
        quoteTextLbl = UILabel()
        quoteTextLbl?.textColor = UIColor.gray
        quoteTextLbl?.numberOfLines = 0
        quoteTextLbl?.textAlignment = .left
        quoteTextLbl?.translatesAutoresizingMaskIntoConstraints = false
        stackViewText = UIStackView()
        stackViewText?.axis = UILayoutConstraintAxis.horizontal
        stackViewText?.distribution = UIStackViewDistribution.fillProportionally
        stackViewText?.alignment = UIStackViewAlignment.top
        stackViewText?.addArrangedSubview(quoteTextLbl!)
        stackViewText?.translatesAutoresizingMaskIntoConstraints = false

        quoteImage = UIImageView()
        quoteImage?.backgroundColor = UIColor.black
        quoteImage?.contentMode = .scaleAspectFill
        quoteImage?.clipsToBounds = true
        quoteImage?.layer.cornerRadius = 2.0
        quoteImage?.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        leading?.isActive = false
        bottom?.isActive = false
        leading = stackViewText?.leadingAnchor.constraint(equalTo: quoteView.leadingAnchor, constant: 14.0)
        leading?.isActive = true
        
        if !tweet.quote!.mediaImageURLs.isEmpty {
            bottom = quoteImage?.bottomAnchor.constraint(equalTo: quoteView.bottomAnchor, constant: -12.0)
            bottom?.isActive = true
            quoteImage?.leadingAnchor.constraint(equalTo: quoteView.leadingAnchor, constant: 12.0).isActive = true
            quoteImage?.widthAnchor.constraint(equalTo: (quoteImage?.heightAnchor)!, multiplier: 1.3).isActive = true
            quoteImage?.topAnchor.constraint(equalTo: (quoteNameLbl?.bottomAnchor)!, constant: 6.0).isActive = true
            quoteImage?.heightAnchor.constraint(equalToConstant: 60.0).isActive = true
            leading?.isActive = false
            leading = stackViewText?.leadingAnchor.constraint(equalTo: (quoteImage?.trailingAnchor)!, constant: 12.0)
            leading?.isActive = true
        }
    }
    
    override func tweetSetConfigure() {
        super.tweetSetConfigure()
        
        guard let twee = tweet.quote else { return }
        
        if twee.mediaImageURLs.isEmpty {
            quoteImage?.isHidden = true
        } else {
            quoteImage?.isHidden = false
        }
        setNeedsUpdateConstraints()
        
        if !twee.mediaImageURLs.isEmpty {
            quoteImage?.sd_setImage(with: twee.mediaImageURLs.first)
        }
        quoteNameLbl?.text = twee.userName
        quoteNickLbl?.text = twee.userScreenName
        quoteTextLbl?.attributedText = twee.text
        quoteTextLbl?.font = UIFont.systemFont(ofSize: 12.0)
        
        let tapQuote = UITapGestureRecognizer()
        tapQuote.rx.event.subscribe(onNext: {[weak self] _ in
            guard let s = self else { return }
            s.tweet.cellData.value = CellData.QuoteTap(tweet: twee)
        }).addDisposableTo(dis)
        if quoteView != nil {
            self.quoteView.isUserInteractionEnabled = true
            self.quoteView.addGestureRecognizer(tapQuote)
        }
    }
}
