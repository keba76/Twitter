    //
    //  DetailsVC.swift
    //  TwitterTest
    //
    //  Created by Ievgen Keba on 2/28/17.
    //  Copyright © 2017 Harman Inc. All rights reserved.
    //
    
    import UIKit
    import RxSwift
    import SafariServices
    import SDWebImage
    
    class EmptyCellForConversation: UITableViewCell {}
    
    class DetailsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching, UIScrollViewDelegate, TwitterTableViewDelegate {
        
        @IBOutlet weak var tableView: UITableView!
        
        let dis = DisposeBag()
        
        var isMoreDataLoading = (move: false, download: false)
        
        var animationController: AnimationController = AnimationController()
        var dataMediaScale: SomeTweetsData?
        
        var tweet: ViewModelTweet?
        var tweetDetails: ViewModelTweet?
        var tweetChain = [ViewModelTweet]()
        var arrayConversation = [ViewModelTweet]()
        var instanceDetail: TwitterClient?
        var indexPath: IndexPath?
        var quoteTap = false
        let myGroup = DispatchGroup()
        lazy var group = DispatchQueue.global(qos: .userInitiated)
        
        var heightCell = Array<CGFloat>()
        var attributeText: NSMutableAttributedString?
        static var tweetIDforDetailsVC = Array<(String, Bool, Bool)>()
        
        fileprivate let imageLoadQueue = OperationQueue()
        fileprivate var imageLoadOperations = [IndexPath: ImageLoadOperation]()
        fileprivate var imageLoadOperationsMedia = [IndexPath: ImageLoadOperation]()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            AppUtility.lockOrientation(.portrait)
            
            if #available(iOS 10.0, *) { tableView.prefetchDataSource = self }
            
            self.navigationItem.title = "Detail"
            tableView.allowsSelection = false
            
            instanceDetail = TwitterClient()
            tweetDetails = ViewModelTweet(viewModelTweet: tweet!)
            tweetDetails?.cellData.asObservable().subscribe(onNext: { [weak self] data in
                guard let s = self else { return }
                s.varietyCellAction(data: data)
            }).disposed(by: self.dis)
            tweetChain.append(tweetDetails!)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tableFooterView = UIView()
            reloadData(tweet: self.tweet!)
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            AppUtility.lockOrientation(.portrait)
            if tweetChain.count <= 1 {
                for (index, data) in DetailsVC.tweetIDforDetailsVC.enumerated() {
                    if let retweet = Profile.tweetID[data.0] {
                        DetailsVC.tweetIDforDetailsVC[index].1 = retweet
                    }
                    if let favorite = Profile.tweetIDForFavorite[data.0] {
                        DetailsVC.tweetIDforDetailsVC[index].2 = favorite
                    }
                }
            } else {
                DispatchQueue.global().async {
                    for (index, tweeTemp) in self.tweetChain.enumerated() {
                        if let id = Profile.tweetID[tweeTemp.tweetID] {
                            if !id, try! tweeTemp.retweetBtn.value() {
                                tweeTemp.retweetBtn.onNext(false)
                                let temp = try! tweeTemp.retweetCount.value() - 1
                                tweeTemp.retweetCount.onNext(temp)
                                if tweeTemp.retweetedType == "Retweeted by You" {
                                    tweeTemp.retweetedType = ""
                                    self.heightCell[index] = self.heightCell[index] - 12.0
                                }
                            } else if id, try! !tweeTemp.retweetBtn.value()  {
                                tweeTemp.retweetBtn.onNext(true)
                                let temp = try! tweeTemp.retweetCount.value() + 1
                                tweeTemp.retweetCount.onNext(temp)
                                tweeTemp.retweetedType = "Retweeted by You"
                                self.heightCell[index] = self.heightCell[index] + 12.0
                            }
                        }
                        if let id = Profile.tweetIDForFavorite[tweeTemp.tweetID] {
                            if !id, try! tweeTemp.favoriteBtn.value() {
                                tweeTemp.favoriteBtn.onNext(false)
                                let temp = try! tweeTemp.favoriteCount.value() - 1
                                tweeTemp.favoriteCount.onNext(temp)
                            } else if id, try! !tweeTemp.favoriteBtn.value() {
                                tweeTemp.favoriteBtn.onNext(true)
                                let temp = try! tweeTemp.favoriteCount.value() + 1
                                tweeTemp.favoriteCount.onNext(temp)
                            }
                        }
                    }
                    DispatchQueue.main.async { self.tableView.reloadData() }
                }
            }
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            if dataMediaScale != nil { dataMediaScale = nil }
        }
        
        func reloadData(tweet: ViewModelTweet) {
            if !tweet.replyConversation.isEmpty {
                let emptyTweet = ViewModelTweet(viewModelTweet: self.tweet!)
                emptyTweet.mediaImageURLs.removeAll()
                emptyTweet.checkEmptyTweet = true
                arrayConversation.insert(emptyTweet, at: 0)
                reloadDataConversation(tweetID: tweet.replyConversation)
            }
            self.myGroup.enter()
            let count = self.tweetChain.count
            instanceDetail?.repliesTweets(tweetOrigin: tweet, complited: { tweets in
                for x in tweets {
                    x.cellData.asObservable().subscribe(onNext: { [weak self] data in
                        guard let s = self else { return }
                        s.varietyCellAction(data: data)
                    }).disposed(by: self.dis)
                }
                self.tweetChain.append(contentsOf: tweets)
                var index = [IndexPath]()
                if self.tweetChain.count - count > 0 {
                    for i in count..<self.tweetChain.count {
                        let indexPath = IndexPath(row: i, section: 0)
                        index.append(indexPath)
                    }
                    self.tableView.performUpdate({ self.tableView.insertRows(at: index, with: .top) }, completion: {
                        self.myGroup.leave()
                    })
                    
                } else {
                    self.myGroup.leave()
                }
            })
            myGroup.notify(queue: .main) {
                if self.isMoreDataLoading.move {
                    if self.arrayConversation.count > 1 {
                        let sum = self.heightCell.reduce(0, +)
                        self.arrayConversation.forEach {_ in self.heightCell.insert(0.0, at: 0)}
                        let realEstateHeight = self.tableView.frame.size.height - 64.0 - 49.0
                        if realEstateHeight - sum > 0 {
                            self.tableView.contentInset.bottom = self.tableView.frame.size.height - (sum + 64.0)
                        }
                        self.tweetChain.insert(contentsOf: self.arrayConversation, at: 0)
                        var ind = [IndexPath]()
                        for x in 0..<self.arrayConversation.count {
                            let index = IndexPath(item: x, section: 0)
                            ind.append(index)
                        }
                        UIView.setAnimationsEnabled(false)
                        self.tableView.beginUpdates()
                        self.tableView.insertRows(at: ind, with: .none)
                        self.tableView.endUpdates()
                        UIView.setAnimationsEnabled(true)
                        
                        let sumTemp = self.heightCell.reduce(0, +)
                        let delta = sumTemp - sum
                        self.tableView.contentOffset.y = delta - 64.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                            self.tableView.setContentOffset(CGPoint(x: 0.0, y: (delta - 64.0) - 25.0 ), animated: true)
                            self.tableView.reloadData()
                        })
                    }
                    self.isMoreDataLoading = (false, false)
                } else { self.isMoreDataLoading.download = true }
            }
        }
        
        func reloadDataConversation(tweetID: String) {
            self.myGroup.enter()
            instanceDetail?.getDataConversation(tweetID: tweetID, complited: { data in
                if let twee = data {
                    twee.cellData.asObservable().subscribe(onNext: { [weak self] data in
                        guard let s = self else { return }
                        s.varietyCellAction(data: data)
                    }).disposed(by: self.dis)
                    self.arrayConversation.insert(twee, at: 0)
                    if !twee.replyConversation.isEmpty {
                        self.reloadDataConversation(tweetID: twee.replyConversation)
                    }
                }
                self.myGroup.leave()
            })
        }
        
        func varietyCellAction(data: CellData) {
            switch data {
            case let .RetweetForDetails(index, btn):
                if quoteTap {
                    self.tweet?.retweetBtn.onNext(try! tweetChain[index.row].retweetBtn.value())
                    self.tweet?.retweetCount.onNext(try! tweetChain[index.row].retweetCount.value())
                    self.tweet?.favoriteBtn.onNext(try! tweetChain[index.row].favoriteBtn.value())
                    self.tweet?.favoriteCount.onNext(try! tweetChain[index.row].favoriteCount.value())
                }
                var countRetweets = 1
                var countFavorites = 1
                if let count = try? tweetChain[index.row].retweetCount.value() {
                    countRetweets = count
                }
                if let count = try? tweetChain[index.row].favoriteCount.value() {
                    countFavorites = count
                }
                if countRetweets == 0 && countFavorites == 0 {
                    self.heightCell[index.row] = self.heightCell[index.row] - 12.0
                }
                if countFavorites == 1 && countRetweets == 1 {
                    self.tableView.reloadRows(at: [index], with: .none)
                }
                if countFavorites == 1, countRetweets == 0, tweetChain[index.row].favorited, btn == "favorite" {
                    self.heightCell[index.row] = self.heightCell[index.row] + 12.0
                    self.tableView.reloadRows(at: [index], with: .none)
                }
                if countRetweets == 1, countFavorites == 0, tweetChain[index.row].retweeted, btn == "retweet" {
                    self.heightCell[index.row] = self.heightCell[index.row] + 12.0
                    self.tableView.reloadRows(at: [index], with: .none)
                }
                if countFavorites == 0 || countRetweets == 0 {
                    self.tableView.reloadRows(at: [index], with: .none)
                }
            case let .Retweet(index):
                if tweetChain[index.row].retweetedType == "Retweeted by You" {
                    heightCell[index.row] = heightCell[index.row] + 12.0
                    // for fixed retweet mark in Replies on tweet
                    saveStatusBtn(tweet: tweetChain[index.row], data: ("r", true))
                } else if tweetChain[index.row].retweetedType == "" {
                    heightCell[index.row] = heightCell[index.row] - 12.0
                    saveStatusBtn(tweet: tweetChain[index.row], data: ("r", false))
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [index], with: .none)
                    self.tableView.endUpdates()
                })
            //DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){ self.tableView.reloadRows(at: [index], with: .none) }
            case let .Reply(twee, modal, replyAll):
                print(data)
                if modal {
                    let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
                    controller.transitioningDelegate = self
                    controller.modalPresentationStyle = .custom
                    controller.variety = VarietyModally.reply
                    controller.tweet = twee
                    present(controller, animated: true, completion: nil)
                    controller.thirdBtn.setImage(UIImage(named: "btnModalyReply"), for: .normal)
                    controller.secondBtn.setImage(UIImage(named: "btnModalyReplyToAll"), for: .normal)
                } else {
                    if !replyAll {
                        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ReplyAndNewTweet") as! UINavigationController
                        if let controller = storyboard.viewControllers.first as? ReplyAndNewTweetVC {
                            controller.userReply = twee
                            self.present(storyboard, animated: true, completion: nil)
                        }
                    } else {
                        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ReplyAndNewTweet") as! UINavigationController
                        if let controller = storyboard.viewControllers.first as? ReplyAndNewTweetVC {
                            controller.userReply = twee
                            var user = [String]()
                            if twee.retweetTweetID != nil {
                                user.append("@\(twee.retweetedScreenName)")
                            }
                            if twee.userMentions.count > 0 {
                                user.append(contentsOf: twee.userMentions)
                            }
                            controller.user = Set(user)
                            self.present(storyboard, animated: true, completion: nil)
                        }
                    }
                }
            case let .Settings(index, twee, delete, viewDetail, viewRetweets, modal):
                if modal {
                    if twee.userScreenName == Profile.account.screenNameAt {
                        let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
                        controller.transitioningDelegate = self
                        controller.modalPresentationStyle = .custom
                        controller.tweet = twee
                        controller.index = index
                        controller.variety = index.row == 0 ? VarietyModally.settingsDetailOfMe : VarietyModally.settingsProfile
                        present(controller, animated: true, completion: nil)
                        if index.row == 0 {
                            controller.thirdBtn.setImage(UIImage(named: "btnModalyDelete"), for: .normal)
                            controller.secondBtn.setImage(UIImage(named: "btnModalyShowRetweets"), for: .normal)
                        } else {
                            controller.fourthBtn.setImage(UIImage(named: "btnModalyDelete"), for: .normal)
                            controller.thirdBtn.setImage(UIImage(named: "btnModalyShowDetails"), for: .normal)
                            controller.secondBtn.setImage(UIImage(named: "btnModalyShowRetweets"), for: .normal)
                        }
                    } else {
                        let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
                        controller.transitioningDelegate = self
                        controller.modalPresentationStyle = .custom
                        controller.tweet = twee
                        controller.index = index
                        controller.variety = index.row == 0 ? VarietyModally.settingsDetail : VarietyModally.settings
                        present(controller, animated: true, completion: nil)
                        if index.row == 0 {
                            controller.secondBtn.setImage(UIImage(named: "btnModalyShowRetweets"), for: .normal)
                        } else {
                            controller.thirdBtn.setImage(UIImage(named: "btnModalyShowDetails"), for: .normal)
                            controller.secondBtn.setImage(UIImage(named: "btnModalyShowRetweets"), for: .normal)
                        }
                    }
                } else {
                    twee.settingsBtn.onNext(false)
                    switch true {
                    case delete:
                        if index.row == 0 {
                            _ = navigationController?.popViewController(animated: true)
                            self.tweet?.cellData.value = CellData.Settings(index: self.indexPath!, tweet: self.tweet!, delete: true, viewDetail: false, viewRetweets: false, modal: false)
                        } else {
                            TwitterClient.swifter.destroyTweet(forID: twee.tweetID)
                            self.tableView.beginUpdates()
                            self.heightCell.remove(at: index.row)
                            self.tweetChain.remove(at: index.row)
                            self.tableView.deleteRows(at: [index], with: .bottom)
                            self.tableView.endUpdates()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: { self.tableView.reloadData() })
                        }
                    case viewDetail:
                        let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "DetailsVC") as! DetailsVC
                        customAttributeForDetailsVC(tweet: twee, complete: { data in
                            controller.attributeText = data
                            controller.tweet = twee
                        })
                        SDWebImageManager.shared().loadImage(with: twee.userAvatar, progress: { (_, _, _) in }, completed: { (image, error, cache, _, _, _) in
                            twee.userPicImage.onNext(image!)
                        })
                        if let url = twee.mediaImageURLs.first {
                            SDWebImageManager.shared().loadImage(with: url, progress: { (_, _, _) in }, completed: { (image, error, cache, _, _, _) in
                                twee.image.onNext(image!)
                            })
                        }
                        self.navigationController?.pushViewController(controller, animated: true)
                    case viewRetweets:
                        let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "FollowersAndFollowingVC") as! FollowersAndFollowingVC
                        controller.tweetID = twee.tweetID
                        self.navigationController?.pushViewController(controller, animated: true)
                    default:
                        break
                    }
                }
            case let .MediaScale(index, convert):
                if let youTubeURL = self.tweetChain[index.row].youtubeURL {
                    let controller = SFSafariViewController(url: youTubeURL, entersReaderIfAvailable: true)
                    self.present(controller, animated: true, completion: nil)
                } else {
                    var frameCell = self.tableView.rectForRow(at: (index))
                    frameCell = CGRect(origin: CGPoint(x: frameCell.origin.x + convert.origin.x, y: frameCell.origin.y + convert.origin.y), size: convert.size)
                    let convertFinal: CGRect! = tableView.convert(frameCell, to: tableView.superview)
                    self.dataMediaScale = SomeTweetsData()
                    self.dataMediaScale?.convert = convertFinal
                    self.dataMediaScale?.image = try! self.tweetChain[index.row].image.value()
                    self.dataMediaScale?.indexPath = index
                    Profile.shotView = false
                    let controllerPhotoScale = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoScaleVC") as! PhotoScaleVC
                    controllerPhotoScale.transitioningDelegate = self
                    controllerPhotoScale.image = self.dataMediaScale?.image
                    if let url = self.tweetChain[index.row].videoURL {
                        self.dataMediaScale?.mediaTriangle = true
                        let convertFrameTriangle = CGRect(x: convertFinal.center.x  - 15.0, y: convertFinal.center.y - 15.0, width: 30.0, height: 30.0)
                        self.dataMediaScale?.frameVideoTriangle = convertFrameTriangle
                        controllerPhotoScale.urlVideo = url
                    }
                    if let url = self.tweetChain[index.row].instagramVideo {
                        self.dataMediaScale?.mediaTriangle = true
                        let convertFrameTriangle = CGRect(x: convertFinal.center.x  - 15.0, y: convertFinal.center.y - 15.0, width: 30.0, height: 30.0)
                        self.dataMediaScale?.frameVideoTriangle = convertFrameTriangle
                        controllerPhotoScale.urlVideo = url
                    }
                    if let url = self.tweetChain[index.row].instagramVideo {
                        self.dataMediaScale?.mediaTriangle = true
                        let convertFrameTriangle = CGRect(x: convertFinal.center.x  - 15.0, y: convertFinal.center.y - 15.0, width: 30.0, height: 30.0)
                        self.dataMediaScale?.frameVideoTriangle = convertFrameTriangle
                        controllerPhotoScale.urlVideo = url
                    }
                    present(controllerPhotoScale, animated: true, completion: nil)
                }
            case let .QuoteTap(tweet):
                let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "DetailsVC") as! DetailsVC
                customAttributeForDetailsVC(tweet: tweet, complete: { data in
                    controller.attributeText = data
                    controller.tweet = tweet
                    controller.quoteTap = true
                })
                SDWebImageManager.shared().loadImage(with: tweet.userAvatar, progress: { (_, _, _) in }, completed: { (image, error, cache, _, _, _) in
                    if image == nil {
                        let urlString = tweet.userAvatar.absoluteString
                        if urlString.contains("profile_images") {
                            let newUrl = urlString.replace(target: ".jpg", withString: "_bigger.jpg")
                            SDWebImageManager.shared().loadImage(with: URL(string: newUrl), progress: { (_, _, _) in
                            }) { (image, error, cache , _ , _, _) in
                                tweet.userPicImage.onNext(image!)
                            }
                        }
                    } else {
                        tweet.userPicImage.onNext(image!)
                    }
                })
                if let url = tweet.mediaImageURLs.first {
                    SDWebImageManager.shared().loadImage(with: url, progress: { (_, _, _) in }, completed: { (image, error, cache, _, _, _) in
                        tweet.image.onNext(image!)
                    })
                }
                self.navigationController?.pushViewController(controller, animated: true)
            case let .Safari(url):
                let controller = SFSafariViewController(url: URL(string: url)!, entersReaderIfAvailable: true)
                self.present(controller, animated: true, completion: nil)
            case let .UserPicTap(tweet):
                let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ProfileVC") as! ProfileVC
                tweet.user.userData = Variable<UserData>(UserData.tempValue(action: false))
                controller.user = tweet.user
                self.navigationController?.pushViewController(controller, animated: true)
            default:
                break
            }
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return tweetChain.count > 0 ? tweetChain.count : 1
            
        }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            var cells = UITableViewCell()
            if tweetChain[indexPath.row].tweetID == self.tweet?.tweetID, !tweetChain[indexPath.row].checkEmptyTweet {
                if !tweetDetails!.mediaImageURLs.isEmpty {
                    let cell = tableView.dequeueReusableCell(indexPath: indexPath) as DetailMediaCell
                    cell.tweetSetConfigure(tweet: tweetChain[indexPath.row])
                    cell.indexPath = indexPath
                    cell.delegate = self
                    cell.tweetContentText.attributedText = attributeText
                    if self.dataMediaScale?.indexPath == nil {
                        group.async {
                            self.fetchImageForCell(index: indexPath, data: self.tweetChain[indexPath.row])
                        }
                    }
                    cells = cell
                    
                } else {
                    let cell = tableView.dequeueReusableCell(indexPath: indexPath) as DetailCompactCell
                    cell.tweetSetConfigure(tweet: tweetChain[indexPath.row])
                    cell.indexPath = indexPath
                    cell.tweetContentText.attributedText = attributeText
                    group.async {
                        self.fetchImageForCell(index: indexPath, data: self.tweetChain[indexPath.row])
                    }
                    cells = cell
                }
            } else if tweetChain.count > 1 {
                if !tweetChain[indexPath.row].mediaImageURLs.isEmpty {
                    let cell = tableView.dequeueReusableCell(indexPath: indexPath) as MediaCell
                    cell.tweetSetConfigure(tweet: tweetChain[indexPath.row])
                    cell.indexPath = indexPath
                    cell.delegate = self
                    if self.dataMediaScale?.indexPath == nil {
                        group.async {
                            self.fetchImageForCell(index: indexPath, data: self.tweetChain[indexPath.row])
                        }
                    }
                    cells = cell
                } else if tweetChain[indexPath.row].checkEmptyTweet  {
                    let cell = tableView.dequeueReusableCell(indexPath: indexPath) as EmptyCellForConversation
                    cells = cell
                } else if tweetChain[indexPath.row].quote != nil {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "quoteCompact", for: indexPath) as! QuoteCell
                    cell.tweetSetConfigure(tweet: tweetChain[indexPath.row])
                    cell.indexPath = indexPath
                    cell.delegate = self
                    if !tweetChain[indexPath.row].quote!.mediaImageURLs.isEmpty {
                        cell.imageQuote.sd_setImage(with: tweetChain[indexPath.row].quote?.mediaImageURLs.first)
                    }
                    group.async {
                        self.fetchImageForCell(index: indexPath, data: self.tweetChain[indexPath.row])
                    }
                    cells = cell
                } else {
                    let cell = tableView.dequeueReusableCell(indexPath: indexPath) as CompactCell
                    cell.tweetSetConfigure(tweet: tweetChain[indexPath.row])
                    cell.indexPath = indexPath
                    cell.delegate = self
                    group.async {
                        self.fetchImageForCell(index: indexPath, data: self.tweetChain[indexPath.row])
                    }
                    cells = cell
                }
            }
            return cells
        }
        
        private func fetchImageForCell(index: IndexPath, data: ViewModelTweet) {
            if !data.mediaImageURLs.isEmpty {
                if let imageLoadOperation = imageLoadOperations[index], let imageLoadOperationMedia = imageLoadOperationsMedia[index] {
                    if imageLoadOperationMedia.image == nil {
                        imageLoadOperationsMedia[index]?.cancel()
                        imageLoadOperationsMedia.removeValue(forKey: index)
                        let imageLoadOperationMedia = ImageLoadOperation(url: data.mediaImageURLs.first!)
                        imageLoadOperationMedia.completionHandler = { [weak self] (image) in
                            guard let strongSelf = self else { return }
                            data.image.onNext(image)
                            strongSelf.imageLoadOperationsMedia.removeValue(forKey: index)
                        }
                        imageLoadQueue.addOperation(imageLoadOperationMedia)
                        imageLoadOperationsMedia[index] = imageLoadOperationMedia
                        
                    } else {
                        data.image.onNext(imageLoadOperationMedia.image!)
                    }
                    if imageLoadOperation.image == nil {
                        imageLoadOperations[index]?.cancel()
                        imageLoadOperations.removeValue(forKey: index)
                        let imageLoadOperation = ImageLoadOperation(url: data.userAvatar)
                        imageLoadOperation.completionHandler = { [weak self] (image) in
                            guard let strongSelf = self else { return }
                            data.userPicImage.onNext(image)
                            strongSelf.imageLoadOperations.removeValue(forKey: index)
                        }
                        imageLoadQueue.addOperation(imageLoadOperation)
                        imageLoadOperations[index] = imageLoadOperation
                        
                    } else {
                        data.userPicImage.onNext(imageLoadOperation.image!)
                    }
                } else {
                    let imageLoadOperation = ImageLoadOperation(url: data.userAvatar)
                    imageLoadOperation.completionHandler = { [weak self] (image) in
                        guard let strongSelf = self else { return }
                        data.userPicImage.onNext(image)
                        strongSelf.imageLoadOperations.removeValue(forKey: index)
                    }
                    imageLoadQueue.addOperation(imageLoadOperation)
                    imageLoadOperations[index] = imageLoadOperation
                    
                    let imageLoadOperationMedia = ImageLoadOperation(url: data.mediaImageURLs.first!)
                    imageLoadOperationMedia.completionHandler = { [weak self] (image) in
                        guard let strongSelf = self else { return }
                        data.image.onNext(image)
                        strongSelf.imageLoadOperationsMedia.removeValue(forKey: index)
                    }
                    imageLoadQueue.addOperation(imageLoadOperationMedia)
                    imageLoadOperationsMedia[index] = imageLoadOperationMedia
                }
            } else {
                if let imageLoadOperation = imageLoadOperations[index], let image = imageLoadOperation.image {
                    data.userPicImage.onNext(image)
                } else {
                    let imageLoadOperation = ImageLoadOperation(url: data.userAvatar)
                    imageLoadOperation.completionHandler = { [weak self] (image) in
                        guard let strongSelf = self else { return }
                        DispatchQueue.main.async {
                            data.userPicImage.onNext(image)
                        }
                        
                        strongSelf.imageLoadOperations.removeValue(forKey: index)
                    }
                    imageLoadQueue.addOperation(imageLoadOperation)
                    imageLoadOperations[index] = imageLoadOperation
                }
            }
        }
        
        private func customAttributeForDetailsVC(tweet: ViewModelTweet, complete: @escaping (_ data: NSMutableAttributedString) -> ()) {
            let text = tweet.text
            let attribute = NSMutableAttributedString(attributedString: text)
            attribute.beginEditing()
            attribute.enumerateAttribute(NSAttributedString.Key(rawValue: convertFromNSAttributedStringKey(NSAttributedString.Key.font)), in: NSRange(location: 0, length: text.length), using: { (value, range, stop) in
                if let oldFont = value as? UIFont {
                    let newFont = oldFont.withSize(14.5)
                    attribute.removeAttribute(NSAttributedString.Key.font, range: range)
                    attribute.addAttribute(NSAttributedString.Key.font, value: newFont, range: range)
                }
            })
            attribute.endEditing()
            complete(attribute)
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            self.isMoreDataLoading.move = false
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            perform(#selector(UIScrollViewDelegate.scrollViewDidEndScrollingAnimation), with: nil, afterDelay: 0.3)
        }
        
        func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            self.isMoreDataLoading.move = true
            if self.isMoreDataLoading == (true, true) {
                if self.arrayConversation.count > 1 {
                    let sum = self.heightCell.reduce(0, +)
                    self.arrayConversation.forEach {_ in self.heightCell.insert(0.0, at: 0)}
                    let realEstateHeight = self.tableView.frame.size.height - 64.0 - 49.0
                    if realEstateHeight - sum > 0 {
                        self.tableView.contentInset.bottom = self.tableView.frame.size.height - (sum + 64.0)
                    }
                    self.tweetChain.insert(contentsOf: self.arrayConversation, at: 0)
                    var ind = [IndexPath]()
                    for x in 0..<self.arrayConversation.count {
                        let index = IndexPath(item: x, section: 0)
                        ind.append(index)
                    }
                    UIView.setAnimationsEnabled(false)
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: ind, with: .none)
                    self.tableView.endUpdates()
                    UIView.setAnimationsEnabled(true)
                    
                    let sumTemp = self.heightCell.reduce(0, +)
                    let delta = sumTemp - sum
                    self.tableView.contentOffset.y = delta - 64.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                        self.tableView.setContentOffset(CGPoint(x: 0.0, y: (delta - 64.0) - 25.0 ), animated: true)
                        self.tableView.reloadData()
                    })
                }
                self.isMoreDataLoading = (false, false)
            }
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            let row = indexPath.row
            let count = heightCell.count
            if row < count, heightCell[row] != 0.0 {
                return heightCell[row]
            } else {
                if tweetChain.count == 0 { return 0.0 }
                let tweetHeight = tweetChain[indexPath.row]
                if self.tweetChain.count == 1 {
                    if !tweetHeight.mediaImageURLs.isEmpty {
                        let object = UINib(nibName: "DetailMedia", bundle: nil).instantiate(withOwner: nil)
                        let cell = object.first as! DetailMediaCell
                        let initialSizeTextLbl = cell.tweetContentText.frame.size
                        let rect = attributeText!.boundingRect(with:  CGSize(width: initialSizeTextLbl.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                        let viewContent = cell.contentView
                        var delta: CGFloat = 0.0
                        let retweetCount = try! tweetHeight.retweetCount.value()
                        let favoriteCount = try! tweetHeight.favoriteCount.value()
                        if retweetCount == 0 && favoriteCount == 0 { delta = 14.0 }
                        let size = viewContent.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                        let finaleSize = size.height + ceil(rect.size.height) + 1.0 - delta
                        if row < count {
                            heightCell.insert(finaleSize, at: row)
                        } else {
                            heightCell.append(finaleSize)
                        }
                        return finaleSize
                    } else {
                        let object = UINib(nibName: "DetailCompact", bundle: nil).instantiate(withOwner: nil)
                        let cell = object.first as! DetailCompactCell
                        let initialSizeTextLbl = cell.tweetContentText.frame.size
                        let rect = attributeText!.boundingRect(with:  CGSize(width: initialSizeTextLbl.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                        let viewContent = cell.contentView
                        var delta: CGFloat = 0.0
                        let retweetCount = try! tweetHeight.retweetCount.value()
                        let favoriteCount = try! tweetHeight.favoriteCount.value()
                        if retweetCount == 0 && favoriteCount == 0 { delta = 14.0 }
                        let size = viewContent.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                        let finaleSize: CGFloat = size.height + ceil(rect.size.height) + 1.0 - delta
                        if row < count {
                            heightCell[row] = finaleSize
                        } else {
                            heightCell.append(finaleSize)
                        }
                        return finaleSize
                        
                    }
                } else if tweetChain[row].checkEmptyTweet {
                    heightCell[row] = 25.0
                    return 25.0
                } else {
                    if !tweetHeight.mediaImageURLs.isEmpty {
                        let object = UINib(nibName: "Media", bundle: nil).instantiate(withOwner: nil)
                        let cell = object.first as! MediaCell
                        let initialSizeTextLbl = cell.tweetContentText.frame.size
                        let rect = tweetHeight.text.boundingRect(with:  CGSize(width: initialSizeTextLbl.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                        let viewContent = cell.contentView
                        let size = viewContent.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                        let finaleSize: CGFloat
                        if tweetHeight.retweetedType.isEmpty {
                            finaleSize = size.height + ceil(rect.size.height) - 12.0 + 1.0
                        } else {
                            finaleSize = size.height + ceil(rect.size.height) + 1.0
                        }
                        if row < count {
                            heightCell[row] = finaleSize
                        } else {
                            heightCell.append(finaleSize)
                        }
                        return finaleSize
                    } else if tweetHeight.quote != nil {
                        let object = UINib(nibName: "Quote", bundle: nil).instantiate(withOwner: nil)
                        let cell = object.first as! QuoteCell
                        let initialSizeTextLbl = cell.tweetContentText.frame.size
                        let rect = tweetHeight.text.boundingRect(with:  CGSize(width: initialSizeTextLbl.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                        
                        let sizeQuoteTextLbl: CGFloat
                        if !tweetHeight.quote!.mediaImageURLs.isEmpty {
                            sizeQuoteTextLbl = 4.0 + 60.0
                        } else {
                            let rectQuote = tweetHeight.quote!.text.boundingRect(with:  CGSize(width: cell.textQuote.frame.size.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                            sizeQuoteTextLbl = ceil(rectQuote.size.height) + 1.0
                        }
                        let viewContent = cell.contentView
                        let size = viewContent.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                        let finaleSize: CGFloat
                        if tweetHeight.retweetedType.isEmpty {
                            finaleSize = size.height + ceil(rect.size.height) - 12.0 + 1.0 + sizeQuoteTextLbl
                        } else {
                            finaleSize = size.height + ceil(rect.size.height) + 1.0 + sizeQuoteTextLbl
                        }
                        if row < count {
                            heightCell[row] = finaleSize
                        } else {
                            heightCell.append(finaleSize)
                        }
                        return finaleSize
                        
                    } else {
                        let object = UINib(nibName: "Compact", bundle: nil).instantiate(withOwner: nil)
                        let cell = object.first as! CompactCell
                        let initialSizeTextLbl = cell.tweetContentText.frame.size
                        let rect = tweetHeight.text.boundingRect(with:  CGSize(width: initialSizeTextLbl.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                        let viewContent = cell.contentView
                        let size = viewContent.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                        let finaleSize: CGFloat
                        if tweetHeight.retweetedType.isEmpty {
                            finaleSize = size.height + ceil(rect.size.height) - 12.0 + 1.0
                        } else {
                            finaleSize = size.height + ceil(rect.size.height) + 1.0
                        }
                        if row < count {
                            heightCell[row] = finaleSize
                        } else {
                            heightCell.append(finaleSize)
                        }
                        return finaleSize
                    }
                }
            }
        }
        
        func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
            if tweetChain.count == 0 { return }
            for indexPath in indexPaths {
                if let _ = imageLoadOperations[indexPath], let _ = imageLoadOperationsMedia[indexPath] { continue }
                if let _ = imageLoadOperations[indexPath] { continue }
                
                if self.tweetChain[indexPath.row].mediaImageURLs.isEmpty {
                    let imageLoadOperation = ImageLoadOperation(url: self.tweetChain[indexPath.row].userAvatar)
                    imageLoadQueue.addOperation(imageLoadOperation)
                    imageLoadOperations[indexPath] = imageLoadOperation
                } else {
                    let imageLoadOperation = ImageLoadOperation(url: self.tweetChain[indexPath.row].userAvatar)
                    imageLoadQueue.addOperation(imageLoadOperation)
                    imageLoadOperations[indexPath] = imageLoadOperation
                    
                    let imageMedia = ImageLoadOperation(url: self.tweetChain[indexPath.row].mediaImageURLs.first!)
                    imageLoadQueue.addOperation(imageMedia)
                    imageLoadOperationsMedia[indexPath] = imageMedia
                }
                
                guard let tweet = tweetChain[indexPath.row].quote else { continue }
                if !tweet.mediaImageURLs.isEmpty {
                    SDWebImagePrefetcher.shared().prefetchURLs([tweet.mediaImageURLs.first!])
                }
                
                #if DEBUG_CELL_LIFECYCLE
                    print(String.init(format: "prefetchRowsAt #%i", indexPath.row))
                #endif
            }
        }
        
        func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
            for indexPath in indexPaths {
                if let _ = imageLoadOperations[indexPath], let _ = imageLoadOperationsMedia[indexPath] {
                    imageLoadOperations[indexPath]!.cancel()
                    imageLoadOperations.removeValue(forKey: indexPath)
                    imageLoadOperationsMedia[indexPath]!.cancel()
                    imageLoadOperationsMedia.removeValue(forKey: indexPath)
                } else if let _ = imageLoadOperations[indexPath] {
                    imageLoadOperations[indexPath]!.cancel()
                    imageLoadOperations.removeValue(forKey: indexPath)
                }
                #if DEBUG_CELL_LIFECYCLE
                    print(String.init(format: "cancelPrefetchingForRowsAt #%i", indexPath.row))
                #endif
            }
        }
        
        func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            if self.dataMediaScale == nil {
                guard let imageLoadOperation = imageLoadOperations[indexPath] else { return }
                imageLoadOperation.cancel()
                imageLoadOperations.removeValue(forKey: indexPath)
                
                guard let imageimageMedia = imageLoadOperationsMedia[indexPath] else { return }
                imageimageMedia.cancel()
                imageLoadOperationsMedia.removeValue(forKey: indexPath)
                
                #if DEBUG_CELL_LIFECYCLE
                    print(String.init(format: "didEndDisplaying #%i", indexPath.row))
                #endif
            }
        }
        
        
        func profileVC(tweet: ViewModelTweet?, someTweetsData: SomeTweetsData?) {
            if let indexTweet = someTweetsData?.indexPath, let check = someTweetsData?.switchBool {
                // for fixed favorite mark in Replies on tweet
                saveStatusBtn(tweet: tweetChain[indexTweet.row], data: ("f", check))
            }
            guard let convert = someTweetsData?.convert, let index = someTweetsData?.indexPath else { return }
            if let youTubeURL = self.tweetChain[index.row].youtubeURL {
                let controller = SFSafariViewController(url: youTubeURL, entersReaderIfAvailable: true)
                self.present(controller, animated: true, completion: nil)
            } else {
                var frameCell = self.tableView.rectForRow(at: (index))
                frameCell = CGRect(origin: CGPoint(x: frameCell.origin.x + convert.origin.x, y: frameCell.origin.y + convert.origin.y), size: convert.size)
                let convertFinal: CGRect! = tableView.convert(frameCell, to: tableView.superview)
                self.dataMediaScale = SomeTweetsData()
                self.dataMediaScale?.convert = convertFinal
                self.dataMediaScale?.image = try! self.tweetChain[index.row].image.value()
                self.dataMediaScale?.indexPath = index
                Profile.shotView = false
                let controllerPhotoScale = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoScaleVC") as! PhotoScaleVC
                controllerPhotoScale.transitioningDelegate = self
                controllerPhotoScale.image = self.dataMediaScale?.image
                if let url = self.tweetChain[index.row].videoURL {
                    self.dataMediaScale?.mediaTriangle = true
                    let convertFrameTriangle = CGRect(x: convertFinal.center.x  - 15.0, y: convertFinal.center.y - 15.0, width: 30.0, height: 30.0)
                    self.dataMediaScale?.frameVideoTriangle = convertFrameTriangle
                    controllerPhotoScale.urlVideo = url
                }
                if let url = self.tweetChain[index.row].instagramVideo {
                    self.dataMediaScale?.mediaTriangle = true
                    let convertFrameTriangle = CGRect(x: convertFinal.center.x  - 15.0, y: convertFinal.center.y - 15.0, width: 30.0, height: 30.0)
                    self.dataMediaScale?.frameVideoTriangle = convertFrameTriangle
                    controllerPhotoScale.urlVideo = url
                }
                present(controllerPhotoScale, animated: true, completion: nil)
            }
        }
        
        private func saveStatusBtn(tweet: ViewModelTweet, data: (String, Bool)) {
            DispatchQueue.global().async {
                var checkBool = false
                for (index, x) in DetailsVC.tweetIDforDetailsVC.enumerated() {
                    if x.0 == tweet.tweetID {
                        if data.0 == "r" {
                            DetailsVC.tweetIDforDetailsVC[index].1 = data.1
                        } else {
                            DetailsVC.tweetIDforDetailsVC[index].2 = data.1
                        }
                        checkBool = true
                    }
                }
                if !checkBool {
                    if data.0 == "r" {
                        DetailsVC.tweetIDforDetailsVC.insert((tweet.tweetID, data.1, false), at: 0)
                    } else {
                        DetailsVC.tweetIDforDetailsVC.insert((tweet.tweetID, false, data.1), at: 0)
                    }
                }
                if DetailsVC.tweetIDforDetailsVC.count > 10 { DetailsVC.tweetIDforDetailsVC.removeLast() }
            }
        }
    }
    
    extension DetailsVC: UIViewControllerTransitioningDelegate {
        
        func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
            let presentationController = SlideInPresentationController(presentedViewController: presented, presenting: presenting, finalSize: true)
            return presentationController
        }
        
        func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            if let dataTemp = dataMediaScale {
                let photoViewController = presented as! PhotoScaleVC
                let alphaVariety = "up"
                animationController.setupImageTransition(data: dataTemp, fromDelegate: self, toDelegate: photoViewController, alphaTabs: alphaVariety)
                return animationController
            } else {
                return SlideInPresentationAnimator(isPresentation: true)
            }
        }
        
        func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            if let dataTemp = dataMediaScale {
                let photoViewController = dismissed as! PhotoScaleVC
                let alphaVariety = "down"
                animationController.setupImageTransition(data: dataTemp, fromDelegate: photoViewController, toDelegate: self, alphaTabs: alphaVariety)
                return animationController
            } else {
                return SlideInPresentationAnimator(isPresentation: false)
            }
        }
    }
    
    extension DetailsVC: ImageTransitionProtocol {
        
        func tranisitionSetup() {
            if let data = self.dataMediaScale {
                tweetChain[data.indexPath!.row].image.onNext(UIImage.getEmptyImageWithColor(color: UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1.0)))
            }
        }
        
        func tranisitionCleanup() {
            if let data = self.dataMediaScale, let index = data.indexPath {
                tweetChain[index.row].image.onNext(data.image!)
            }
        }
        
        func imageWindowFrame() -> CGRect { return (dataMediaScale?.convert)! }
    }
    

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
