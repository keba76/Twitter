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

protocol ButtonAction {
    func label(symbol: String, text: String, photo: Bool, photoName: String, convert: CGRect)
}
extension ButtonAction {
    func extensionLabel(symbol: String = "", text: String = "", photo: Bool = false, photoName: String = "", convert: CGRect = CGRect.zero) {
        label(symbol: symbol, text: text, photo: photo, photoName: photoName, convert: convert)
    }
}

class Cell1: UICollectionViewCell {
    
    let dis = DisposeBag()
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
        if btnPhoto.imageView?.image == UIImage(named: "photo1") {
            btnPhoto.rx.tap.subscribe(onNext: { [unowned self] _ in
                if self.btnPhoto.imageView?.image == UIImage(named: "photo1") {
                    self.delegate?.extensionLabel(photo: true, photoName: "photoIcon")
                } else {
                    self.delegate?.extensionLabel(photo: true, photoName: "pic", convert: self.convert(self.btnPhoto.frame, to: self.contentView))
                }
            }).addDisposableTo(dis)
        }
        
        btnHashtag.rx.tap.asObservable().subscribe(onNext: { _ in
            self.delegate?.extensionLabel(symbol: "#", text: "Start Typing a Tag...")
        }).addDisposableTo(dis)
        btnAt.rx.tap.asObservable().subscribe(onNext: { _ in
            self.delegate?.extensionLabel(symbol: "@", text: "Start Typing a Name...")
        }).addDisposableTo(dis)
    }
}
class Cell2: UICollectionViewCell {
    @IBOutlet weak var textInfo: UILabel!
}

