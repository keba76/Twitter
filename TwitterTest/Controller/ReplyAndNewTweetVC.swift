//
//  ReplyAndNewTweetVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/5/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

struct ConstantMeasure {
    static let modalHeightTwoBtn: CGFloat = 166.0
    static let modalHeightThreeBtn: CGFloat = 240.0
    static let modalHeightFourBtn: CGFloat = 314.0
    static let spaceBetweetFirstAndSecondBtn: CGFloat = 30.0
}

protocol ButtonAction {
    func label(symbol: String, text: String, photo: Bool, photoName: String, convert: CGRect)
}
extension ButtonAction {
    func extensionLabel(symbol: String = "", text: String = "", photo: Bool = false, photoName: String = "", convert: CGRect = CGRect.zero) {
        label(symbol: symbol, text: text, photo: photo, photoName: photoName, convert: convert)
    }
}

class Cell1: UICollectionViewCell {
    
    var dis = DisposeBag()
    override func prepareForReuse() { dis = DisposeBag() }
    var delegate: ButtonAction?
    
    @IBOutlet weak var btnLocation: UIButton!
    @IBOutlet weak var btnPhoto: UIButton!
    @IBOutlet weak var btnHashtag: UIButton!
    @IBOutlet weak var btnAt: UIButton!
    @IBOutlet weak var countLbl: UILabel!
    
    var image: UIImage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        btnPhoto.layer.cornerRadius = 3.0
        btnPhoto.clipsToBounds = true
    }
    
    func config(image: UIImage?) {
        btnPhoto.imageView?.contentMode = .scaleAspectFill
        if let pic = image {
            btnPhoto.setImage(pic, for: .normal)
        } else {
            btnPhoto.setImage(UIImage(named: "photo1"), for: .normal)
        }
        btnPhoto.rx.tap.subscribe(onNext: { [unowned self] _ in
            if self.btnPhoto.imageView?.image == UIImage(named: "photo1") {
                self.delegate?.extensionLabel(photo: true, photoName: "photoIcon")
            } else {
                self.delegate?.extensionLabel(photo: true, photoName: "pic", convert: self.convert(self.btnPhoto.frame, to: self.contentView))
            }
        }).disposed(by: dis)
        
        btnHashtag.rx.tap.asObservable().subscribe(onNext: { _ in
            self.delegate?.extensionLabel(symbol: "#", text: "Start Typing a Tag...")
        }).disposed(by: dis)
        btnAt.rx.tap.asObservable().subscribe(onNext: { _ in
            self.delegate?.extensionLabel(symbol: "@", text: "Start Typing a Name...")
        }).disposed(by: dis)
    }
}
class Cell2: UICollectionViewCell {
    @IBOutlet weak var textInfo: UILabel!
}

