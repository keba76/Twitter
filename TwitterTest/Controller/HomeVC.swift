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

struct Profile {
    static var account = ModelUser()
    static var arrayIdFollowers = [JSON]()
    static var startTimeLine: [ViewModelTweet]?
    static var reloadingProfileTweetsWhenRetweet = 0
    static var profileAccount = false
    static var shotView = false
}

struct SomeTweetsData {
    var convert: CGRect?
    var indexPath: IndexPath?
    var image: UIImage?
    var scaleAvatarImage = false
    var scaleBanner = false
    var frameImage: CGRect?
    var frameBackImage: CGRect?
    var secondImageForBanner: UIImage?
    
    init(){}
    
    init(convert: CGRect? = nil, indexPath: IndexPath? = nil, image: UIImage? = nil, scaleAvatarImage: Bool = false, scaleBanner: Bool = false, frameImage: CGRect? = nil, frameBackImage: CGRect? = nil, secondImageForBanner: UIImage? = nil) {
        
        self.convert = convert
        self.indexPath = indexPath
        self.image = image
        self.scaleAvatarImage = scaleAvatarImage
        self.scaleBanner = scaleBanner
        self.frameImage = frameImage
        self.frameBackImage = frameBackImage
        self.secondImageForBanner = secondImageForBanner
    }
}


final class HomeVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, SegueHandlerType {
    
    enum SegueIdentifier: String {
        case DetailsVCText
        case DetailsVCMedia
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var cellHeights: CGFloat = 0.0
    var indexRefresh: [IndexPath]?
    
    var animationController: AnimationController = AnimationController()
    var dataMediaScale: SomeTweetsData?
    
    let dis = DisposeBag()
    
    fileprivate let imageLoadQueue = OperationQueue()
    fileprivate var imageLoadOperations = [IndexPath: ImageLoadOperation]()
    fileprivate var imageLoadOperationsMedia = [IndexPath: ImageLoadOperation]()
    
    var refreshControler: CBStoreHouseRefreshControl?
    
    var instance: TwitterClient?
    
    var loadingMoreTweets: NVActivityIndicatorView?
    var loadingView: UIView?
    
    var tweetViewConstraints: NSLayoutConstraint?
    var newTweetsLbl: UILabel?
    
    var isMoreDataLoading = (start: false, finish: false, download: false)
    
    var lastTweetID: String?
    var tweet: [ViewModelTweet]? {
        didSet {
            lastTweetID = tweet?.last?.tweetID
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 10.0, *) {
            tableView.prefetchDataSource = self
        }
        
        tableView.register(UINib(nibName: "QuoteCell", bundle: Bundle.main) , forCellReuseIdentifier: "quoteCompact")
        
        let buttonReply = UIBarButtonItem(image: UIImage(named: "composetweet2"), style: .plain, target: self, action: #selector(self.barbuttonReply))
        self.navigationItem.rightBarButtonItem  = buttonReply
        let buttonInfo = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.barbuttonInfo))
        self.navigationItem.leftBarButtonItem = buttonInfo
        
        instance = TwitterClient()
        
        creatCounterNewTweets()
        
        refreshControler = CBStoreHouseRefreshControl.attach(to: self.tableView, target: self, refreshAction: #selector(actionClose), plist: "arrow", color: UIColor(red: 255/255, green: 0/255, blue: 104/255, alpha: 1), lineWidth: 1.5, dropHeight: 90, scale: 1, horizontalRandomness: 150, reverseLoadingAnimation: true, internalAnimationFactor: 0.5)
        
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.estimatedRowHeight = 270.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "Tweeter logo"))
        var inset = tableView.contentInset
        inset.bottom += ScrollActivityView.defaultHeight
        tableView.contentInset = inset
        