class ReplyAndNewTweetVC: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var inputText: UITextView!
    
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    
    var countText: String?
    var countChar: String?
    var charCountLbl = Variable("140")
    
    static let instance = TwitterClient()
    
    var fromSnapshot: UIView?
    
    var scrollBack = false
    
    var viewProgress: NVActivityIndicatorView?
    
    let transition = PopAnimatorImageScale()
    
    let dis = DisposeBag()
    
    var convert: CGRect?
    var convertFinal = false
    
    //var delegate: ModallyDelegate?
    //var reply = false
    
    var user = Set<String>()
    
    var userReply: ViewModelTweet?
    
    var image: UIImage? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var btnTweet: UIBarButtonItem?
    var btnClose: UIBarButtonItem?
    //var replyTweet: Tweet?
    var keyboardHeight: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 10.0, *) {
            self.collectionView.isPrefetchingEnabled = false
        }
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        inputText.becomeFirstResponder()
        
        NotificationCenter.default.rx.notification(.UIKeyboardWillShow).subscribe(onNext: { notification in
            if let keyboardRectValue = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                self.keyboardHeight = keyboardRectValue.height
            }
        }).addDisposableTo(dis)
        var number: Int = 0
        if let reply = userReply{
            inputText.text = "@" + "\(reply.user.screenName) "
            //charCountLbl.value = String(140 - inputText.text.characters.count)
            number = 140 - inputText.text.characters.count
        }
        if user.count > 0 {
            for name in user {
                if let user = userReply,  name == "@\(user.user.screenName)" {
                    continue
                }
                inputText.text = inputText.text + "\(name) "
                // print(inputText.text)
                number = number - name.characters.count - 1
            }
            
            if number > 0 {
                charCountLbl.value = "\(number)"
            }
        }
        
        charCountLbl.asObservable().subscribe{ symbol in
            self.collectionView.reloadData()
            if self.scrollBack {
                let cellSize = CGSize(width: 365, height: 28)
                let contentOff = self.collectionView.contentOffset
                if self.collectionView.contentSize.width <= self.collectionView.contentOffset.x + cellSize.width
                {
                    self.collectionView.scrollRectToVisible(CGRect(x: 0, y: contentOff.y, width: cellSize.width, height: cellSize.height), animated: true)
                    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                    
                } else {
                    self.collectionView.scrollRectToVisible(CGRect(x: -contentOff.x - 10 + cellSize.width, y: contentOff.y, width: cellSize.width, height: cellSize.height), animated: true)
                    
                }
                self.scrollBack = false
            }
            }.addDisposableTo(dis)
        
        inputText.delegate = self
        let btnTweet = UIButton(type: .custom)
        btnTweet.setImage(UIImage(named: "tweet"), for: .normal)
        btnTweet.frame = CGRect(x: 0, y: 0, width: 60, height: 29)
        self.btnTweet = UIBarButtonItem(customView: btnTweet)
        self.navigationItem.rightBarButtonItem = self.btnTweet
        self.btnTweet?.isEnabled = false
        
        let btnClose = UIButton(type: .custom)
        btnClose.setImage(UIImage(named: "close"), for: .normal)
        btnClose.frame = CGRect(x: 0, y: 0, width: 60, height: 29)
        self.btnClose = UIBarButtonItem(customView: btnClose)
        self.navigationItem.leftBarButtonItem = self.btnClose
        
        btnClose.rx.tap.subscribe(onNext: {
            self.inputText.resignFirstResponder()
            self.dismiss(animated: true, completion: {
                self.userReply?.replyBtn.onNext(false)
            })
        }).addDisposableTo(dis)
        btnTweet.rx.tap.subscribe(onNext: {
            self.inputText.resignFirstResponder()
            self.textViewHeightConstraint.constant = UIScreen.main.bounds.height - 48.0
            
            let rectProgress = CGRect(x: self.view.bounds.width/2 - 25.0, y: self.view.bounds.height/2 - 25.0, width: 50.0, height: 50.0)
            self.viewProgress = NVActivityIndicatorView(frame: rectProgress, type: .lineScalePulseOut, color: UIColor(red: 255/255, green: 0/255, blue: 104/255, alpha: 1), padding: 0)
            
            self.view.addSubview(self.viewProgress!)
            self.view.bringSubview(toFront: self.viewProgress!)
            self.viewProgress?.startAnimating()
            
            
            DispatchQueue.global().async {
                if let pic = self.image, self.inputText.text != "" {
                    let data = UIImageJPEGRepresentation(pic, 0.5)
                    ReplyAndNewTweetVC.instance.publishTweet(status: self.inputText.text, media: data, complited: { tweet in
                        self.viewProgress?.stopAnimating()
                        self.dismiss(animated: true, completion: {
                            self.userReply?.replyBtn.onNext(false)
                        })
                    })
                } else if let pic = self.image {
                    let data = UIImageJPEGRepresentation(pic, 0.5)
                    ReplyAndNewTweetVC.instance.publishTweet(status: nil, media: data, complited: { tweet in
                        self.viewProgress?.stopAnimating()
                        self.dismiss(animated: true, completion: {
                            self.userReply?.replyBtn.onNext(false)
                        })
                    })
                } else {
                    ReplyAndNewTweetVC.instance.publishTweet(status: self.inputText.text, media: nil, complited: { tweet in
                        self.viewProgress?.stopAnimating()
                        self.dismiss(animated: true, completion: {
                            self.userReply?.replyBtn.onNext(false)
                        })
                    })
                }
                
            }
            
        }).addDisposableTo(dis)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        inputText.becomeFirstResponder()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if inputText.text != "" {
            print(inputText.text)
            btnTweet?.isEnabled = true
            //charCountLbl = "140"
        } else {
            charCountLbl.value = String(140 - inputText.text.characters.count)
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if inputText.text == "" {
            btnTweet?.isEnabled = false
        }
    }
    func textViewDidChange(_ textView: UITextView) {
        if inputText.text.characters.count > 0 && inputText.text.characters.count < 140  {
            charCountLbl.value = String(140 - inputText.text.characters.count)
            btnTweet?.isEnabled = true
        } else {
            btnTweet?.isEnabled = false
            charCountLbl.value = String(140 - inputText.text.characters.count)
        }
    }
}

extension ReplyAndNewTweetVC: ButtonAction {
    
