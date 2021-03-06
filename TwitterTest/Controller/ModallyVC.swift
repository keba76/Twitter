//
//  ModallyVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/7/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift

protocol ModallyDelegate: class {
    func modally(image: UIImage?, variety: VarietyModally?, helper: SomeTweetsData?)
}
extension ModallyDelegate {
    func extensionModally(image: UIImage? = nil, variety: VarietyModally? = nil, helper: SomeTweetsData? = nil) {
        modally(image: image, variety: variety, helper: helper)
    }
}

enum VarietyModally {
    case photo
    case pic
    case fourBtn
    case reply
    case showMute
    case cancel
    case removePic
    case settings
    case settingsDetailOfMe
    case settingsDetail
    case settingsProfile
    case imageLibrary
    case makePhotoOrVideo
}

class ModallyVC: UIViewController {
    
    @IBOutlet weak var fourthBtn: UIButton!
    @IBOutlet weak var thirdBtn: UIButton!
    @IBOutlet weak var secondBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    @IBOutlet weak var heightFirstBtn: NSLayoutConstraint!
    @IBOutlet weak var heightSecondBtn: NSLayoutConstraint!
    @IBOutlet weak var heightThirdBnt: NSLayoutConstraint!
    @IBOutlet weak var spaceBetweenFirstAndTwoBtn: NSLayoutConstraint!
    
    let dis = DisposeBag()
    var delegateModally: ModallyDelegate?
    
    var variety: VarietyModally?
    var tweet: ViewModelTweet?
    var user: ModelUser?
    
    var index: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fourthBtn.imageView?.contentMode = .scaleAspectFill
        thirdBtn.imageView?.contentMode = .scaleAspectFill
        secondBtn.imageView?.contentMode = .scaleAspectFill
        cancelBtn.imageView?.contentMode = .scaleAspectFill
        
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
            AppUtility.lockOrientation(.landscapeRight)
        }
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            AppUtility.lockOrientation(.landscapeLeft)
        }
        if UIDevice.current.orientation == UIDeviceOrientation.portrait {
            AppUtility.lockOrientation(.portrait)
        }
        
        switch self.variety! {
        case .showMute, .settingsDetail:
            self.thirdBtn.isHidden = true
            self.fourthBtn.isHidden = true
        case .fourBtn, .settingsProfile:
            break
        default:
            self.fourthBtn.isHidden = true
        }
        
        fourthBtn.rx.tap.asObservable().subscribe(onNext: { [weak self] _ in
            guard let s = self else { return }
            switch s.variety! {
            case .fourBtn:
                s.dismiss(animated: true, completion: {
                    s.user?.userData.value = UserData.TapSettingsBtn(user: s.user!, modal: false, showMute: false, publicReply: true, mute: false, follow: false)
                })
            case .settingsProfile:
                s.dismiss(animated: true, completion: nil)
                s.tweet!.cellData.value = CellData.Settings(index: s.index!, tweet: s.tweet!, delete: true, viewDetail: false, viewRetweets: false, modal: false)
            default:
                break
            }
        }).disposed(by: self.dis)
        
        thirdBtn.rx.tap.asObservable().subscribe(onNext: { [unowned self] _ in
            switch self.variety! {
            case .photo:
                self.dismiss(animated: true, completion: {
                    self.delegateModally?.extensionModally(variety: VarietyModally.makePhotoOrVideo)
                })
            case .pic:
                //self.image = nil
                self.dismiss(animated: true, completion: {
                    self.delegateModally?.extensionModally(variety: VarietyModally.removePic)
                })
            case .reply:
                self.dismiss(animated: true, completion: {
                    self.tweet!.cellData.value = CellData.Reply(tweet: self.tweet!, modal: false, replyAll: false)
                })
            case .settingsDetailOfMe:
                self.dismiss(animated: true, completion: nil)
                self.tweet!.cellData.value = CellData.Settings(index: self.index!, tweet: self.tweet!, delete: true, viewDetail: false, viewRetweets: false, modal: false)
            case .settingsProfile, .settings:
                self.dismiss(animated: true, completion: nil)
                self.tweet!.cellData.value = CellData.Settings(index: self.index!, tweet: self.tweet!, delete: false, viewDetail: true, viewRetweets: false, modal: false)
            default:
                break
            }
        }).disposed(by: self.dis)
        
        secondBtn.rx.tap.asObservable().subscribe(onNext: { [unowned self] _ in
            switch self.variety! {
            case .photo:
                self.dismiss(animated: true, completion: {
                    self.delegateModally?.extensionModally(variety: VarietyModally.imageLibrary)
                })
            case .pic:
                self.dismiss(animated: true, completion: {
                    self.delegateModally?.extensionModally(variety: VarietyModally.pic)
                })
            case .reply:
                self.dismiss(animated: true, completion: {
                    self.tweet!.cellData.value = CellData.Reply(tweet: self.tweet!, modal: false, replyAll: true)
                })
            case .showMute:
                self.dismiss(animated: true, completion: {
                    self.user?.userData.value = UserData.TapSettingsBtn(user: self.user!, modal: false, showMute: true, publicReply: false, mute: false, follow: false)
                })
            case .settings, .settingsProfile, .settingsDetailOfMe, .settingsDetail:
                
                self.dismiss(animated: true, completion: nil)
                self.tweet!.cellData.value = CellData.Settings(index: self.index!, tweet: self.tweet!, delete: false, viewDetail: false, viewRetweets: true, modal: false)
            default:
                break
            }
        }).disposed(by: self.dis)
        cancelBtn.rx.tap.asObservable().subscribe(onNext: {
            guard let type = self.variety else { return }
            switch type {
            case .settingsProfile, .settings, .settingsDetailOfMe, .settingsDetail:
                self.tweet?.settingsBtn.onNext(false)
            case .reply:
                Profile.reloadingProfileTweetsWhenReply -= 1
                self.tweet?.replyBtn.onNext(false)
            default:
                break
            }
            self.dismiss(animated: true, completion: {
                self.delegateModally?.extensionModally(variety: VarietyModally.cancel)
            })
        }).disposed(by: self.dis)
    }
}


