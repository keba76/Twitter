
//  ProfileVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/22/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SDWebImage

class ProfileVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, SegueHandlerType {
    
    enum SegueIdentifier: String {
        case DetailsVCText
        case DetailsVCMedia
        case ProfilePageVC
    }
    
    var tableHeaderHeight: CGFloat = 350.0
    
    var viewProgress: NVActivityIndicatorView?
    
    var animationController = AnimationController()
    var dataMediaScale: SomeTweetsData?
    
    fileprivate let imageLoadQueue = OperationQueue()
    fileprivate var imageLoadOperations = [IndexPath: ImageLoadOperation]()
    fileprivate var imageLoadOperationsMedia = [IndexPath: ImageLoadOperation]()
    
    @IBOutlet weak var tableView: UITableView!
    
    var dis = DisposeBag()
    var instance: TwitterClient?
    
    var loadingMoreTweets: NVActivityIndicatorView?
    var loadingView: UIView?
    
    var user: ModelUser?
 
    var isMoreDataLoading = (start: false, finish: false, download: false)
    
    var viewHelp: UIView?
    
    var settings = false
    
    var headerView: ProfileHeader!
    
    var lastTweetID: String?
    var tweet: [ViewModelTweet]? {
        didSet {
            lastTweetID = tweet?.last?.tweetID
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        instance = TwitterClient()
        
        if #available(iOS 10.0, *) {
            tableView.prefetchDataSource = self
        }
        
        tableView.register(UINib(nibName: "QuoteCell", bundle: Bundle.main) , forCellReuseIdentifier: "quoteCompact")
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 270.0
        tableView.tableFooterView = UIView()
        
        headerView = tableView.tableHeaderView as! ProfileHeader
        tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        tableView.contentInset = UIEdgeInsets(top: tableHeaderHeight - 64, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0.0, y: -(tableHeaderHeight + 64))
        headerView.frame = CGRect(x: 0, y: -(tableHeaderHeight), width: tableView.bounds.width, height: tableHeaderHeight)
        self.headerView.user = user
        
        self.user?.userData.asObservable().subscribe(onNext: { [weak self] data in
            guard let s = self else { return }
            s.varietyUserAction(data: data)
            }, onCompleted: {
                print("!!!")
        }).addDisposableTo(dis)
        
        let rectProgress = CGRect(x: view.bounds.width/2 - 20.0, y: (view.bounds.height + tableView.contentInset.top + 64.0)/2 - 20.0, width: 40.0, height: 40.0)
        viewProgress = NVActivityIndicatorView(frame: rectProgress, type: .lineScalePulseOut, color: UIColor(red: 255/255, green: 0/255, blue: 104/255, alpha: 1), padding: 0)
        self.view.addSubview(self.viewProgress!)
        self.view.bringSubview(toFront: self.viewProgress!)
        self.viewProgress?.startAnimating()
        
        self.navigationItem.title = user?.screenName
        
        if let user = self.user, user.protected, !user.followYou {
            self.tweet = [ViewModelTweet]()
            self.tableView.reloadData()
        } else {
            self.reloadData()
        }
    
        var inset = tableView.contentInset
        inset.bottom += ScrollActivityView.defaultHeight
        tableView.contentInset = inset
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if dataMediaScale != nil { dataMediaScale = nil }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.navigationController?.viewControllers.count == 1 {
            Profile.profileAccount = true
            if Profile.reloadingProfileTweetsWhenRetweet != 0 {
                self.tableView.contentOffset = CGPoint(x: 0, y: 0 - self.tableView.contentInset.top)
                
                viewHelp = UIView(frame: CGRect(x: 0.0, y: -self.tableView.contentOffset.y + 64.0, width: view.bounds.width, height: view.bounds.height))
                viewHelp?.backgroundColor = UIColor.groupTableViewBackground
                self.view.addSubview(viewHelp!)
                self.view.bringSubview(toFront: viewHelp!)
                
                let rectProgress = CGRect(x: view.bounds.width/2 - 20.0, y: (view.bounds.height + tableView.contentInset.top + 64.0)/2 - 20.0, width: 40.0, height: 40.0)
                viewProgress = NVActivityIndicatorView(frame: rectProgress, type: .lineScalePulseOut, color: UIColor(red: 255/255, green: 0/255, blue: 104/255, alpha: 1), padding: 0)
                self.view.addSubview(self.viewProgress!)
                self.view.bringSubview(toFront: self.viewProgress!)
                self.viewProgress?.startAnimating()
                self.lastTweetID = nil
                instance?.userTimeLine(id: (user?.id)!, maxID: lastTweetID) { (data) in
                    Profile.reloadingProfileTweetsWhenRetweet = 0
                    self.viewProgress?.stopAnimating()
                    self.viewProgress?.removeFromSuperview()
                    self.viewProgress = nil
                    UIView.animate(withDuration: 0.4, animations: {
                        self.viewHelp?.alpha = 0.0
                    }, completion: { finish in
                        self.viewHelp?.removeFromSuperview()
                        self.viewHelp = nil
                    })
                    
                    var uniqueTemp = [ViewModelTweet]()
                    if let tempTweet = self.tweet {
                        for value in data {
                            if tempTweet.contains(value) { break }
                            value.cellData.asObservable().subscribe(onNext: { data in
                                self.varietyCellAction(data: data)
                            }).addDisposableTo(self.dis)
                            uniqueTemp.insert(value, at: 0)
                        }
                    }
                    self.tweet?.insert(contentsOf: uniqueTemp, at: 0)
                    
                    var indexRefresh = [IndexPath]()
                    for (index, _ ) in uniqueTemp.enumerated() {
                        indexRefresh.append(IndexPath(item: index, section: 0))
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        self.imageLoadOperations.forEach {$0.value.cancel()}
                        self.imageLoadOperationsMedia.forEach {$0.value.cancel()}
                        self.imageLoadOperations = [IndexPath: ImageLoadOperation]()
                        self.imageLoadOperationsMedia = [IndexPath: ImageLoadOperation]()
                        self.tableView.beginUpdates()
                        self.tableView.insertRows(at: indexRefresh, with: .top)
                        self.tableView.endUpdates()
                    })
                }
            }
        } else {
            Profile.profileAccount = false
        }
    }
    
    //        override func viewWillDisappear(_ animated: Bool) {
    //            super.viewWillDisappear(animated)
    //                if self.us == ProfileConstant.account {} else {
    //            self.us?.userData = Variable<UserData>(UserData.tempValue(action: false))
    //
    //            }
    //        }
    
    func reloadData(append: Bool = false) {
        
        instance?.userTimeLine(id: (user?.id)!, maxID: lastTweetID) { (data) in
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
                self.viewProgress?.stopAnimating()
                self.viewProgress?.removeFromSuperview()
                self.viewProgress = nil
                if self.tweet == nil {
                    self.tweet = data
                    for x in self.tweet! {
                        x.cellData.asObservable().shareReplay(0).subscribe(onNext: { data in
                            self.varietyCellAction(data: data)
                        }).addDisposableTo(self.dis)
                    }
                }
                let section = IndexSet(integer: 0)
                self.tableView.reloadSections(section, with: .bottom)
                
            }
        }
    }
    
    func varietyCellAction(data: CellData) {
        switch data {
        case let .Retweet(index, convert):
            print(data)
            if TabBarVC.tab == .profileVC, self.navigationController?.viewControllers.count == 1 {
                let indexTemp = self.tableView.indexPathForRow(at: convert)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self.tableView.beginUpdates()
                    self.tweet?.remove(at: (indexTemp?.row)!)
                    self.tableView.deleteRows(at: [indexTemp!], with: .none)
                    self.imageLoadOperations[indexTemp!]?.cancel()
                    self.imageLoadOperations.removeValue(forKey: indexTemp!)
                    self.tableView.endUpdates()
                })
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.tableView.reloadRows(at: [index], with: .none) }
            }
        case let .UserPicTap(tweet):
            let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ProfileVC") as! ProfileVC
            tweet.user.userData = Variable<UserData>(UserData.tempValue(action: false))
            controller.user = tweet.user
            self.navigationController?.pushViewController(controller, animated: true)
            
        case let .Reply(twee, modal, replyAll):
            print(data)
            if modal {
                let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
                controller.transitioningDelegate = self
                controller.modalPresentationStyle = .custom
                controller.variety = VarietyModally.reply
                controller.tweet = twee
                self.settings = true
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
                        if !Profile.profileAccount {
                            if twee.retweetTweetID != nil {
                                user.append("@\(twee.retweetedScreenName)")
                            }
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
            
        default:
            break
        }
    }
    func varietyUserAction(data: UserData) {
        switch data {
        case let .ImageUserScale(data):
            self.dataMediaScale = SomeTweetsData()
            self.dataMediaScale?.scaleAvatarImage = true
            self.dataMediaScale?.convert = data.convert
            self.dataMediaScale?.image = headerView.images
            Profile.shotView = false
            let controllerPhotoScale = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoScaleVC") as! PhotoScaleVC
            controllerPhotoScale.transitioningDelegate = self
            controllerPhotoScale.image = headerView.images
            present(controllerPhotoScale, animated: true, completion: nil)
        case let .ImageBannerScale(data):
            self.dataMediaScale = SomeTweetsData()
            self.dataMediaScale?.scaleBanner = true
            self.dataMediaScale?.convert = data.convert
            self.dataMediaScale?.frameBackImage = data.frameBackImage
            self.dataMediaScale?.frameImage = data.frameImage
            self.dataMediaScale?.secondImageForBanner = headerView.images
            self.dataMediaScale?.image = headerView.imageBanner
            Profile.shotView = false
            let controllerPhotoScale = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoScaleVC") as! PhotoScaleVC
            controllerPhotoScale.transitioningDelegate = self
            controllerPhotoScale.image = headerView.imageBanner
            present(controllerPhotoScale, animated: true, completion: nil)
            
        case let .TapSettingsBtn(user, modal, showMute, publicReply, mute, follow):
            if modal {
                self.settings = true
                let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
                controller.transitioningDelegate = self
                controller.modalPresentationStyle = .custom
                controller.user = user
                if tabBarController?.selectedIndex == 1, self.navigationController?.viewControllers.count == 1 {
                    controller.variety = VarietyModally.showMute
                    present(controller, animated: true, completion: nil)
                    controller.secondBtn.setImage(UIImage(named: "muteUsers"), for: .normal)
                } else {
                    controller.variety = VarietyModally.fourBtn
                    present(controller, animated: true, completion: nil)
                    controller.fourthBtn.setImage(UIImage(named: "publicReplyBtn"), for: .normal)
                    controller.secondBtn.setImage(UIImage(named: "muteBtn"), for: .normal)
                    if !Profile.arrayIdFollowers.isEmpty, let id = Int(user.id)  {
                        if Profile.arrayIdFollowers.contains(where: {$0.integer == id}) {
                            controller.thirdBtn.setImage(UIImage(named: "unfollowBtn"), for: .normal)
                        } else {
                            controller.thirdBtn.setImage(UIImage(named: "followBtn"), for: .normal)
                        }
                    }
                    
                }
            } else {
                switch true {
                case showMute:
                    print("!")
                case publicReply:
                    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ReplyAndNewTweet") as! UINavigationController
                    if let controller = storyboard.viewControllers.first as? ReplyAndNewTweetVC {
                        var tempSet = Set<String>()
                        tempSet.insert(user.screenName)
                        controller.user = tempSet
                        self.present(storyboard, animated: true, completion: nil)
                    }
                default:
                    break
                }
                
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tweets = tweet else { return 0 }
        return tweets.count > 0 ? tweets.count : 1
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
        case let compact where !compact.tweetID.isEmpty:
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
        case let empty where empty.tweetID.isEmpty:
            if (self.user?.protected)! {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LockCell") as! LockCell
                tableView.separatorStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell") as! EmptyCell
                tableView.separatorStyle = .none
                return cell
            }
            
        default:
            tableView.separatorStyle = .none
            return UITableViewCell()
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var headerRect = CGRect(x: 0, y: -(tableHeaderHeight), width: tableView.bounds.width, height: tableHeaderHeight)
        if tableView.contentOffset.y < -(tableHeaderHeight) {
            headerRect.origin.y = tableView.contentOffset.y
            headerRect.size.height = -tableView.contentOffset.y
            headerView.frame = headerRect
        }
        
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
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if isMoreDataLoading.start {
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
        case .ProfilePageVC:
            if let detail = segue.destination as? ProfilePageVC {
                detail.user = self.user
                
            }
        }
    }
}

extension ProfileVC: UIViewControllerTransitioningDelegate {
    
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

extension ProfileVC: ImageTransitionProtocol {
    
    func tranisitionSetup() {
        if self.dataMediaScale!.scaleAvatarImage {
            self.headerView.profileImageView.image = nil
        } else if self.dataMediaScale!.scaleBanner {
            self.headerView.backgroundImage.image = nil
        } else {
            if let twee = self.tweet, let data = self.dataMediaScale {
                twee[data.indexPath!.row].image.onNext(UIImage.getEmptyImageWithColor(color: UIColor.white))
            }
        }
    }
    func tranisitionCleanup() {
        if self.dataMediaScale!.scaleAvatarImage {
            self.headerView.profileImageView.image = dataMediaScale?.image
        } else if self.dataMediaScale!.scaleBanner {
            self.headerView.backgroundImage.image = dataMediaScale?.image
        } else {
            if let twee = self.tweet, let data = self.dataMediaScale, let index = data.indexPath {
                twee[index.row].image.onNext(data.image!)
            }
        }
    }
    func imageWindowFrame() -> CGRect { return (dataMediaScale?.convert)! }
}

extension ProfileVC: UITableViewDataSourcePrefetching {
    
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
