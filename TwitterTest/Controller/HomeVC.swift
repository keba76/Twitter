//
//  HomeVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/13/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift
import SafariServices
import SDWebImage

struct Profile {
    static var account: ModelUser?
    static var arrayIdFollowers = [JSON]()
    static var startTimeLine: [ViewModelTweet]?
    static var reloadingProfileTweetsWhenRetweet = 0
    static var reloadingProfileTweetsWhenReply = 0
    static var profileAccount = false
    static var shotView = false
    static var tweetID = Dictionary<String, Bool>()
    static var tweetIDForFavorite = Dictionary<String, Bool>()
    static var markerForReset = false
}

struct SomeTweetsData {
    var convert: CGRect?
    var indexPath: IndexPath?
    var image: UIImage?
    var scaleAvatarImage = false
    var scaleBanner = false
    var frameImage: CGRect?
    var frameBackImage = CGRect.zero
    var secondImageForBanner: UIImage?
    var cornerRadius = true
    var switchBool: Bool?
    
    init(){}
    
    init(convert: CGRect? = nil, indexPath: IndexPath? = nil, image: UIImage? = nil, scaleAvatarImage: Bool = false, scaleBanner: Bool = false, frameImage: CGRect? = nil, frameBackImage: CGRect = CGRect.zero, secondImageForBanner: UIImage? = nil, switchBool: Bool? = nil) {
        
        self.convert = convert
        self.indexPath = indexPath
        self.image = image
        self.scaleAvatarImage = scaleAvatarImage
        self.scaleBanner = scaleBanner
        self.frameImage = frameImage
        self.frameBackImage = frameBackImage
        self.secondImageForBanner = secondImageForBanner
        self.switchBool = switchBool
    }
}

final class HomeVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, SegueHandlerType {
    
    enum SegueIdentifier: String {
        case DetailsVCText
        case DetailsVCMedia
        case DetailsVCQuote
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var heightCell = Array<CGFloat>()
    
    var animationController: AnimationController = AnimationController()
    var dataMediaScale: SomeTweetsData?
    
    var instance: TwitterClient?
    let dis = DisposeBag()
    
    fileprivate let imageLoadQueue = OperationQueue()
    fileprivate var imageLoadOperations = [IndexPath: ImageLoadOperation]()
    fileprivate var imageLoadOperationsMedia = [IndexPath: ImageLoadOperation]()
    
    var refreshControler: CBStoreHouseRefreshControl?
    var tempTweetArray: [ViewModelTweet]?
    var tweetViewConstraints: NSLayoutConstraint?
    var newTweetsLbl: UILabel?
    var myView: UIView?
    var indexRefresh = 0
    var positionRefresh = false
    
    var loadingMoreTweets: NVActivityIndicatorView?
    var loadingView: UIView?
    var stopOffset = false
    var isMoreDataLoading = (start: false, finish: false, download: false)
    
    var lastTweetID: String?
    var tweet: [ViewModelTweet]? {
        didSet { lastTweetID = tweet?.last?.lastTweetID }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 10.0, *) { tableView.prefetchDataSource = self }
        
        let buttonReply = UIBarButtonItem(image: UIImage(named: "composetweet2"), style: .plain, target: self, action: #selector(self.barbuttonReply))
        self.navigationItem.rightBarButtonItem  = buttonReply
        let buttonInfo = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.barbuttonInfo))
        self.navigationItem.leftBarButtonItem = buttonInfo
        
        instance = TwitterClient()
        
        creatCounterNewTweets()
        
