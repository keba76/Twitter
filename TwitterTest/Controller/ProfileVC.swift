
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
import SafariServices

class ProfileVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, SegueHandlerType {
    
    enum SegueIdentifier: String {
        case DetailsVCText
        case DetailsVCMedia
        case ProfilePageVC
        case DetailsVCQuote
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
    
    var heightCell = Array<CGFloat>()
    
    var loadingMoreTweets: NVActivityIndicatorView?
    var loadingView: UIView?
    var stopOffset = false
    
    lazy var group = DispatchQueue.global(qos: .userInitiated)
    
    var user: ModelUser?
    
    var isMoreDataLoading = (start: false, finish: false, download: false)
    
    var viewHelp: UIView?
    
    var settings = false
    
    var headerView: ProfileHeader!
    
    var lastTweetID: String?
    var tweet: [ViewModelTweet]? {
        didSet {
            lastTweetID = tweet?.last?.lastTweetID
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppUtility.lockOrientation(.portrait)
        instance = TwitterClient()
        
        
        if #available(iOS 10.0, *) { tableView.prefetchDataSource = self }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        if TabBarVC.tab == .profileVC, self.navigationController?.viewControllers.count == 1 {
            Profile.reloadingProfileTweetsWhenRetweet = 0
            Profile.reloadingProfileTweetsWhenReply = 0
        }
        
        headerView = tableView.tableHeaderView as? ProfileHeader
        tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        tableView.contentInset = UIEdgeInsets(top: tableHeaderHeight - 64.0, left: 0, bottom: 0, right: 0)
        
        headerView.frame = CGRect(x: 0, y: -(tableHeaderHeight), width: tableView.bounds.width, height: tableHeaderHeight)
        self.headerView.user = user
        
        self.user?.userData.asObservable().subscribe(onNext: { [weak self] data in
            guard let s = self else { return }
            s.varietyUserAction(data: data)
        }).disposed(by: self.dis)
        
        let rectProgress = CGRect(x: view.bounds.width/2 - 20.0, y: (view.bounds.height + tableView.contentInset.top + 64.0)/2 - 20.0, width: 40.0, height: 40.0)
        viewProgress = NVActivityIndicatorView(frame: rectProgress, type: .lineScalePulseOut, color: UIColor(red: 255/255, green: 0/255, blue: 104/255, alpha: 1), padding: 0)
        self.view.addSubview(self.viewProgress!)
        self.view.bringSubviewToFront(self.viewProgress!)
        self.viewProgress?.startAnimating()
        
        self.navigationItem.title = user?.screenName
        
        if let user = self.user, user.protected, !user.followYou {
            self.tweet = [ViewModelTweet]()
            self.viewProgress?.stopAnimating()
            self.viewProgress?.removeFromSuperview()
            self.viewProgress = nil
            self.tableView.reloadData()
            
        } else {
            self.reloadData()
        }
        
        tableView.contentInset.bottom += 60.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppUtility.lockOrientation(.portrait)
        if self.navigationController?.viewControllers.count == 1 {
            
            Profile.markerForReset = true
            Profile.profileAccount = true
            guard let twee = self.tweet else { return }
            
            var timeStamp = false
            for (key, value) in Profile.tweetID {
                if twee.contains(where: {$0.tweetID == key}) {
                    if value { continue }
                }
                if value { timeStamp = value; break }
            }
            
            //if Profile.reloadingProfileTweetsWhenReply <= 0 && !timeStamp {
            
            var arrayIndex = [Int]()
            var tempDeleteCount = 0
            for (index, tweeTemp) in twee.enumerated() {
                if let id = Profile.tweetID[tweeTemp.tweetID] {
                    if !id, try! tweeTemp.retweetBtn.value() {
                        arrayIndex.append(index)
                        
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
                if !Profile.tweetIDDelete.isEmpty {
                    
                    if let _ = Profile.tweetIDDelete[tweeTemp.tweetID] {
                        tempDeleteCount += 1
                        arrayIndex.append(index)
                    }
                }
            }
            if Profile.tweetIDDelete.count - tempDeleteCount > 0 {
                Profile.reloadingProfileTweetsWhenReply -= Profile.tweetIDDelete.count - tempDeleteCount
            }
            if arrayIndex.count > 0 {
                var markerOffset = 0
                for x in arrayIndex {
                    self.tweet?.remove(at: x - markerOffset)
                    self.heightCell.remove(at: x - markerOffset)
                    markerOffset += 1
                }
            }
            Profile.tweetIDDelete = [:]
            self.tableView.reloadData()
            
            //            } else {
            //            DispatchQueue.global().async {
            //                for tweeTemp in twee {
            //                    if let id = Profile.tweetIDForFavorite[tweeTemp.tweetID] {
            //                        if !id, try! tweeTemp.favoriteBtn.value() {
            //                            tweeTemp.favoriteBtn.onNext(false)
            //                            let temp = try! tweeTemp.favoriteCount.value() - 1
            //                            tweeTemp.favoriteCount.onNext(temp)
            //                        } else if id, try! !tweeTemp.favoriteBtn.value() {
            //                            tweeTemp.favoriteBtn.onNext(true)
            //                            let temp = try! tweeTemp.favoriteCount.value() + 1
            //                            tweeTemp.favoriteCount.onNext(temp)
            //                        }
            //                    }
            //                }
            //            }
            //            }
            if timeStamp || Profile.reloadingProfileTweetsWhenReply > 0 {
                
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                viewHelp = UIView(frame: CGRect(x: 0.0, y: self.tableHeaderHeight, width: view.bounds.width, height: view.bounds.height))
                viewHelp?.backgroundColor = UIColor.groupTableViewBackground
                self.view.addSubview(viewHelp!)
                self.view.bringSubviewToFront(viewHelp!)
                
                let rectProgress = CGRect(x: view.bounds.width/2 - 20.0, y: (self.tableHeaderHeight + (view.bounds.height - self.tableHeaderHeight)/2) - 20.0, width: 40.0, height: 40.0)
                viewProgress = NVActivityIndicatorView(frame: rectProgress, type: .lineScalePulseOut, color: UIColor(red: 255/255, green: 0/255, blue: 104/255, alpha: 1), padding: 0)
                self.view.addSubview(self.viewProgress!)
                self.view.bringSubviewToFront(self.viewProgress!)
                self.viewProgress?.startAnimating()
                self.lastTweetID = nil
                instance?.userTimeLine(id: (user?.id)!, maxID: lastTweetID) { (data) in
                    self.viewProgress?.stopAnimating()
                    self.viewProgress?.removeFromSuperview()
                    self.viewProgress = nil
                    UIView.animate(withDuration: 0.5, animations: {
                        self.viewHelp?.alpha = 0.0
                    }, completion: { finish in
                        self.viewHelp?.removeFromSuperview()
                        self.viewHelp = nil
                    })
                    var uniqueTemp = [ViewModelTweet]()
                    for value in data {
                        if twee.contains(value) { break }
                        value.cellData.asObservable().subscribe(onNext: { [weak self] data in
                            guard let s = self else { return }
                            s.varietyCellAction(data: data)
                        }).disposed(by: self.dis)
                        uniqueTemp.append(value)
                    }
                    
                    self.imageLoadOperations.forEach {$0.value.cancel()}
                    self.imageLoadOperationsMedia.forEach {$0.value.cancel()}
                    self.imageLoadOperations = [IndexPath: ImageLoadOperation]()
                    self.imageLoadOperationsMedia = [IndexPath: ImageLoadOperation]()
                    Profile.reloadingProfileTweetsWhenRetweet = 0
                    Profile.reloadingProfileTweetsWhenReply = 0
                    
                    if uniqueTemp.count > 0 {
                        self.tweet?.insert(contentsOf: uniqueTemp, at: 0)
                        
                        var indexRefresh = [IndexPath]()
                        var seed = uniqueTemp.count
                        while seed != 0 {
                            indexRefresh.insert(IndexPath(item: seed - 1, section: 0), at: 0)
                            self.heightCell.insert(0.0, at: 0)
                            seed -= 1
                        }
                        self.tableView.beginUpdates()
                        self.tableView.insertRows(at: indexRefresh, with: .top)
                        self.tableView.endUpdates()
                        self.tableView.reloadData()
                    }
                }
            }
        } else {
            Profile.profileAccount = false
            Profile.markerForReset = false
            guard let twee = self.tweet else { return }
            DispatchQueue.global().async {
                for (index, tweeTemp) in twee.enumerated() {
                    if let id = Profile.tweetID[tweeTemp.tweetID] {
                        if !id, try! tweeTemp.retweetBtn.value() {
                            tweeTemp.retweetBtn.onNext(false)
                            let temp = try! tweeTemp.retweetCount.value() - 1
                            tweeTemp.retweetCount.onNext(temp)
                            if tweeTemp.retweetedType == "Retweeted by \(tweeTemp.retweetedName) and You" {
                                tweeTemp.retweetedType = "Retweeted by \(tweeTemp.retweetedName)"
                            } else {
                                self.heightCell[index] = self.heightCell[index] - 12.0
                                tweeTemp.retweetedType = ""
                            }
                        } else if id, try! !tweeTemp.retweetBtn.value() {
                            tweeTemp.retweetBtn.onNext(true)
                            let temp = try! tweeTemp.retweetCount.value() + 1
                            tweeTemp.retweetCount.onNext(temp)
                            if tweeTemp.retweetedType == "Retweeted by \(tweeTemp.retweetedName)" {
                                tweeTemp.retweetedType = "Retweeted by \(tweeTemp.retweetedName) and You"
                            } else {
                                self.heightCell[index] = self.heightCell[index] + 12.0
                                tweeTemp.retweetedType = "Retweeted by You"
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
                DispatchQueue.main.async { self.tableView.reloadData() }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if dataMediaScale != nil { dataMediaScale = nil }
    }
    
    func reloadData(append: Bool = false) {
        
        instance?.userTimeLine(id: (user?.id)!, maxID: lastTweetID) { (data) in
            
            if append {
                
                if data.isEmpty {
                    self.stopOffset = true
                    self.loadingMoreTweets?.stopAnimating()
                    self.loadingMoreTweets?.removeFromSuperview()
                    self.loadingView?.removeFromSuperview()
                    self.loadingMoreTweets = nil
                    self.loadingView = nil
                    UIView.animate(withDuration: 0.3) { self.tableView.contentInset = UIEdgeInsets(top: self.tableHeaderHeight, left: 0, bottom: 50.0, right: 0) }
                    return
                }
                for x in data {
                    x.cellData.asObservable().subscribe(onNext: { [weak self] data in
                        guard let s = self else { return }
                        s.varietyCellAction(data: data)
                    }).disposed(by: self.dis)
                }
                
                let startIndex = self.tweet!.count
                self.tweet?.append(contentsOf: data)
                let endIndex  = self.tweet!.count - 1
                var index = [IndexPath]()
                if endIndex > startIndex {
                    for x in startIndex...endIndex {
                        let tempIndex = IndexPath(item: x, section: 0)
                        index.append(tempIndex)
                    }
                }
                
                if self.isMoreDataLoading.finish {
                    self.isMoreDataLoading = (start: false, finish: true, download: false)
                    let pointOffSetY = self.tableView.contentSize.height - self.tableView.bounds.height
                    self.loadingMoreTweets?.stopAnimating()
                    self.loadingMoreTweets?.removeFromSuperview()
                    self.loadingView?.removeFromSuperview()
                    self.loadingMoreTweets = nil
                    self.loadingView = nil
                    //self.tableView.setContentOffset(CGPoint(x: 0.0, y: pointOffSetY), animated: true)
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: {
                        self.tableView.setContentOffset(CGPoint(x: 0.0, y: pointOffSetY), animated: false)
                    }, completion: { finished in
                        self.tableView.beginUpdates()
                        self.tableView.insertRows(at: index, with: .none)
                        self.tableView.endUpdates()
                        self.tableView.setContentOffset(CGPoint(x: 0.0, y: pointOffSetY + (self.tableView.contentOffset.y - pointOffSetY) + 100.0), animated: true)
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
                        x.cellData.asObservable().subscribe(onNext: { [weak self] data in
                            guard let s = self else { return }
                            s.varietyCellAction(data: data)
                        }).disposed(by: self.dis)
                    }
                }
                let section = IndexSet(integer: 0)
                self.tableView.reloadSections(section, with: .bottom)
                
            }
        }
    }
    
    func varietyCellAction(data: CellData) {
        switch data {
        case let .Retweet(index):
            print(data)
            guard let twee = self.tweet else { return }
            if TabBarVC.tab == .profileVC, self.navigationController?.viewControllers.count == 1 {
                Profile.reloadingProfileTweetsWhenRetweet = 0
                self.tweet?.remove(at: index.row)
                self.heightCell.remove(at: index.row)
                self.imageLoadOperations.forEach {$0.value.cancel()}
                self.imageLoadOperationsMedia.forEach {$0.value.cancel()}
                self.imageLoadOperations = [:]
                self.imageLoadOperationsMedia = [:]
                self.tableView.performUpdate({ self.tableView.deleteRows(at: [index], with: .automatic) }, completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.tableView.reloadData() }
                })
            } else {
                if twee[index.row].retweetedType == "Retweeted by You" {
                    heightCell[index.row] = heightCell[index.row] + 12.0
                } else if twee[index.row].retweetedType == "" {
                    heightCell[index.row] = heightCell[index.row] - 12.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [index], with: .none)
                    self.tableView.endUpdates()
                })
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
        case let .Settings(index, twee, delete, viewDetail, viewRetweets, modal):
            if modal {
                if twee.userScreenName == Profile.account.screenNameAt {
                    let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
                    controller.transitioningDelegate = self
                    controller.modalPresentationStyle = .custom
                    controller.variety = VarietyModally.settingsProfile
                    controller.tweet = twee
                    controller.index = index
                    present(controller, animated: true, completion: nil)
                    controller.fourthBtn.setImage(UIImage(named: "btnModalyDelete"), for: .normal)
                    controller.thirdBtn.setImage(UIImage(named: "btnModalyShowDetails"), for: .normal)
                    controller.secondBtn.setImage(UIImage(named: "btnModalyShowRetweets"), for: .normal)
                } else {
                    let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
                    controller.transitioningDelegate = self
                    controller.modalPresentationStyle = .custom
                    controller.variety = VarietyModally.settings
                    controller.tweet = twee
                    controller.index = index
                    present(controller, animated: true, completion: nil)
                    controller.thirdBtn.setImage(UIImage(named: "btnModalyShowDetails"), for: .normal)
                    controller.secondBtn.setImage(UIImage(named: "btnModalyShowRetweets"), for: .normal)
                }
            } else {
                twee.settingsBtn.onNext(false)
                switch true {
                case delete:
                    TwitterClient.swifter.destroyTweet(forID: twee.tweetID)
                    self.heightCell.remove(at: index.row)
                    self.tweet!.remove(at: index.row)
                    self.imageLoadOperations.forEach {$0.value.cancel()}
                    self.imageLoadOperationsMedia.forEach {$0.value.cancel()}
                    self.imageLoadOperations = [:]
                    self.imageLoadOperationsMedia = [:]
                    self.tableView.performUpdate({self.tableView.deleteRows(at: [index], with: .bottom)}, completion: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.tableView.reloadData() }
                    })
                    Profile.tweetIDDelete[twee.tweetID] = true
                case viewDetail:
                    let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "DetailsVC") as! DetailsVC
                    customAttributeForDetailsVC(tweet: twee, complete: { data in
                        controller.attributeText = data
                        controller.tweet = twee
                    })
                    SDWebImageManager.shared().loadImage(with: twee.userAvatar, progress: { (_, _,
                        _) in }, completed: { (image, error, cache, _, _, _) in
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
        case let .QuoteTap(tweet):
            let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "DetailsVC") as! DetailsVC
            customAttributeForDetailsVC(tweet: tweet, complete: { data in
                controller.attributeText = data
                controller.tweet = tweet
            })
            SDWebImageManager.shared().loadImage(with: tweet.userAvatar, progress: { (_, _, _) in }, completed: { (image, error, cache, _, _, _) in
                if image == nil {
                    let urlString = tweet.userAvatar.absoluteString
                    if urlString.contains("profile_images") {
                        let newUrl = urlString.replace(target: ".jpg", withString: "_bigger.jpg")
                        SDWebImageManager.shared().loadImage(with: URL(string: newUrl), progress: { (_ , _, _) in
                        }) { (image, error, cache , _ , _, _) in
                            tweet.userPicImage.onNext(image!)
                        }
                    }
                } else {
                    tweet.userPicImage.onNext(image!)
                }
                
            })
            if let url = tweet.mediaImageURLs.first {
                SDWebImageManager.shared().loadImage(with: url, progress: { (_, _, _) in }, completed: { (image, error, cache, _, _, _) in tweet.image.onNext(image!)
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
            
        case let .MediaScale(index, convert):
            if let youTubeURL = self.tweet?[index.row].youtubeURL {
                let controller = SFSafariViewController(url: youTubeURL, entersReaderIfAvailable: true)
                self.present(controller, animated: true, completion: nil)
            } else {
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
                if let url = self.tweet?[index.row].videoURL {
                    self.dataMediaScale?.mediaTriangle = true
                    let convertFrameTriangle = CGRect(x: convertFinal.center.x  - 15.0, y: convertFinal.center.y - 15.0, width: 30.0, height: 30.0)
                    self.dataMediaScale?.frameVideoTriangle = convertFrameTriangle
                    controllerPhotoScale.urlVideo = url
                }
                if let url = self.tweet?[index.row].instagramVideo {
                    self.dataMediaScale?.mediaTriangle = true
                    let convertFrameTriangle = CGRect(x: convertFinal.center.x  - 15.0, y: convertFinal.center.y - 15.0, width: 30.0, height: 30.0)
                    self.dataMediaScale?.frameVideoTriangle = convertFrameTriangle
                    controllerPhotoScale.urlVideo = url
                }
                present(controllerPhotoScale, animated: true, completion: nil)
            }
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
            self.dataMediaScale?.image = headerView.imageBanner == nil ?  UIImage.getEmptyImageWithColor(color: UIColor(red: 3/255, green: 169/255, blue: 244/255, alpha: 1)) : headerView.imageBanner
            self.dataMediaScale?.cornerRadius = false
            Profile.shotView = false
            let controllerPhotoScale = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoScaleVC") as! PhotoScaleVC
            controllerPhotoScale.transitioningDelegate = self
            if headerView.imageBanner == nil {
                controllerPhotoScale.image = UIImage.getEmptyImageWithColor(color: UIColor(red: 3/255, green: 169/255, blue: 244/255, alpha: 1))
            } else {
                controllerPhotoScale.image = headerView.imageBanner
            }
            present(controllerPhotoScale, animated: true, completion: nil)
            
        case let .TapSettingsBtn(user, modal, showMute, publicReply, _, _):
            if modal {
                print(data)
                self.settings = true
                let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
                controller.transitioningDelegate = self
                controller.modalPresentationStyle = .custom
                controller.user = user
                if tabBarController?.selectedIndex == 1, self.navigationController?.viewControllers.count == 1 {
                    controller.variety = VarietyModally.showMute
                    present(controller, animated: true, completion: nil)
                    controller.secondBtn.setImage(UIImage(named: "btnModalyShowMute"), for: .normal)
                } else {
                    controller.variety = VarietyModally.fourBtn
                    present(controller, animated: true, completion: nil)
                    controller.fourthBtn.setImage(UIImage(named: "btnModalyReplyPublic"), for: .normal)
                    controller.secondBtn.setImage(UIImage(named: "btnModalyMute"), for: .normal)
                    if !Profile.arrayIdFollowers.isEmpty, let id = Int(user.id)  {
                        if Profile.arrayIdFollowers.contains(where: {$0.integer == id}) {
                            controller.thirdBtn.setImage(UIImage(named: "btnModalyUnfollow"), for: .normal)
                        } else {
                            controller.thirdBtn.setImage(UIImage(named: "btnModalyFollow"), for: .normal)
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
                        tempSet.insert("@\(user.screenName)")
                        controller.user = tempSet
                        controller.publicReply = true
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
        guard let twee = tweet else { return UITableViewCell() }
        if twee.isEmpty {
            if (self.user?.protected)! {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LockCell") as! LockCell
                tableView.separatorStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell") as! EmptyCell
                tableView.separatorStyle = .none
                return cell
            }
        }
        switch twee[indexPath.row] {
        case let media where !media.mediaImageURLs.isEmpty:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MediaCell", for: indexPath) as! MediaCell
            cell.tweetSetConfigure(tweet: media)
            cell.indexPath = indexPath
            if self.dataMediaScale?.indexPath == nil {
                group.async {
                    self.fetchImageForCell(index: indexPath, data: media)
                }
                
            }
            return cell
        case let quote where quote.quote != nil:
            let cell = tableView.dequeueReusableCell(withIdentifier: "quoteCompact", for: indexPath) as! QuoteCell
            cell.tweetSetConfigure(tweet: quote)
            cell.indexPath = indexPath
            if !quote.quote!.mediaImageURLs.isEmpty {
                group.async {
                    cell.imageQuote.sd_setImage(with: quote.quote?.mediaImageURLs.first)
                }
            }
            group.async {
                self.fetchImageForCell(index: indexPath, data: quote)
            }
            return cell
        case let compact where !compact.tweetID.isEmpty:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CompactCell", for: indexPath) as! CompactCell
            cell.tweetSetConfigure(tweet: twee[indexPath.row])
            cell.indexPath = indexPath
            group.async {
                self.fetchImageForCell(index: indexPath, data: compact)
            }
            return cell
            
        default:
            tableView.separatorStyle = .none
            return UITableViewCell()
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
                    //self?.tableView.layoutIfNeeded()
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if tableView.contentOffset.y < -(tableHeaderHeight) {
            var headerRect = CGRect(x: 0, y: -(tableHeaderHeight), width: tableView.bounds.width, height: tableHeaderHeight)
            headerRect.origin.y = tableView.contentOffset.y
            headerRect.size.height = -tableView.contentOffset.y
            headerView.frame = headerRect
        }
        guard let twee = self.tweet else { return }
        if twee.count < 8 {
            UIView.animate(withDuration: 0.3) { self.tableView.contentInset = UIEdgeInsets(top: self.tableHeaderHeight, left: 0, bottom: 50.0, right: 0) }
        }
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
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if isMoreDataLoading.start {
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
                    }
                }
            }
        case .ProfilePageVC:
            if let detail = segue.destination as? ProfilePageVC {
                detail.user = self.user
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = indexPath.row
        let count = heightCell.count
        if row < count, heightCell[row] != 0.0 {
            return heightCell[row]
        } else {
            guard let twee = tweet else { return 0.0 }
            if twee.isEmpty { return 82.0 }
            
            let tweetHeight = twee[indexPath.row]
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
                let size = viewContent.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
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
                twee[data.indexPath!.row].image.onNext(UIImage.getEmptyImageWithColor(color: UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1.0)))
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
                    
                    guard let tweet = twee.quote else { continue }
                    if !tweet.mediaImageURLs.isEmpty {
                        SDWebImagePrefetcher.shared().prefetchURLs([tweet.mediaImageURLs.first!])
                    }
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