class ReplyAndNewTweetVC: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var inputText: UITextView!
    
    @IBOutlet weak var bottomEdgeConstraint: NSLayoutConstraint!
    
    var countText: String?
    var countChar: String?
    var charCountLbl = Variable("140")
    
    var key: KeyboardStayAppearedVC?
    
    static let instance = TwitterClient()
    
    lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        return picker
    }()
    
    var scrollBack = false
    
    var viewProgress: NVActivityIndicatorView?
    
    let transition = PopAnimatorImageScale()
    var rotation = false
    
    let dis = DisposeBag()
    
    var mainWindows: UIWindow?
    
    var viewBtnClose: UIImageView?
    
    var convert: CGRect?
    var convertFinal = false
    
    var user = Set<String>()
    
    var userReply: ViewModelTweet?
    var publicReply = false
    
    var image: UIImage? {
        didSet { collectionView.reloadData() }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var btnTweet: UIBarButtonItem?
    var btnClose: UIBarButtonItem?
    var keyboardHeight: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppUtility.lockOrientation(.all)
        self.navigationItem.title = "New Tweet"
        
        self.modalPresentationCapturesStatusBarAppearance = true
        
        
        if #available(iOS 10.0, *) {  self.collectionView.isPrefetchingEnabled = false }
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        inputText.becomeFirstResponder()
        
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification).subscribe(onNext: { notification in
            guard let keyboardEndFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else { return }
            guard let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber else { return }
            self.keyboardHeight = keyboardEndFrame.cgRectValue.height
            
            UIView.animate(withDuration: duration.doubleValue,
                           delay: 0,
                           options: UIView.AnimationOptions(rawValue: UInt(curve.intValue << 16)),
                           animations: {
                            self.bottomEdgeConstraint.constant = keyboardEndFrame.cgRectValue.height
                            self.view.layoutIfNeeded() },
                           completion: { _ in
            })
        }).disposed(by: dis)
        
        var number: Int = 0
        if let reply = userReply{
            inputText.text = "@" + "\(reply.user.screenName) "
            number = 140 - inputText.text.count
        }
        if user.count > 0 {
            for name in user {
                if let user = userReply,  name == "@\(user.user.screenName)" { continue }
                inputText.text = inputText.text + "\(name) "
                number = 140 - inputText.text.count
            }
            if number > 0 {
                charCountLbl.value = "\(number)"
            }
        }
        
        charCountLbl.asObservable().subscribe{ symbol in
            self.collectionView.reloadData()
            if self.scrollBack {
                let cellSize = CGSize(width: UIScreen.main.bounds.width, height: 28)
                let contentOff = self.collectionView.contentOffset
                self.collectionView.scrollRectToVisible(CGRect(x: 0, y: contentOff.y, width: cellSize.width, height: cellSize.height), animated: true)
                self.collectionView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
                self.scrollBack = false
            }
            }.disposed(by: dis)
        
        inputText.delegate = self
        let btnTweet = UIButton(type: .custom)
        btnTweet.setImage(UIImage(named: "tweet"), for: .normal)
        btnTweet.frame = CGRect(x: 0, y: 0, width: 60, height: 24)
        self.btnTweet = UIBarButtonItem(customView: btnTweet)
        self.navigationItem.rightBarButtonItem = self.btnTweet
        self.btnTweet?.isEnabled = false
        
        let btnClose = UIButton(type: .custom)
        btnClose.setImage(UIImage(named: "close"), for: .normal)
        btnClose.frame = CGRect(x: 0, y: 0, width: 60, height: 24)
        self.btnClose = UIBarButtonItem(customView: btnClose)
        self.navigationItem.leftBarButtonItem = self.btnClose
        
        btnClose.rx.tap.subscribe(onNext: {
            self.userReply?.replyBtn.onNext(false)
            if Profile.reloadingProfileTweetsWhenReply > 0 { Profile.reloadingProfileTweetsWhenReply -= 1 }
            if UIDevice.current.orientation.isLandscape {
                let view = self.fullScreenShot()
                self.viewBtnClose = UIImageView(image: view)
                self.viewBtnClose!.frame = self.view.frame
                self.view.addSubview(self.viewBtnClose!)
                self.view.bringSubviewToFront(self.viewBtnClose!)
                self.inputText.resignFirstResponder()
                UIView.animate(withDuration: 0.0, delay: 0, options: .curveEaseOut, animations: {
                    let value = UIInterfaceOrientation.portrait.rawValue
                    UIDevice.current.setValue(value, forKey: "orientation")
                }, completion: { finished in
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                })
            } else {
                self.inputText.resignFirstResponder()
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }).disposed(by: dis)
        
        btnTweet.rx.tap.subscribe(onNext: {
            Profile.reloadingProfileTweetsWhenReply += 1
            self.inputText.resignFirstResponder()
            self.bottomEdgeConstraint.constant = 0.0
            
            let rectProgress = CGRect(x: self.view.bounds.width/2 - 20.0, y: self.view.bounds.height/2 - 20.0, width: 40.0, height: 40.0)
            self.viewProgress = NVActivityIndicatorView(frame: rectProgress, type: .lineScalePulseOut, color: UIColor(red: 255/255, green: 0/255, blue: 104/255, alpha: 1), padding: 0)
            
            self.view.addSubview(self.viewProgress!)
            self.view.bringSubviewToFront(self.viewProgress!)
            self.viewProgress?.startAnimating()
            
            DispatchQueue.global().async {
                if let pic = self.image, self.inputText.text != "" {
                    let data = pic.jpegData(compressionQuality: 0.5)
                    ReplyAndNewTweetVC.instance.publishTweet(status: self.inputText.text, media: data, publicReply: self.publicReply ? nil : self.userReply!.tweetID, complited: { tweet in
                        if self.rotation {
                            self.rotation = false
                        } else {
                            self.dismissTweet()
                        }
                    })
                } else if let pic = self.image {
                    let data = pic.jpegData(compressionQuality: 0.5)
                    ReplyAndNewTweetVC.instance.publishTweet(status: nil, media: data, publicReply: self.publicReply ? nil : self.userReply!.tweetID, complited: { tweet in
                        self.dismissTweet()
                    })
                } else {
                    ReplyAndNewTweetVC.instance.publishTweet(status: self.inputText.text, media: nil, publicReply: self.publicReply ? nil : self.userReply!.tweetID, complited: { tweet in
                        self.dismissTweet()
                    })
                }
            }
            
        }).disposed(by: dis)
    }
    
    private func dismissTweet() {
        if UIDevice.current.orientation.isLandscape {
            let view = self.fullScreenShot()
            self.viewBtnClose = UIImageView(image: view)
            self.viewBtnClose!.frame = self.view.frame
            self.view.addSubview(self.viewBtnClose!)
            self.view.bringSubviewToFront(self.viewBtnClose!)
            self.viewProgress?.stopAnimating()
            self.viewProgress?.removeFromSuperview()
            self.viewProgress = nil
            UIView.animate(withDuration: 0.0, delay: 0, options: .curveEaseOut, animations: {
                let value = UIInterfaceOrientation.portrait.rawValue
                UIDevice.current.setValue(value, forKey: "orientation")
            }, completion: { finished in
                self.presentingViewController?.dismiss(animated: true, completion: {
                    self.userReply?.replyBtn.onNext(false)
                })
            })
        } else {
            self.viewProgress?.stopAnimating()
            self.viewProgress?.removeFromSuperview()
            self.dismiss(animated: true, completion: {
                self.userReply?.replyBtn.onNext(false)
            })
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        UIApplication.shared.isStatusBarHidden = false
        self.viewBtnClose?.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY);
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.rotation = true
        
        self.collectionView.collectionViewLayout.invalidateLayout()
        
        if self.viewProgress != nil {
            coordinator.animate(alongsideTransition: { _ in
                self.viewProgress?.frame.origin = CGPoint(x: size.width/2 - 20.0, y: size.height/2 - 20.0)
            }, completion: { _ in
                if !self.rotation {
                    self.dismissTweet()
                } else {
                    self.rotation = false
                }
            })
        }
        
        if let image = self.viewBtnClose {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            coordinator.animate(alongsideTransition: { (context) in
                let deltaTransform = coordinator.targetTransform
                let deltaAngle = atan2(deltaTransform.b, deltaTransform.a)
                var currentRotation: CGFloat = image.layer.value(forKeyPath: "transform.rotation.z") as! CGFloat
                currentRotation += -1 * deltaAngle + 0.0001
                image.layer.setValue(currentRotation, forKeyPath: "transform.rotation.z")
            }, completion: { (context) in
                var currentTransform: CGAffineTransform = image.transform
                currentTransform.a = round(currentTransform.a)
                currentTransform.b = round(currentTransform.b)
                currentTransform.c = round(currentTransform.c)
                currentTransform.d = round(currentTransform.d)
                image.transform = currentTransform
            })
        }
    }
    
    func fullScreenShot() -> UIImage? {
        let imgSize = UIScreen.main.bounds.size
        UIGraphicsBeginImageContextWithOptions(imgSize, false, 0.0)
        for window in UIApplication.shared.windows {
            if window.responds(to: #selector(getter: UIWindow.screen)) || window.screen == UIScreen.main {
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
        }
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        inputText.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.mainWindows = nil
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if inputText.text != "" {
            print(inputText.text)
            btnTweet?.isEnabled = true
        } else {
            charCountLbl.value = String(140 - inputText.text.count)
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if inputText.text == "" {
            btnTweet?.isEnabled = false
        }
    }
    func textViewDidChange(_ textView: UITextView) {
        if inputText.text.count > 0 && inputText.text.count < 140  {
            charCountLbl.value = String(140 - inputText.text.count)
            btnTweet?.isEnabled = true
        } else {
            btnTweet?.isEnabled = false
            charCountLbl.value = String(140 - inputText.text.count)
        }
    }
}

extension ReplyAndNewTweetVC: ButtonAction {
    
    func label(symbol: String, text: String, photo: Bool, photoName: String, convert: CGRect) {
        
        if photo {
            if photoName == "photoIcon" {
                if self.mainWindows == nil {
                    mainWindows = UIWindow(frame: self.view.window!.frame)
                    mainWindows!.windowLevel =  UIApplication.shared.windows.last!.windowLevel + 1
                    mainWindows!.isHidden = false
                } else {
                    self.mainWindows?.isHidden = false
                }
                
                let keyboardStay = KeyboardStayAppearedVC(nibName: "KeyboardStayAppearedVC", bundle: nil)
                
                mainWindows!.rootViewController = keyboardStay
                let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
                controller.transitioningDelegate = self
                controller.modalPresentationStyle = .custom
                controller.delegateModally = self
                controller.variety = VarietyModally.photo
                keyboardStay.present(controller, animated: true, completion: nil)
                if UIDevice.current.orientation.isLandscape {
                    controller.heightFirstBtn.constant = 50.0
                    controller.heightSecondBtn.constant = 50.0
                    controller.heightThirdBnt.constant = 50.0
                    controller.spaceBetweenFirstAndTwoBtn.constant = (ConstantMeasure.modalHeightThreeBtn - 42.0) - self.keyboardHeight! > 0 ? ConstantMeasure.spaceBetweetFirstAndSecondBtn - ((ConstantMeasure.modalHeightThreeBtn - 42.0) - self.keyboardHeight!) : ConstantMeasure.spaceBetweetFirstAndSecondBtn + ((ConstantMeasure.modalHeightThreeBtn - 42.0) - self.keyboardHeight!)
                    
                    controller.thirdBtn.setImage(UIImage(named: "btnModalyRotateMakePhoto"), for: .normal)
                    controller.secondBtn.setImage(UIImage(named: "btnModalyRotateLibrary"), for: .normal)
                    controller.cancelBtn.setImage(UIImage(named: "btnModalyRotateCancel"), for: .normal)
                    
                } else {
                    controller.spaceBetweenFirstAndTwoBtn.constant = ConstantMeasure.modalHeightThreeBtn - self.keyboardHeight! > 0 ? ConstantMeasure.spaceBetweetFirstAndSecondBtn - ConstantMeasure.modalHeightThreeBtn - self.keyboardHeight! : ConstantMeasure.spaceBetweetFirstAndSecondBtn - (ConstantMeasure.modalHeightThreeBtn - self.keyboardHeight!)
                    controller.thirdBtn.setImage(UIImage(named: "btnModalyMakePhoto"), for: .normal)
                    controller.secondBtn.setImage(UIImage(named: "btnModalyLibrary"), for: .normal)
                }
                
            } else if photoName == "pic" {
                if self.mainWindows == nil {
                    mainWindows = UIWindow(frame: self.view.window!.frame)
                    mainWindows!.windowLevel =  UIApplication.shared.windows.last!.windowLevel + 1
                    mainWindows!.isHidden = false
                } else {
                    self.mainWindows?.isHidden = false
                }
                
                let keyboardStay = KeyboardStayAppearedVC(nibName: "KeyboardStayAppearedVC", bundle: nil)
                
                mainWindows!.rootViewController = keyboardStay
                self.convertFinal = false
                self.convert = convert
                let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
                controller.transitioningDelegate = self
                controller.modalPresentationStyle = .custom
                controller.delegateModally = self
                controller.variety = VarietyModally.pic
                keyboardStay.present(controller, animated: true, completion: nil)
                
                if UIDevice.current.orientation.isLandscape {
                    controller.heightFirstBtn.constant = 50.0
                    controller.heightSecondBtn.constant = 50.0
                    controller.heightThirdBnt.constant = 50.0
                    controller.spaceBetweenFirstAndTwoBtn.constant = (ConstantMeasure.modalHeightThreeBtn - 42.0) - self.keyboardHeight! > 0 ? ConstantMeasure.spaceBetweetFirstAndSecondBtn - ((ConstantMeasure.modalHeightThreeBtn - 42.0) - self.keyboardHeight!) : ConstantMeasure.spaceBetweetFirstAndSecondBtn + ((ConstantMeasure.modalHeightThreeBtn - 42.0) - self.keyboardHeight!)
                    
                    controller.thirdBtn.setImage(UIImage(named: "btnModalyRotateRemove"), for: .normal)
                    controller.secondBtn.setImage(UIImage(named: "btnModalyRotateShowImage"), for: .normal)
                    controller.cancelBtn.setImage(UIImage(named: "btnModalyRotateCancel"), for: .normal)
                } else {
                    controller.spaceBetweenFirstAndTwoBtn.constant = ConstantMeasure.modalHeightThreeBtn - self.keyboardHeight! > 0 ? ConstantMeasure.spaceBetweetFirstAndSecondBtn - ConstantMeasure.modalHeightThreeBtn - self.keyboardHeight! : ConstantMeasure.spaceBetweetFirstAndSecondBtn - (ConstantMeasure.modalHeightThreeBtn - self.keyboardHeight!)
                    controller.thirdBtn.setImage(UIImage(named: "btnModalyRemove"), for: .normal)
                    controller.secondBtn.setImage(UIImage(named: "btnModalyShowImage"), for: .normal)
                }
            }
        } else {
            self.countText = text
            self.inputText.text.append(symbol)
            collectionView.reloadData()
            let cellSize = CGSize(width: UIScreen.main.bounds.width, height: 28)
            let contentOff = collectionView.contentOffset
            collectionView.scrollRectToVisible(CGRect(x: contentOff.x + 10 + cellSize.width, y: contentOff.y, width: cellSize.width, height: cellSize.height), animated: true)
            scrollBack = true
        }
    }
}

extension ReplyAndNewTweetVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell1", for: indexPath) as! Cell1
            cell.image = self.image
            cell.config(image: self.image)
            cell.countLbl.text = charCountLbl.value
            cell.delegate = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell2", for: indexPath) as! Cell2
            cell.textInfo.text = countText
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.size.width, height: 37)
    }
}