        refreshControler = CBStoreHouseRefreshControl.attach(to: self.tableView, target: self, refreshAction: #selector(actionClose), plist: "arrow", color: UIColor(red: 255/255, green: 0/255, blue: 104/255, alpha: 1), lineWidth: 1.5, dropHeight: 90, scale: 1, horizontalRandomness: 150, reverseLoadingAnimation: true, internalAnimationFactor: 0.5)
        
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "Tweeter logo"))
        tableView.contentInset.bottom += 60.0
        
        if self.tweet == nil {
            self.tweet = Profile.startTimeLine!
            for x in self.tweet! {
                x.cellData.asObservable().subscribe(onNext: { [weak self] data in
                    guard let s = self else { return }
                    s.varietyCellAction(data: data)
                }).addDisposableTo(self.dis)
            }
        }
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let twee = self.tweet else { return }
        DispatchQueue.global().async {
            var arrayIndex = [Int]()
            for (index, tweeTemp) in twee.enumerated() {
                if let id = Profile.tweetID[tweeTemp.tweetID] {
                    if !id, try! tweeTemp.retweetBtn.value() {
                        tweeTemp.retweetBtn.onNext(false)
                        let temp = try! tweeTemp.retweetCount.value() - 1
                        tweeTemp.retweetCount.onNext(temp)
                        if tweeTemp.retweetedType == "Retweeted by \(tweeTemp.retweetedName) and You" {
                            tweeTemp.retweetedType = "Retweeted by \(tweeTemp.retweetedName)"
                        } else if tweeTemp.followingStatus {
                            self.heightCell[index] = self.heightCell[index] - 12.0
                            tweeTemp.retweetedType = ""
                        } else { arrayIndex.append(index) }
                    } else if id, try! !tweeTemp.retweetBtn.value()  {
                        tweeTemp.retweetBtn.onNext(true)
                        let temp = try! tweeTemp.retweetCount.value() + 1
                        tweeTemp.retweetCount.onNext(temp)
                        if tweeTemp.retweetedType == "" {
                            tweeTemp.retweetedType = "Retweeted by You"
                            self.heightCell[index] = self.heightCell[index] + 12.0
                        } else {
                            tweeTemp.retweetedType = "Retweeted by \(tweeTemp.retweetedName) and You"
                        }
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
            if arrayIndex.count > 0 {
                var markerOffset = 0
                for x in arrayIndex {
                    self.tweet?.remove(at: x - markerOffset)
                    self.heightCell.remove(at: x - markerOffset)
                    markerOffset += 1
                }
            }
            if Profile.markerForReset, self.navigationController?.viewControllers.count == 1 { Profile.tweetID = [:]; Profile.tweetIDForFavorite = [:] }
            DispatchQueue.main.async { self.tableView.reloadData() }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if dataMediaScale != nil { dataMediaScale = nil }
    }
    
    private func creatCounterNewTweets() {
        myView = UIView()
        myView!.backgroundColor = UIColor(red: 220/257, green: 220/257, blue: 220/257, alpha: 0.85)
        self.view.addSubview(myView!)
        let leading = NSLayoutConstraint(item: myView!, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 0.0)
        let trailing = NSLayoutConstraint(item: myView!, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        let top = NSLayoutConstraint(item: myView!, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 64.0)
        tweetViewConstraints = NSLayoutConstraint(item: myView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0.0)
        tweetViewConstraints?.isActive = true
        
        NSLayoutConstraint.activate([leading, trailing, top])
        myView!.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.bringSubview(toFront: myView!)
        
        newTweetsLbl = UILabel()
        newTweetsLbl?.text = ""
        newTweetsLbl?.textColor = UIColor.black
        newTweetsLbl?.font = UIFont.boldSystemFont(ofSize: 12)
        newTweetsLbl?.textAlignment = .center
        newTweetsLbl?.translatesAutoresizingMaskIntoConstraints = false
        myView!.addSubview(newTweetsLbl!)
        
        let imageView = UIImageView()
        imageView.heightAnchor.constraint(equalToConstant: 12.0).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 12.0).isActive = true
        imageView.image = UIImage(named: "arrowSimple")
        
        let stackView = UIStackView()
        stackView.axis = UILayoutConstraintAxis.horizontal
        stackView.distribution = UIStackViewDistribution.equalSpacing
        stackView.alignment = UIStackViewAlignment.center
        stackView.spacing = 9.0
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(newTweetsLbl!)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        myView!.addSubview(stackView)
        
        stackView.centerXAnchor.constraint(equalTo: myView!.centerXAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: myView!.bottomAnchor, constant: -4.0).isActive = true
    }
    
    func barbuttonReply() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ReplyAndNewTweet") as! UINavigationController
        if let controller = storyboard.viewControllers.first as? ReplyAndNewTweetVC {
            let user = Profile.account
            user?.screenName = ""
            controller.userReply = nil
            self.present(storyboard, animated: true, completion: nil)
        }
    }
    func barbuttonInfo() {
        
    }
    
    func actionClose () {
        self.lastTweetID = nil
        self.perform(#selector(reloadData), with: nil, afterDelay: 1, inModes: [.commonModes])
    }
    
    func reloadData(append: Bool = false) {
        
        instance?.timeLine(maxID: lastTweetID) { (data) in
            if append {
                if data.isEmpty {
                    self.stopOffset = true
                    self.loadingMoreTweets?.stopAnimating()
                    self.loadingMoreTweets?.removeFromSuperview()
                    self.loadingView?.removeFromSuperview()
                    self.loadingMoreTweets = nil
                    self.loadingView = nil
                    
                    UIView.animate(withDuration: 0.3) { self.tableView.contentInset = UIEdgeInsets(top: 64.0, left: 0, bottom: 50.0, right: 0) }
                    return
                }
                for x in data {
                    x.cellData.asObservable().subscribe(onNext: { [weak self] data in
                        guard let s = self else { return }
                        s.varietyCellAction(data: data)
                    }).addDisposableTo(self.dis)
                }
                self.tweet?.append(contentsOf: data)
                if self.isMoreDataLoading.finish {
                    self.isMoreDataLoading = (start: false, finish: true, download: false)
                    let pointOffSetY = self.tableView.contentSize.height - self.tableView.bounds.height
                    self.loadingMoreTweets?.stopAnimating()
                    self.loadingMoreTweets?.removeFromSuperview()
                    self.loadingView?.removeFromSuperview()
                    self.loadingMoreTweets = nil
                    self.loadingView = nil
                    self.tableView.setContentOffset(CGPoint(x: 0.0, y: pointOffSetY), animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                        self.tableView.reloadData()
                        self.tableView.setContentOffset(CGPoint(x: 0.0, y: pointOffSetY + (self.tableView.contentOffset.y - pointOffSetY) + 100.0), animated: true)
                        self.isMoreDataLoading.finish = false
                    })
                } else if !self.isMoreDataLoading.finish {
                    self.isMoreDataLoading.download = true
                }
            } else {
                
                self.tempTweetArray = [ViewModelTweet]()
                if let tempTweet = self.tweet {
                    for value in data {
                        if tempTweet.contains(value) {
                            break
                        }
                        self.tempTweetArray!.append(value)
                    }
                }
                if data.count > 0, self.tempTweetArray!.count > 0 {
                    for x in self.tempTweetArray! {
                        x.cellData.asObservable().subscribe(onNext: { [weak self] data in
                            guard let s = self else { return }
                            s.varietyCellAction(data: data)
                        }).addDisposableTo(self.dis)
                    }
                    self.lastTweetID = self.tweet?.last?.lastTweetID
                    self.indexRefresh = self.tempTweetArray!.count
                    self.newTweetsLbl?.text = "\(self.indexRefresh) New Tweets"
                    self.refreshControler?.finishingLoading()
                    NSObject.cancelPreviousPerformRequests(withTarget: self)
                    self.perform(#selector(UIScrollViewDelegate.scrollViewDidEndScrollingAnimation), with: nil, afterDelay: 1.0)
                } else {
                    self.refreshControler?.finishingLoading()
                    self.lastTweetID = self.tweet?.last?.lastTweetID
                }
            }
        }
    }
    
    func varietyCellAction(data: CellData) {
        switch data {
        case let .Retweet(index):
            print(data)
            guard let twee = self.tweet else { return }
            if twee[index.row].retweetedType == "Retweeted by You", !twee[index.row].retweeted {
                self.imageLoadOperations.forEach {$0.value.cancel()}
                self.imageLoadOperationsMedia.forEach {$0.value.cancel()}
                self.imageLoadOperations = [IndexPath: ImageLoadOperation]()
                self.imageLoadOperationsMedia = [IndexPath: ImageLoadOperation]()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self.tableView.beginUpdates()
                    self.heightCell.remove(at: index.row)
                    self.tweet!.remove(at: index.row)
                    self.tableView.deleteRows(at: [index], with: .bottom)
                    self.tableView.endUpdates()
                })
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: {
                    self.tableView.reloadData()
                })
            } else {
                if twee[index.row].retweetedType == "Retweeted by You" {
                    heightCell[index.row] = heightCell[index.row] + 12.0
                } else if twee[index.row].retweetedType == "" {
                    heightCell[index.row] = heightCell[index.row] - 12.0
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
            self.dataMediaScale?.image = try! self.tweet?[index.row].image.value()
            self.dataMediaScale?.indexPath = index
            Profile.shotView = false
            let controllerPhotoScale = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoScaleVC") as! PhotoScaleVC
            controllerPhotoScale.transitioningDelegate = self
            controllerPhotoScale.image = self.dataMediaScale?.image
            present(controllerPhotoScale, animated: true, completion: nil)
        case let .QuoteTap(tweet):
            let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "DetailsVC") as! DetailsVC
            customAttributeForDetailsVC(tweet: tweet, complete: { data in
                controller.attributeText = data
                controller.tweet = tweet
            })
            SDWebImageManager.shared().downloadImage(with: tweet.userAvatar, progress: { (_, _) in }, completed: { (image, error, cache, _, _) in
                tweet.userPicImage.onNext(image!)
            })
            if let url = tweet.mediaImageURLs.first {
                SDWebImageManager.shared().downloadImage(with: url, progress: { (_, _) in }, completed: { (image, error, cache, _, _) in
                    tweet.image.onNext(image!)
                })
            }
            self.navigationController?.pushViewController(controller, animated: true)
        case let .TextInvokeSelectRow(index):
            self.tableView.selectRow(at: index, animated: true, scrollPosition: .none)
            performSegue(withIdentifier: "DetailsVCText", sender: self.tableView.cellForRow(at: index))
            self.tableView.deselectRow(at: index, animated: true)
        case let .Safari(url):
            let controller = SFSafariViewController(url: URL(string: url)!, entersReaderIfAvailable: true)
            self.present(controller, animated: true, completion: nil)
        case let .UserPicTap(tweet):
            let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ProfileVC") as! ProfileVC
            tweet.user.userData = Variable<UserData>(UserData.tempValue(action: false))
            controller.user = tweet.user
            self.navigationItem.title = "Timeline"
            self.navigationController?.pushViewController(controller, animated: true)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweet?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let twee = tweet?[indexPath.row] else { return UITableViewCell() }
        switch twee {
        case let media where !media.mediaImageURLs.isEmpty:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MediaCell", for: indexPath) as! MediaCell
            cell.tweetSetConfigure(tweet: media)
            cell.indexPath = indexPath
            if self.dataMediaScale?.indexPath == nil {
                self.fetchImageForCell(index: indexPath, data: media)
            }
            return cell
        case let quote where quote.quote != nil:
            let cell = tableView.dequeueReusableCell(withIdentifier: "quoteCompact", for: indexPath) as! QuoteCell
            cell.tweetSetConfigure(tweet: quote)
            cell.indexPath = indexPath
            if !quote.quote!.mediaImageURLs.isEmpty {
                DispatchQueue.global().async {
                    cell.imageQuote.sd_setImage(with: quote.quote?.mediaImageURLs.first)
                }
            }
            self.fetchImageForCell(index: indexPath, data: quote)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CompactCell", for: indexPath) as! CompactCell
            cell.tweetSetConfigure(tweet: twee)
            cell.indexPath = indexPath
            DispatchQueue.global().async {
                self.fetchImageForCell(index: indexPath, data: twee)
            }
            return cell
        }
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let twee = self.tweet else { return }
        if tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.height + 50.0, twee.count > 8, !self.stopOffset {
            if !isMoreDataLoading.start, !isMoreDataLoading.finish  {
                NSObject.cancelPreviousPerformRequests(withTarget: self)
                perform(#selector(UIScrollViewDelegate.scrollViewDidEndScrollingAnimation), with: nil, afterDelay: 0.3)
                isMoreDataLoading.start = true
                
                loadingView = UIView(frame: CGRect(x: CGFloat(0.0), y: tableView.contentSize.height, width: tableView.bounds.size.width, height: 60.0))
                tableView.addSubview(loadingView!)
                let rectProgress = CGRect(x: (loadingView?.bounds.width)!/2 - 11.0, y: (loadingView?.bounds.height)!/2 - 11.0, width: 22.0, height: 22.0)
                loadingMoreTweets = NVActivityIndicatorView(frame: rectProgress, type: .lineScalePulseOutRapid, color: UIColor(red: 255/255, green: 0/255, blue: 104/255, alpha: 1), padding: 0)
                loadingView?.addSubview(loadingMoreTweets!)
                loadingMoreTweets?.startAnimating()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                    self.reloadData(append: true)
                })
                
            } else if isMoreDataLoading.start, isMoreDataLoading.finish {
                isMoreDataLoading.finish = false
                NSObject.cancelPreviousPerformRequests(withTarget: self)
                perform(#selector(UIScrollViewDelegate.scrollViewDidEndScrollingAnimation), with: nil, afterDelay: 0.3)
            }
        }
        if tableView.contentOffset.y < -64.0 {
            self.refreshControler?.scrollViewDidScroll()
        }
        if self.positionRefresh {
            let frameCell = self.tableView.rectForRow(at: IndexPath(row: self.indexRefresh - 1, section: 0))
            let position = self.tableView.convert(frameCell, to: self.tableView.superview)
            if position.maxY <= 64.0, position.maxY >= 0.0 && tableView.isDragging {
                self.tweetViewConstraints?.constant = 23.0 - (64.0 - position.maxY)
            } else if position.minY >= 64.0 {
                self.indexRefresh -= 1
                if self.indexRefresh > 0  { self.newTweetsLbl?.text = "\(self.indexRefresh) New Tweets" }
            }
            if self.indexRefresh == 0, position.maxY > 62.0 {
                self.positionRefresh = false
                self.tweetViewConstraints?.constant = 0.0
                self.tempTweetArray = nil
                UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.refreshControler?.scrollViewDidEndDragging()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if self.indexRefresh > 0 {
            if self.tableView.contentSize.height <= self.tableView.bounds.size.height - 100.0 {
                var tempIndex = [IndexPath]()
                while self.indexRefresh != 0  {
                    tempIndex.append(IndexPath(item: self.indexRefresh - 1, section: 0))
                    heightCell.insert(0.0, at: indexRefresh - 1)
                    self.indexRefresh -= 1
                }
                self.tableView.insertRows(at: tempIndex, with: .top)
                
            } else {
                self.tweet?.insert(contentsOf: self.tempTweetArray!, at: 0)
                var tempIndex = self.indexRefresh
                while tempIndex != 0 {
                    heightCell.insert(0.0, at: tempIndex - 1)
                    tempIndex -= 1
                }
                let index = IndexPath(item: self.indexRefresh, section: 0)
                self.tableView.reloadData()
                self.tableView.scrollToRow(at: index, at: .top, animated: false)
                self.tableView.layoutIfNeeded()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02, execute: {
                    self.tweetViewConstraints?.constant = 23.0
                    self.positionRefresh = true
                    UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
                })
            }
            
        } else if isMoreDataLoading.start {
            if self.isMoreDataLoading.download {
                self.isMoreDataLoading = (start: false, finish: true, download: false)
                let pointOffSetY = self.tableView.contentSize.height - self.tableView.bounds.height
                self.loadingMoreTweets?.stopAnimating()
                self.loadingMoreTweets?.removeFromSuperview()
                self.loadingView?.removeFromSuperview()
                self.loadingMoreTweets = nil
                self.loadingView = nil
                self.tableView.setContentOffset(CGPoint(x: 0.0, y: pointOffSetY), animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    self.tableView.reloadData()
                    self.tableView.setContentOffset(CGPoint(x: 0.0, y: pointOffSetY + (self.tableView.contentOffset.y - pointOffSetY) + 100.0), animated: true)
                    self.isMoreDataLoading.finish = false
                })
            } else if !self.isMoreDataLoading.finish {
                self.isMoreDataLoading.finish = true
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = indexPath.row
        let count = heightCell.count
        if row < count, heightCell[row] != 0.0 {
            return heightCell[row]
        } else {
            guard let tweetHeight = tweet?[indexPath.row] else { return 0.0 }
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
                if row < count {
                    heightCell.insert(finaleSize, at: row)
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
                    sizeQuoteTextLbl = 2.0 + 60.0
                } else {
                    let rectQuote = tweetHeight.quote!.text.boundingRect(with:  CGSize(width: cell.textQuote.frame.size.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                    sizeQuoteTextLbl = ceil(rectQuote.size.height)
                }
                let viewContent = cell.contentView
                let size = viewContent.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
                let finaleSize: CGFloat
                if tweetHeight.retweetedType.isEmpty {
                    finaleSize = size.height + ceil(rect.size.height) - 12.0 + 1.0 + sizeQuoteTextLbl
                } else {
                    finaleSize = size.height + ceil(rect.size.height) + 1.0 + sizeQuoteTextLbl
                }
                if row < count {
                    heightCell.insert(finaleSize, at: row)
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
                let size = viewContent.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
                let finaleSize: CGFloat
                if tweetHeight.retweetedType.isEmpty {
                    finaleSize = size.height + ceil(rect.size.height) - 12.0 + 1.0
                } else {
                    finaleSize = size.height + ceil(rect.size.height) + 1.0
                }
                if row < count {
                    heightCell.insert(finaleSize, at: row)
                } else {
                    heightCell.append(finaleSize)
                }
                return finaleSize
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch  segueIdentifierForSegue(segue: segue) {
        case .DetailsVCText:
            if let detail = segue.destination as? DetailsVC {
                if let cell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPath(for: cell)
                    if let index = indexPath, let twee = self.tweet?[index.row] {
                        customAttributeForDetailsVC(tweet: twee, complete: { data in
                            detail.attributeText = data
                            detail.tweet = twee
                        })
                        self.navigationItem.title = "Timeline"
                    }
                }
            }
        case .DetailsVCMedia:
            if let detail = segue.destination as? DetailsVC {
                if let cell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPath(for: cell)
                    if let index = indexPath, let twee = self.tweet?[index.row] {
                        customAttributeForDetailsVC(tweet: twee, complete: { data in
                            detail.attributeText = data
                            detail.tweet = twee
                        })
                        self.navigationItem.title = "Timeline"
                    }
                }
            }
        case .DetailsVCQuote:
            if let detail = segue.destination as? DetailsVC {
                if let cell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPath(for: cell)
                    if let index = indexPath, let twee = self.tweet?[index.row] {
                        customAttributeForDetailsVC(tweet: twee, complete: { data in
                            detail.attributeText = data
                            detail.tweet = twee
                        })
                        self.navigationItem.title = "Timeline"
                    }
                }
            }
        }
    }
    
    private func customAttributeForDetailsVC(tweet: ViewModelTweet, complete: @escaping (_ data: NSMutableAttributedString) -> ()) {
        let text = tweet.text
        let attribute = NSMutableAttributedString(attributedString: text)
        attribute.beginEditing()
        attribute.enumerateAttribute(NSFontAttributeName, in: NSRange(location: 0, length: text.length), using: { (value, range, stop) in
            if let oldFont = value as? UIFont {
                let newFont = oldFont.withSize(14.5)
                attribute.removeAttribute(NSFontAttributeName, range: range)
                attribute.addAttribute(NSFontAttributeName, value: newFont, range: range)
            }
            //stop.pointee = true
        })
        attribute.endEditing()
        complete(attribute)
    }
}

extension HomeVC: UIViewControllerTransitioningDelegate {
    
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

extension HomeVC: ImageTransitionProtocol {
    
    func tranisitionSetup() {
        if let twee = self.tweet, let data = self.dataMediaScale {
            twee[data.indexPath!.row].image.onNext(UIImage.getEmptyImageWithColor(color: UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1.0)))
        }
    }
    
    func tranisitionCleanup() {
        if let twee = self.tweet, let data = self.dataMediaScale, let index = data.indexPath {
            twee[index.row].image.onNext(data.image!)
        }
    }
    
    func imageWindowFrame() -> CGRect { return (dataMediaScale?.convert)! }
}

extension HomeVC: UITableViewDataSourcePrefetching {
    
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
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let _ = imageLoadOperations[indexPath], let _ = imageLoadOperationsMedia[indexPath] { continue }
            if let _ = imageLoadOperations[indexPath] { continue }
            
            if let twee = self.tweet?[indexPath.row] {
                if twee.mediaImageURLs.isEmpty {
                    let imageLoadOperation = ImageLoadOperation(url: twee.userAvatar)
                    imageLoadQueue.addOperation(imageLoadOperation)
                    imageLoadOperations[indexPath] = imageLoadOperation
                } else {
                    let imageLoadOperation = ImageLoadOperation(url: twee.userAvatar)
                    imageLoadQueue.addOperation(imageLoadOperation)
                    imageLoadOperations[indexPath] = imageLoadOperation
                    
                    let imageMedia = ImageLoadOperation(url: twee.mediaImageURLs.first!)
                    imageLoadQueue.addOperation(imageMedia)
                    imageLoadOperationsMedia[indexPath] = imageMedia
                }
                guard let tweet = twee.quote else { continue }
                if !tweet.mediaImageURLs.isEmpty {
                    SDWebImagePrefetcher.shared().prefetchURLs([tweet.mediaImageURLs.first!])
                }
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
}

