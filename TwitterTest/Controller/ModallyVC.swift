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
}

class ModallyVC: UIViewController {
    
    @IBOutlet weak var thirdBtn: UIButton!
    @IBOutlet weak var secondBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var fourthBtn: UIButton!
    
    let dis = DisposeBag()
    var delegateModally: ModallyDelegate?
    
    
    var variety: VarietyModally?
    var tweet: ViewModelTweet?
    var user: ModelUser?
    
    var imageMiniature: UIImage?
    var image: UIImage?
    
    lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        return picker
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switch self.variety! {
        case .showMute:
            self.thirdBtn.isHidden = true
            self.fourthBtn.isHidden = true
        case let btn where btn != .fourBtn:
            self.fourthBtn.isHidden = true
        default:
            break
        }
        
//        if self.variety! != .fourBtn {
//            self.fourBtn.isHidden = true
//        }
        
        fourthBtn.rx.tap.asObservable().subscribe(onNext: { [unowned self] _ in
            switch self.variety! {
            case .fourBtn:
                self.dismiss(animated: true, completion: {
                    self.user?.userData.value = UserData.TapSettingsBtn(user: self.user!, modal: false, showMute: false, publicReply: true, mute: false, follow: false)
                    //self.delegateModally?.extensionModally(variety: VarietyModally.fourBtn)
                })
            default:
                break
            }
        }).addDisposableTo(dis)
        
        thirdBtn.rx.tap.asObservable().subscribe(onNext: { [unowned self] _ in
            switch self.variety! {
            case .photo:
                self.imagePicker.sourceType = .camera
                self.present(self.imagePicker, animated: true, completion: nil)
            case .pic:
                //self.image = nil
                self.dismiss(animated: true, completion: {
                    self.delegateModally?.extensionModally()
                })
            case .reply:
                self.dismiss(animated: true, completion: {
                    self.tweet!.cellData.value = CellData.Reply(tweet: self.tweet!, modal: false, replyAll: false)
                })
            default:
                break
            }
        }).addDisposableTo(dis)
        
        
        secondBtn.rx.tap.asObservable().subscribe(onNext: { [unowned self] _ in
            switch self.variety! {
            case .photo:
                self.imagePicker.sourceType = .photoLibrary
                self.present(self.imagePicker, animated: true, completion: nil)
            case .pic:
                let width = (UIApplication.shared.windows.first?.bounds)!
                self.dismiss(animated: true, completion: {
                    self.delegateModally?.extensionModally(image:self.imageWithImage(image: self.image!, scaledToSize: CGSize(width: width.width, height: width.width * (self.image?.size.height)! / (self.image?.size.width)!)) , variety: VarietyModally.pic)
                })
            case .reply:
                self.dismiss(animated: true, completion: {
                    self.tweet!.cellData.value = CellData.Reply(tweet: self.tweet!, modal: false, replyAll: true)
                })
            case .showMute:
                self.dismiss(animated: true, completion: {
                    self.user?.userData.value = UserData.TapSettingsBtn(user: self.user!, modal: false, showMute: true, publicReply: false, mute: false, follow: false)
                })
            default:
                break
                
            }
        }).addDisposableTo(dis)
        cancelBtn.rx.tap.asObservable().subscribe(onNext: {
            guard let type = self.variety else { return }
            if type != .reply {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.dismiss(animated: true, completion: {
                    self.tweet?.replyBtn.onNext(false)
                    //self.delegateModally?.extensionModally(variety: type)
                })
            }
        }).addDisposableTo(dis)
    }

}

extension ModallyVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        image = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.dismiss(animated: true, completion: {
            self.dismiss(animated: true, completion: {
                self.delegateModally?.extensionModally(image: self.image)
            })
        })
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}