    func label(symbol: String, text: String, photo: Bool, photoName: String, convert: CGRect) {
        
        if photo {
            if photoName == "photoIcon" {
                let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
                
                controller.transitioningDelegate = self
                controller.modalPresentationStyle = .custom
                controller.delegateModally = self
                let rootViewController: UIViewController =
                    (UIApplication.shared.windows.last?.rootViewController!)!
                controller.variety = VarietyModally.photo
                rootViewController.present(controller, animated: true, completion: nil)
                controller.thirdBtn.setImage(UIImage(named: "takePhoto"), for: .normal)
                controller.secondBtn.setImage(UIImage(named: "takeLibrary"), for: .normal)
                
                
            } else if photoName == "pic" {
                self.convertFinal = false
                self.convert = convert
                let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ModallyVC") as! ModallyVC
                controller.transitioningDelegate = self
                controller.modalPresentationStyle = .custom
                controller.delegateModally = self
                let rootViewController: UIViewController =
                    (UIApplication.shared.windows.last?.rootViewController!)!
                controller.variety = VarietyModally.pic
                rootViewController.present(controller, animated: true, completion: nil)
                controller.thirdBtn.setImage(UIImage(named: "takeRemove"), for: .normal)
                controller.imageMiniature = self.imageWithImage(image: image!, scaledToSize: CGSize(width: 35, height: 35))
                controller.secondBtn.setImage(UIImage(named: "takeShowImage"), for: .normal)
                controller.image = self.image
                print(self.image!.size)
                
            }
        } else {
            self.countText = text
            self.inputText.text.append(symbol)
            collectionView.reloadData()
            let cellSize = CGSize(width: 365, height: 28)
            let contentOff = collectionView.contentOffset
            if collectionView.contentSize.width <= collectionView.contentOffset.x + cellSize.width
            {
                collectionView.scrollRectToVisible(CGRect(x: 0, y: contentOff.y, width: cellSize.width, height: cellSize.height), animated: true)
                
            } else {
                collectionView.scrollRectToVisible(CGRect(x: contentOff.x + 10 + cellSize.width, y: contentOff.y, width: cellSize.width, height: cellSize.height), animated: true)
                
            }
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
            cell.countLbl.text = charCountLbl.value
            cell.delegate = self
            if image != nil {
                cell.btnPhoto.imageView?.contentMode = .scaleAspectFill
                cell.btnPhoto.setImage(image!, for: .normal)
                //cell.btnPhoto.setImage(self.imageWithImage(image: image!, scaledToSize: CGSize(width: 35, height: 35)), for: .normal)
                cell.image = self.image
            } else {
                cell.btnPhoto.setImage(UIImage(named: "photo1"), for: .normal)
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell2", for: indexPath) as! Cell2
            cell.textInfo.text = countText
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 365, height: 37)
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
            transition.presenting = true
            return transition
        }
        return SlideInPresentationAnimator(isPresentation: true)
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if self.convertFinal {
            
            transition.presenting = false
            self.convertFinal = false
            return transition
        }
        return SlideInPresentationAnimator(isPresentation: false)
    }
}

extension ReplyAndNewTweetVC: ModallyDelegate {
    
    
    
    func modally(image: UIImage?, variety: VarietyModally?, helper: SomeTweetsData?) {
        self.image = image
        btnTweet?.isEnabled = self.image != nil ? true : false
        if let variety = variety {
            if variety == .pic {
                let index = IndexPath(row: 0, section: 0)
                var the = UICollectionViewLayoutAttributes()
                the = collectionView.layoutAttributesForItem(at: index)!
                the.frame = CGRect(x: the.frame.origin.x + (convert?.origin.x)!, y: the.frame.origin.y + (convert?.origin.y)!, width: (convert?.width)!, height: (convert?.height)!)
                let cellFrameInSuperview:CGRect!  = collectionView.convert(the.frame, to: collectionView.superview)
                self.convert = cellFrameInSuperview
                
                self.convertFinal = true
                let imageScaleController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoScaleSimpleVC") as! PhotoScaleSimpleVC
                imageScaleController.transitioningDelegate = self
                imageScaleController.image = self.image
                
                present(imageScaleController, animated: true, completion: nil)
                
            }
        }
    }
}