        if self.tweet == nil {
            self.tweet = Profile.startTimeLine!
            for x in self.tweet! {
                x.cellData.asObservable().subscribe(onNext: { data in
                    self.varietyCellAction(data: data)
                }).addDisposableTo(self.dis)
            }
        }
        self.tableView.reloadData()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if dataMediaScale != nil { dataMediaScale = nil }
    }
    
    func creatCounterNewTweets() {
        let myView = UIView()
        myView.backgroundColor = UIColor(red: 220/257, green: 220/257, blue: 220/257, alpha: 0.85)
        self.view.addSubview(myView)
        let leading = NSLayoutConstraint(item: myView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 0.0)
        let trailing = NSLayoutConstraint(item: myView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        let top = NSLayoutConstraint(item: myView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 64.0)
        tweetViewConstraints = NSLayoutConstraint(item: myView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0.0)
        tweetViewConstraints?.isActive = true
        
        NSLayoutConstraint.activate([leading, trailing, top])
        myView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.bringSubview(toFront: myView)
        
        newTweetsLbl = UILabel()
        newTweetsLbl?.text = ""
        newTweetsLbl?.textColor = UIColor.black
        newTweetsLbl?.font = UIFont.boldSystemFont(ofSize: 12)
        newTweetsLbl?.textAlignment = .center
        newTweetsLbl?.translatesAutoresizingMaskIntoConstraints = false
        myView.addSubview(newTweetsLbl!)
        
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
        
        myView.addSubview(stackView)
        
        stackView.centerXAnchor.constraint(equalTo: myView.centerXAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: myView.bottomAnchor, constant: -4.0).isActive = true
    }
    
    func barbuttonReply() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ReplyAndNewTweet") as! UINavigationController
        if let controller = storyboard.viewControllers.first as? ReplyAndNewTweetVC {
            let user = Profile.account
            user.screenName = ""
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
                for x in data {
                    x.cellData.asObservable().subscribe(onNext: { data in
                        self.varietyCellAction(data: data)
                    }).addDisposableTo(self.dis)
                }
                self.tweet?.append(contentsOf: data)
                
                if self.isMoreDataLoading.finish {
                    self.isMoreDataLoading = (start: false, finish: true, download: false)
                    let pointOffSetY = self.tableView.contentSize.height - self.tableView.bounds.height - 50.0
                    self.tableView.setContentOffset(CGPoint(x: 0.0, y: pointOffSetY), animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                        self.loadingMoreTweets?.stopAnimating()
                        self.loadingMoreTweets?.removeFromSuperview()
                        self.loadingView?.removeFromSuperview()
                        self.loadingMoreTweets = nil
                        self.loadingView = nil
                        self.tableView.reloadData()
                    })
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                        
                        self.tableView.setContentOffset(CGPoint(x: 0.0, y: pointOffSetY + (self.tableView.contentOffset.y - pointOffSetY) + 150.0), animated: true)
                        self.isMoreDataLoading.finish = false
                    })
                } else if !self.isMoreDataLoading.finish {
                    self.isMoreDataLoading.download = true
                }
            } else {
                var uniqueTemp = [ViewModelTweet]()
                if let tempTweet = self.tweet {
                    for value in data {
                        if tempTweet.contains(value) {
                            break
                        }
                        uniqueTemp.append(value)
                    }
                }
                
                if data.count > 0, uniqueTemp.count > 0 {
                    for x in uniqueTemp {
                        x.cellData.asObservable().subscribe(onNext: { data in
                            self.varietyCellAction(data: data)
                        }).addDisposableTo(self.dis)
                    }
                    self.tweet?.insert(contentsOf: uniqueTemp, at: 0)
//                    var data = 0
//                    self.indexRefresh = [IndexPath]()
//                    while data != uniqueTemp.count {
//                        let index = IndexPath(item: data, section: 0)
//                        self.indexRefresh?.append(index)
//                        data += 1
//                    }
                    
                    self.indexRefresh = [IndexPath]()
                    for (index, _ ) in uniqueTemp.enumerated() {
                        self.indexRefresh?.append(IndexPath(item: index, section: 0))
                    }
                    
                    
                    if let index = self.indexRefresh {
                        self.newTweetsLbl?.text = "\(index.count) New Tweets"
                    }
                    self.cellHeights = 0
                    self.refreshControler?.finishingLoading()
                    NSObject.cancelPreviousPerformRequests(withTarget: self)
                    self.perform(#selector(UIScrollViewDelegate.scrollViewDidEndScrollingAnimation), with: nil, afterDelay: 1.0)
                } else {
                    self.refreshControler?.finishingLoading()
                }
            }
        }
    }
    
    
    func varietyCellAction(data: CellData) {
        switch data {
        case let .Retweet(index, _):
            print(data)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.tableView.reloadRows(at: [index], with: .none) }
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
            self.tableView.reloadData()
            print(data)
        case let .QuoteTap(tweet):
            let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "DetailsVC") as! DetailsVC
            controller.tweet = tweet
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "media", for: indexPath) as! TweetMediaCell
            cell.tweet = media
            cell.indexPath = indexPath
            if self.dataMediaScale?.indexPath == nil {
                if let imageLoadOperation = imageLoadOperations[indexPath], let imageLoadOperationMedia = imageLoadOperationsMedia[indexPath] {
                    media.userPicImage.onNext(imageLoadOperation.image ?? UIImage.getEmptyImageWithColor(color: UIColor.white))
                    media.image.onNext(imageLoadOperationMedia.image ?? UIImage.getEmptyImageWithColor(color: UIColor.white))
                } else {
                    let imageLoadOperation = ImageLoadOperation(url: media.userAvatar)
                    imageLoadOperation.completionHandler = { [weak self] (image) in
                        guard let strongSelf = self else { return }
                        media.userPicImage.onNext(image)
                        strongSelf.imageLoadOperations.removeValue(forKey: indexPath)
                    }
                    imageLoadQueue.addOperation(imageLoadOperation)
                    imageLoadOperations[indexPath] = imageLoadOperation
                    
                    let imageLoadOperationMedia = ImageLoadOperation(url: media.mediaImageURLs.first!)
                    imageLoadOperationMedia.completionHandler = { [weak self] (image) in
                        guard let strongSelf = self else { return }
                        media.image.onNext(image)
                        strongSelf.imageLoadOperationsMedia.removeValue(forKey: indexPath)
                    }
                    imageLoadQueue.addOperation(imageLoadOperationMedia)
                    imageLoadOperationsMedia[indexPath] = imageLoadOperationMedia
                }
            }
            return cell
        case let quote where quote.quote != nil:
            let cell = tableView.dequeueReusableCell(withIdentifier: "quoteCompact", for: indexPath) as! QuoteCell
            cell.tweet = quote
            cell.indexPath = indexPath
            if let imageLoadOperation = imageLoadOperations[indexPath], let image = imageLoadOperation.image {
                quote.userPicImage.onNext(image)
            } else {
                let imageLoadOperation = ImageLoadOperation(url: quote.userAvatar)
                imageLoadOperation.completionHandler = { [weak self] (image) in
                    guard let strongSelf = self else { return }
                    quote.userPicImage.onNext(image)
                    strongSelf.imageLoadOperations.removeValue(forKey: indexPath)
                }
                imageLoadQueue.addOperation(imageLoadOperation)
                imageLoadOperations[indexPath] = imageLoadOperation
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "compact", for: indexPath) as! TweetCompactCell
            cell.tweet = twee
            cell.indexPath = indexPath
            if let imageLoadOperation = imageLoadOperations[indexPath],
                let image = imageLoadOperation.image {
                twee.userPicImage.onNext(image)
            } else {
                let imageLoadOperation = ImageLoadOperation(url: twee.userAvatar)
                imageLoadOperation.completionHandler = { [weak self] (image) in
                    guard let strongSelf = self else { return }
                    twee.userPicImage.onNext(image)
                    strongSelf.imageLoadOperations.removeValue(forKey: indexPath)
                }
                imageLoadQueue.addOperation(imageLoadOperation)
                imageLoadOperations[indexPath] = imageLoadOperation
            }
            return cell
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !isMoreDataLoading.start, !isMoreDataLoading.finish && tweet?.count != nil && (tweet?.count)! > 8 {
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollViewContentOffset = scrollViewContentHeight - tableView.bounds.height + 50.0
            if tableView.contentOffset.y > scrollViewContentOffset {
                NSObject.cancelPreviousPerformRequests(withTarget: self)
                perform(#selector(UIScrollViewDelegate.scrollViewDidEndScrollingAnimation), with: nil, afterDelay: 0.3)
                isMoreDataLoading.start = true
                
                loadingView = UIView(frame: CGRect(x: CGFloat(0.0), y: tableView.contentSize.height, width: tableView.bounds.size.width, height: 60.0))
                tableView.addSubview(loadingView!)
                let rectProgress = CGRect(x: (loadingView?.bounds.width)!/2 - 11.0, y: (loadingView?.bounds.height)!/2 - 11.0, width: 22.0, height: 22.0)
                loadingMoreTweets = NVActivityIndicatorView(frame: rectProgress, type: .lineScalePulseOutRapid, color: UIColor(red: 255/255, green: 0/255, blue: 104/255, alpha: 1), padding: 0)
                loadingView?.addSubview(loadingMoreTweets!)
                loadingMoreTweets?.startAnimating()
                DispatchQueue.global().asyncAfter(deadline: .now() + 2.0, execute: {
                    self.reloadData(append: true)
                })
            }
        } else if isMoreDataLoading.start, isMoreDataLoading.finish {
            isMoreDataLoading.finish = false
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            perform(#selector(UIScrollViewDelegate.scrollViewDidEndScrollingAnimation), with: nil, afterDelay: 0.3)
        }
        
        self.refreshControler?.scrollViewDidScroll()
        
        if self.cellHeights > 0, self.indexRefresh != nil, self.tableView.contentOffset.y > cellHeights - 64.0 && tableView.isDragging {
            self.tweetViewConstraints?.constant = 23.0 - (self.tableView.contentOffset.y - (cellHeights - 64.0))
            self.view.layoutIfNeeded()
        }
        if self.cellHeights > 0, self.indexRefresh != nil, self.tableView.contentOffset.y <= cellHeights - 64.0 && tableView.isDragging {
            self.tweetViewConstraints?.constant = 23.0
            self.view.layoutIfNeeded()
        }
        if let index = self.indexRefresh, self.cellHeights > 0, self.tableView.contentOffset.y <= cellHeights - 64.0 && tableView.isDragging {
            let cellFrame = self.tableView.rectForRow(at: index.last!)
            if self.tableView.contentOffset.y <= cellHeights - 64.0 - cellFrame.height && cellHeights != 64.0 {
                self.indexRefresh?.removeLast()
                if let x = indexRefresh, (self.indexRefresh?.count)! > 0 {
                    self.newTweetsLbl?.text = "\(x.count) New Tweets"
                }
                cellHeights -= cellFrame.height
                if cellHeights == 0 {
                    cellHeights = -1
                }
            }
        }
        if cellHeights == -1, self.indexRefresh != nil {
            cellHeights = 0
            self.indexRefresh = nil
            self.tweetViewConstraints?.constant = 0.0
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.refreshControler?.scrollViewDidEndDragging()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if self.indexRefresh != nil {
            self.tableView.reloadData()
            self.indexRefresh?.forEach({ index in
                self.cellHeights += (self.tableView.cellForRow(at: index)?.frame.height)!
            })
            self.tableView.contentOffset = CGPoint(x: 0.0, y: self.cellHeights - 64.0)
            
            self.tweetViewConstraints?.constant = 23.0
            
            UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
        } else if isMoreDataLoading.start {
            if self.isMoreDataLoading.download {
                self.isMoreDataLoading = (start: false, finish: true, download: false)
                let pointOffSetY = self.tableView.contentSize.height - self.tableView.bounds.height - 50.0
                self.tableView.setContentOffset(CGPoint(x: 0.0, y: pointOffSetY), animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self.loadingMoreTweets?.stopAnimating()
                    self.loadingMoreTweets?.removeFromSuperview()
                    self.loadingView?.removeFromSuperview()
                    self.loadingMoreTweets = nil
                    self.loadingView = nil
                    self.tableView.reloadData()
                })
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                    
                    self.tableView.setContentOffset(CGPoint(x: 0.0, y: pointOffSetY + (self.tableView.contentOffset.y - pointOffSetY) + 150.0), animated: true)
                    self.isMoreDataLoading.finish = false
                })
            } else if !self.isMoreDataLoading.finish {
                self.isMoreDataLoading.finish = true
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch  segueIdentifierForSegue(segue: segue) {
        case .DetailsVCText:
            if let detail = segue.destination as? DetailsVC {
                if let cell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPath(for: cell)
                    detail.tweet = tweet![(indexPath?.row)!]
                }
            }
        case .DetailsVCMedia:
            if let detail = segue.destination as? DetailsVC {
                if let cell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPath(for: cell)
                    detail.tweet = tweet![(indexPath?.row)!]
                }
            }
        }
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
            twee[data.indexPath!.row].image.onNext(UIImage.getEmptyImageWithColor(color: UIColor.white))
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

