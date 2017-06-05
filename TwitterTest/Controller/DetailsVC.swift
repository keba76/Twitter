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
    
    class DetailsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching, TwitterTableViewDelegate {
        
        @IBOutlet weak var tableView: UITableView!
        
        let dis = DisposeBag()
        
        var animationController: AnimationController = AnimationController()
        var dataMediaScale: SomeTweetsData?
        
        var tweet: ViewModelTweet?
        var tweetDetails: ViewModelTweet?
        var tweetChain = [ViewModelTweet]()
        var instanceDetail: TwitterClient?
        
        var heightCell = Array<CGFloat>()
        var attributeText: NSMutableAttributedString?
        static var tweetIDforDetailsVC = Array<(String, Bool, Bool)>()
        
        fileprivate let imageLoadQueue = OperationQueue()
        fileprivate var imageLoadOperations = [IndexPath: ImageLoadOperation]()
        fileprivate var imageLoadOperationsMedia = [IndexPath: ImageLoadOperation]()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            if #available(iOS 10.0, *) { tableView.prefetchDataSource = self }
            
            self.navigationItem.title = "Detail"
            tableView.allowsSelection = false
            
            instanceDetail = TwitterClient()
            tweetDetails = ViewModelTweet(viewModelTweet: tweet!)
            tweetDetails?.cellData.asObservable().subscribe(onNext: { [weak self] data in
                guard let s = self else { return }
                s.varietyCellAction(data: data)
            }).addDisposableTo(self.dis)
            tweetChain.append(tweetDetails!)
            tableView.delegate = self
            tableView.dataSource = self
            if !tweetDetails!.mediaImageURLs.isEmpty { tableView.contentInset.top -= 60.0 }
            tableView.tableFooterView = UIView()
            
            reloadData()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
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
        
        func reloadData() {
            instanceDetail?.repliesTweets(tweetOrigin: tweet!, complited: { tweets in
                for x in tweets {
                    x.cellData.asObservable().subscribe(onNext: { [weak self] data in
                        guard let s = self else { return }
                        s.varietyCellAction(data: data)
                    }).addDisposableTo(self.dis)
                }
                self.tweetChain.append(contentsOf: tweets)
                var index = [IndexPath]()
                if self.tweetChain.count > 1 {
                    for i in 1..<self.tweetChain.count {
                        let indexPath = IndexPath(row: i, section: 0)
                        index.append(indexPath)
                    }
                }
                self.tableView.insertRows(at: index, with: .top)
            })
        }
        
        func varietyCellAction(data: CellData) {
            switch data {
            case let .Retweet(index):
                if index.row > 0 {
                    print(data)
                    if tweetChain[index.row].retweetedType == "Retweeted by You" {
                        heightCell[index.row] = heightCell[index.row] + 12.0
                        // for fixed retweet mark in Replies on tweet
                        saveStatusBtn(tweet: tweetChain[index.row], data: ("r", true))
                    } else if tweetChain[index.row].retweetedType == "" {
                        heightCell[index.row] = heightCell[index.row] - 12.0
                        saveStatusBtn(tweet: tweetChain[index.row], data: ("r", false))
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.tableView.reloadRows(at: [index], with: .none) }
                }
            case let .Reply(twee, modal, replyAll):
                print(data)
                if modal {
                    let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
                    controller.transitioningDelegate = self
                    controller.modalPresentationStyle = .custom
                    controller.variety = VarietyModally.reply
                    controller.tweet = twee
                    present(controller, animated: true, completion: nil)
                    controller.thirdBtn.setImage(UIImage(named: "replyBtn"), for: .normal)
                    controller.secondBtn.setImage(UIImage(named: "replyToAllBtn"), for: .normal)
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
            case let .MediaScale(index, convert):
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
                present(controllerPhotoScale, animated: true, completion: nil)
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
            if indexPath.row == 0 {
                if !tweetDetails!.mediaImageURLs.isEmpty {
                    let cell = tableView.dequeueReusableCell(indexPath: indexPath) as DetailMediaCell
                    cell.tweetSetConfigure(tweet: tweetChain[indexPath.row])
                    cell.indexPath = indexPath
                    cell.delegate = self
                    cell.tweetContentText.attributedText = attributeText
                    cells = cell
                    
                } else {
                    let cell = tableView.dequeueReusableCell(indexPath: indexPath) as DetailCompactCell
                    cell.tweetSetConfigure(tweet: tweetChain[indexPath.row])
                    cell.indexPath = indexPath
                    cell.tweetContentText.attributedText = attributeText
                    cells = cell
                }
            }
            if tweetChain.count > 1 && indexPath.row != 0 {
                if !tweetChain[indexPath.row].mediaImageURLs.isEmpty {
                    let cell = tableView.dequeueReusableCell(indexPath: indexPath) as MediaCell
                    cell.tweetSetConfigure(tweet: tweetChain[indexPath.row])
                    cell.indexPath = indexPath
                    cell.delegate = self
                    if self.dataMediaScale?.indexPath == nil {
                        fetchImageForCell(index: indexPath, data: tweetChain[indexPath.row])
                    }
                    cells = cell
                    
                } else {
                    let cell = tableView.dequeueReusableCell(indexPath: indexPath) as CompactCell
                    cell.tweetSetConfigure(tweet: tweetChain[indexPath.row])
                    cell.indexPath = indexPath
                    cell.delegate = self
                    fetchImageForCell(index: indexPath, data: tweetChain[indexPath.row])
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
                        data.userPicImage.onNext(image)
                        strongSelf.imageLoadOperations.removeValue(forKey: index)
                    }
                    imageLoadQueue.addOperation(imageLoadOperation)
                    imageLoadOperations[index] = imageLoadOperation
                }
            }
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            let row = indexPath.row
            let count = heightCell.count
            if row < count {
                return heightCell[row]
            } else {
                if tweetChain.count == 0 { return 0.0 }
                let tweetHeight = tweetChain[indexPath.row]
                if indexPath.row == 0 {
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
                        let size = viewContent.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
                        let finaleSize = size.height + ceil(rect.size.height) + 1.0 - delta
                        heightCell.append(finaleSize)
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
                        let size = viewContent.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
                        let finaleSize: CGFloat = size.height + ceil(rect.size.height) + 1.0 - delta
                        heightCell.append(finaleSize)
                        return finaleSize
                        
                    }
                } else {
                    if !tweetHeight.mediaImageURLs.isEmpty {
                        let object = UINib(nibName: "Media", bundle: nil).instantiate(withOwner: nil)
                        let cell = object.first as! MediaCell
                        let initialSizeTextLbl = cell.tweetContentText.frame.size
                        let rect = tweetHeight.text.boundingRect(with:  CGSize(width: initialSizeTextLbl.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                        let viewContent = cell.contentView
                        let size = viewContent.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
                        let finaleSize: CGFloat
                        if tweetHeight.retweetedType.isEmpty {
                            finaleSize = size.height + ceil(rect.size.height) - 12.0 + 1.0
                        } else {
                            finaleSize = size.height + ceil(rect.size.height) + 1.0
                        }
                        heightCell.append(finaleSize)
                        return finaleSize
                    } else {
                        let object = UINib(nibName: "Compact", bundle: nil).instantiate(withOwner: nil)
                        let cell = object.first as! CompactCell
                        let initialSizeTextLbl = cell.tweetContentText.frame.size
                        let rect = tweetHeight.text.boundingRect(with:  CGSize(width: initialSizeTextLbl.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                        let viewContent = cell.contentView
                        let size = viewContent.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
                        let finaleSize: CGFloat
                        if tweetHeight.retweetedType.isEmpty {
                            finaleSize = size.height + ceil(rect.size.height) - 12.0 + 1.0
                        } else {
                            finaleSize = size.height + ceil(rect.size.height) + 1.0
                        }
                        heightCell.append(finaleSize)
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
                #if DEBUG_CELL_LIFECYCLE
                    print(String.init(format: "prefetchRowsAt #%i", indexPath.row))
                #endif
            }
        }
        
        func profileVC(tweet: ViewModelTweet?, someTweetsData: SomeTweetsData?) {
            if let indexTweet = someTweetsData?.indexPath, let check = someTweetsData?.switchBool {
                // for fixed favorite mark in Replies on tweet
                saveStatusBtn(tweet: tweetChain[indexTweet.row], data: ("f", check))
            }
            guard let convert = someTweetsData?.convert, let index = someTweetsData?.indexPath else { return }
            var frameCell = self.tableView.rectForRow(at: (index))
            frameCell = CGRect(origin: CGPoint(x: frameCell.origin.x + convert.origin.x, y: frameCell.origin.y + convert.origin.y), size: convert.size)
            let convertFinal: CGRect! = tableView.convert(frameCell, to: tableView.superview)
            self.dataMediaScale = SomeTweetsData()
            self.dataMediaScale?.convert = convertFinal
            self.dataMediaScale?.image = try! self.tweetChain[index.row].image.value()
            self.dataMediaScale?.indexPath = index
            self.dataMediaScale?.cornerRadius = false
            Profile.shotView = false
            
            let controllerPhotoScale = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoScaleVC") as! PhotoScaleVC
            controllerPhotoScale.transitioningDelegate = self
            controllerPhotoScale.image = self.dataMediaScale?.image
            present(controllerPhotoScale, animated: true, completion: nil)
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
    
