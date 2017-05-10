//
//  FollowersAndFollowingVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/18/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class FollowersAndFollowingVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var navItem: UINavigationItem!
    //@IBOutlet weak var backBtn: UIBarButtonItem!
    
    
    var dis = DisposeBag()
    
    
    //var loadingActivityView: ScrollActivityView?
    var isMoreDataLoading = (start: false, finish: false, download: false)
    var instance: TwitterClient?
    var download = false
    var cursor: String?
    var typeUser: String?
    var user: ModelUser?
    var users = [ModelUser]()
    //var followedYou = false
    var userTapSettings: ModelUser?
    
    var viewProgress: NVActivityIndicatorView?
    
    var loadingMoreTweets: NVActivityIndicatorView?
    var loadingView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        
        self.navigationItem.title = self.typeUser == "Followers" ? "Followers" : "Followings"
        
        
        
        //tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        
        instance = TwitterClient()
        
        reloadData()
        
//        backBtn.rx.tap.asObservable().subscribe({ _ in
//            self.dismiss(animated: true, completion: nil)
//        }).addDisposableTo(dis)
        
        var inset = tableView.contentInset
        inset.bottom += ScrollActivityView.defaultHeight
        tableView.contentInset = inset
        
        
        let rectProgress = CGRect(x: view.bounds.width/2 - 25.0, y: view.bounds.height/2 - 25.0, width: 50.0, height: 50.0)
        viewProgress = NVActivityIndicatorView(frame: rectProgress, type: .lineScalePulseOut, color: UIColor(red: 255/255, green: 0/255, blue: 104/255, alpha: 1), padding: 0)
        
        self.view.addSubview(self.viewProgress!)
        self.view.bringSubview(toFront: self.viewProgress!)
        self.viewProgress?.startAnimating()
        
    }
    
    
    func reloadData(append: Bool = false) {
            instance?.followersAndFollowing(userID: self.user!.id, type: typeUser!, cursor: cursor, complited: { user, cursor in
                if append {
                    for x in user {
                        x.userData.asObservable().subscribe(onNext: { [weak self] data in
                            guard let s = self else { return }
                            s.varietyUserAction(data: data)
                            }, onCompleted: {
                                print("!!!")
                        }).addDisposableTo(self.dis)
                    }
                    self.users.append(contentsOf: user)
                    self.cursor = cursor
                    if self.isMoreDataLoading.finish {
                        self.isMoreDataLoading = (start: false, finish: true, download: false)
                        let pointOffSetY = self.tableView.contentSize.height - self.tableView.bounds.height - 20.0
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
                            
                            self.tableView.setContentOffset(CGPoint(x: 0.0, y: pointOffSetY + (self.tableView.contentOffset.y - pointOffSetY) + 50.0), animated: true)
                            self.isMoreDataLoading.finish = false
                        })
                    } else if !self.isMoreDataLoading.finish {
                        self.isMoreDataLoading.download = true
                    }
                    //self.cursor = cursor
                    //self.tableView.reloadData()
                } else {
                    self.download = true
                    self.viewProgress?.stopAnimating()
                    self.viewProgress?.removeFromSuperview()
                    self.viewProgress = nil
                    for x in user {
                        x.userData.asObservable().subscribe(onNext: { [weak self] data in
                            guard let s = self else { return }
                            s.varietyUserAction(data: data)
                            }, onCompleted: {
                                print("!!!")
                        }).addDisposableTo(self.dis)
                    }

                    self.users.append(contentsOf: user)
                    self.cursor = cursor
                    let section = IndexSet(integer: 0)
                    self.tableView.reloadSections(section, with: .fade)
                }
            })
       
    }
    
    private func varietyUserAction(data: UserData) {
        switch data {
        case let .TapSettingsBtn(user, modal, _ , publicReply, mute, follow):
            if modal {
            let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
            controller.transitioningDelegate = self
            controller.modalPresentationStyle = .custom
            controller.user = user
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
            } else {
                switch true {
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
        return users.count > 0 ? users.count : users.count == 0 && download ? 1 : 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.users.count == 0 && download {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell") as! EmptyCell
            tableView.separatorStyle = .none
            return cell
        } else if self.users.count > 0  {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FollowersAndFollowingCell", for: indexPath) as! FollowersAndFollowingCell
            cell.user = users[indexPath.row]
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !isMoreDataLoading.start, !isMoreDataLoading.finish, self.cursor != "0" && users.count > 10 {
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollViewContentOffset = scrollViewContentHeight - tableView.bounds.height + 5.0
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
                let pointOffSetY = self.tableView.contentSize.height - self.tableView.bounds.height - 20.0
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
                    
                    self.tableView.setContentOffset(CGPoint(x: 0.0, y: pointOffSetY + (self.tableView.contentOffset.y - pointOffSetY) + 50.0), animated: true)
                    self.isMoreDataLoading.finish = false
                })
            } else if !self.isMoreDataLoading.finish {
                self.isMoreDataLoading.finish = true
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "profileNC") as! UINavigationController
        //let profileVC = storyboard.viewControllers.first as! ProfileVC
        //ProfileVC.userBehavior.onNext(users[indexPath.row])
        //profileVC.id = users[indexPath.row].id
        //ProfileVC.users.append(users[indexPath.row])   ВАЖНО!!!! поменять!
        tableView.deselectRow(at: indexPath, animated: true)
        let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ProfileVC") as! ProfileVC
        users[indexPath.row].userData = Variable<UserData>(UserData.tempValue(action: false))
        controller.user = users[indexPath.row]
        if (self.navigationController != nil) {
            print("111")
        }
        self.navigationController?.pushViewController(controller, animated: true)
        
    }
    
}

//extension FollowersAndFollowingVC: TwitterTableViewDelegate {
//    
//    func profileVC(tweet: ViewModelTweet?, user: ModelUser?, users: ModelUser?, someTweetsData: SomeTweetsData?, settings: Bool, scaleAvatarImage: Bool) {
//        let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
//        if let user = users {
//            self.userTapSettings = user
//        }
//        
//        controller.transitioningDelegate = self
//        controller.modalPresentationStyle = .custom
//        controller.delegateModally = self
//        controller.variety = VarietyModally.fourBtn
//        present(controller, animated: true, completion: nil)
//        controller.fourthBtn.setImage(UIImage(named: "publicReplyBtn"), for: .normal)
//        controller.secondBtn.setImage(UIImage(named: "muteBtn"), for: .normal)
//        if !Profile.arrayIdFollowers.isEmpty, let idString = users?.id, let id = Int(idString)  {
//            if Profile.arrayIdFollowers.contains(where: {$0.integer == id}) {
//                controller.thirdBtn.setImage(UIImage(named: "unfollowBtn"), for: .normal)
//            } else {
//                controller.thirdBtn.setImage(UIImage(named: "followBtn"), for: .normal)
//            }
//        }
//    }

//    func profileVC(tweet: Tweet?, user: ModelUser?, users: ModelUser?, someTweetsData: SomeTweetsData?, settings: Bool, scaleAvatarImage: Bool) {
//        let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
//        if let user = users {
//            self.userTapSettings = user
//        }
//        
//        controller.transitioningDelegate = self
//        controller.modalPresentationStyle = .custom
//        controller.delegateModally = self
//        controller.variety = VarietyModally.fourBtn
//        present(controller, animated: true, completion: nil)
//        controller.fourBtn.setImage(UIImage(named: "publicReplyBtn"), for: .normal)
//        controller.libraryBtn.setImage(UIImage(named: "muteBtn"), for: .normal)
//        if let array = ProfileLeftVC.arrayIdFollowers, let idString = users?.id, let id = Int(idString)  {
//            if array.contains(where: {$0.integer == id}) {
//                controller.photoBtn.setImage(UIImage(named: "unfollowBtn"), for: .normal)
//            } else {
//                controller.photoBtn.setImage(UIImage(named: "followBtn"), for: .normal)
//            }
//        }
//        
//    }
//}

extension FollowersAndFollowingVC: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = SlideInPresentationController(presentedViewController: presented, presenting: presenting, finalSize: true)
        return presentationController
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInPresentationAnimator(isPresentation: true)
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInPresentationAnimator(isPresentation: false)
    }
}

extension FollowersAndFollowingVC: ModallyDelegate {
    
    func modally(image: UIImage?, variety: VarietyModally?, helper: SomeTweetsData?) {
        
        if let variety = variety {
            if variety == .fourBtn {
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ReplyAndNewTweet") as! UINavigationController
//                if let controller = storyboard.viewControllers.first as? ReplyAndNewTweetVC {
//                    controller.userReply = self.userTapSettings
//                    self.present(storyboard, animated: true, completion: nil)                 // ПРОВЕРИТЬ!!!
//                }
            }
        }
    }
}