extension ReplyAndNewTweetVC: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = SlideInPresentationController(presentedViewController: presented, presenting: presenting, keyboardHeight: keyboardHeight!)
        return presentationController
    }
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if self.convertFinal {
            transition.originFrame = convert!
            transition.deltaOffsetHeightInitial = UIScreen.main.bounds.size.height - self.keyboardHeight!
            transition.presenting = true
            return transition
        }
        return SlideInPresentationAnimator(isPresentation: true)
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if self.convertFinal {
            transition.presenting = false
            transition.deltaOffsetHeightFinale = UIScreen.main.bounds.size.height - self.keyboardHeight!
            transition.delegate = self
            return transition
        }
        return SlideInPresentationAnimator(isPresentation: false)
    }
}

extension ReplyAndNewTweetVC: ModallyDelegate, KeyTop {
    
    func keyboardTop() { self.mainWindows?.isHidden = true; self.convertFinal = false }
    
    func modally(image: UIImage?, variety: VarietyModally?, helper: SomeTweetsData?) {
        AppUtility.lockOrientation(.all)
        if let pic = image {
            self.image = pic
            btnTweet?.isEnabled = true
        }
        if let variety = variety {
            if variety == .pic {
                let index = IndexPath(row: 0, section: 0)
                var the = UICollectionViewLayoutAttributes()
                the = collectionView.layoutAttributesForItem(at: index)!
                the.frame = CGRect(x: the.frame.origin.x + (convert?.origin.x)!, y: the.frame.origin.y + (convert?.origin.y)!, width: (convert?.width)!, height: (convert?.height)!)
                let cellFrameInSuperview: CGRect!  = collectionView.convert(the.frame, to: collectionView.superview)
                self.convert = cellFrameInSuperview
                self.convertFinal = true
                
                if self.mainWindows == nil {
                    mainWindows = UIWindow(frame: self.view.window!.frame)
                    mainWindows!.windowLevel =  UIApplication.shared.windows.last!.windowLevel + 1
                    mainWindows!.isHidden = false
                } else {
                    self.mainWindows?.isHidden = false
                }
                
                let keyboardStay = KeyboardStayAppearedVC(nibName: "KeyboardStayAppearedVC", bundle: nil)
                
                mainWindows!.rootViewController = keyboardStay
                let imageScaleController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoScaleSimpleVC") as! PhotoScaleSimpleVC
                imageScaleController.transitioningDelegate = self
                imageScaleController.image = self.image
                let array: Array<Any> = [keyboardStay, imageScaleController]
                perform(#selector(performModalImageShow), with: array, afterDelay: 0.0)
            }
            
            if variety == .cancel { self.mainWindows?.isHidden = true }
            if variety == .removePic {
                self.image = nil
                self.mainWindows?.isHidden = true
                if self.inputText.text.isEmpty {
                    btnTweet?.isEnabled = false
                }
            }
            if variety == .imageLibrary {
                self.imagePicker.sourceType = .photoLibrary
                let keyboardStay = KeyboardStayAppearedVC(nibName: "KeyboardStayAppearedVC", bundle: nil)
                mainWindows!.rootViewController = keyboardStay
                perform(#selector(imagePickerAppeare), with: keyboardStay, afterDelay: 0.0)
            }
            if variety == .makePhotoOrVideo {
                let keyboardStay = KeyboardStayAppearedVC(nibName: "KeyboardStayAppearedVC", bundle: nil)
                mainWindows!.rootViewController = keyboardStay
                perform(#selector(imagePickerAppeare), with: keyboardStay, afterDelay: 0.0)
            }
        }
    }
    @objc func imagePickerAppeare(keyboard: KeyboardStayAppearedVC) {
        keyboard.present(self.imagePicker, animated: true, completion: nil)
    }
    
    @objc func performModalImageShow(array: Array<Any>) {
        let first = array[0] as! KeyboardStayAppearedVC
        let second = array[1] as! PhotoScaleSimpleVC
        first.present(second, animated: true, completion: nil)
    }
}
extension ReplyAndNewTweetVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        let pic = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage
        picker.dismiss(animated: true, completion: {
            self.image = pic
            self.btnTweet?.isEnabled = true
            self.mainWindows?.isHidden = true
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: {
            self.mainWindows?.isHidden = true
        })
    }
}

extension UIImagePickerController {
    open override var shouldAutorotate: Bool { return true }
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .all }
}



// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
