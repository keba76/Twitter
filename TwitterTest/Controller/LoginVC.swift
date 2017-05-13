//
//  LoginVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/11/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift

class LoginVC: UIViewController, UIViewControllerTransitioningDelegate, UIWebViewDelegate {
    
    var swifter: Swifter
    
    var dummyWebViewInFirstVC: UIWebView?
    
    let transition = BubbleTransition()
    
    var progress: NVActivityIndicatorView?
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var subtitleLbl: UILabel!
    @IBOutlet weak var logo: UIImageView!
    let dis = DisposeBag()
    var authorize = false
    var loadWeb = false
    
    var btn: TKTransitionSubmitButton!
    var requestToken: Credential.OAuthAccessToken?
    
    static var token: String?
    
    required init?(coder aDecoder: NSCoder) {
        self.swifter = Swifter(consumerKey: "cjU5R9BJRgdoae2R4QngvRumt", consumerSecret: "ugmAekQO24abRoYDUZ4d3q1EHMCftVrSu0Sy875ApVbK4fh2QF")
        super.init(coder: aDecoder)
    }
    
    @IBOutlet weak var logoVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoMovedToTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoHeightOriginalConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoHeihtSmallerConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let failureHandler: (Error) -> Void = { error in
            self.alert(title: "Error", message: error.localizedDescription)
        }
        
        btn = TKTransitionSubmitButton(frame: CGRect(x: 0, y: 0, width: self.titleLbl.frame.width, height: 37))
        btn.center = self.view.center
        btn.frame.y = self.subtitleLbl.frame.maxY + 30.0
        btn.backgroundColor = UIColor.white
        btn.setTitle("Sign in", for: UIControlState())
        self.view.addSubview(btn)
        btn.titleLabel?.font = UIFont(name: "HelveticaNeue-Regular", size: 14)
        btn.setTitleColor(UIColor(red: 22/257, green: 185/257, blue: 237/257, alpha: 1.0), for: .normal)
        
        btn.rx.tap.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: {
            self.btn.startLoadingAnimation()
            
            self.dummyWebViewInFirstVC = UIWebView(frame: CGRect(x: 0.0, y: 20.0, width: self.view.frame.width, height: self.view.frame.height - 20.0))
            self.dummyWebViewInFirstVC?.delegate = self
            self.swifter.postOAuthRequestToken(with: URL(string: "TwitterTest://success")!, success: { token, response in
                self.requestToken = token!
                
                let authorizeURL = URL(string: "oauth/authorize", relativeTo: TwitterURL.oauth.url)
                let queryURL = URL(string: authorizeURL!.absoluteString + "?oauth_token=\(token!.key)")!
                
                self.dummyWebViewInFirstVC?.loadRequest(URLRequest(url: queryURL))
                
            }, failure: failureHandler)
            
            self.authorize = true
        }).addDisposableTo(dis)
        
        btn.alpha = 0
        titleLbl.alpha = 0
        subtitleLbl.alpha = 0
        //UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !self.authorize {
            self.logoVerticalConstraint.isActive = false
            self.logoMovedToTopConstraint.isActive = true
            self.logoHeightOriginalConstraint.isActive = false
            self.logoHeihtSmallerConstraint.isActive = true
            
            UIView.animate(withDuration: 1.5) {
                self.view.layoutIfNeeded()
                
                self.btn.alpha = 1
                self.titleLbl.alpha = 1
                self.subtitleLbl.alpha = 1
                
                self.btn.frame = self.btn.frame.offsetBy(dx: 0, dy: -30)
                self.titleLbl.frame = self.titleLbl.frame.offsetBy(dx: 0, dy: -30)
                self.subtitleLbl.frame = self.subtitleLbl.frame.offsetBy(dx: 0, dy: -30)
            }
            self.btn.spiner.spinnerColor = self.btn.spinnerColor
        } else if loadWeb {
            var timer = false
            let rectProgress = CGRect(x: self.view.bounds.width/2 - 67.0, y: self.view.bounds.height/2 - 67.0, width: 134.0, height: 134.0)
            self.progress = NVActivityIndicatorView(frame: rectProgress, type: .ballScale, color: UIColor.white, padding: 12)
            self.view.addSubview(self.progress!)
            self.view.bringSubview(toFront: self.progress!)
            self.progress?.startAnimating()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3, execute: {
                timer = true
            })
            TwitterClient.swifter.verifyAccountCredentials(includeEntities: false, skipStatus: true, success: { json in
                let user = ModelUser(parse: User(dict: json))
                Profile.account = user
                TwitterClient.swifter.getUserFollowersIDs(for: .id(user.id), count: 5000, success: { (json, _ , nextCursor) in
                    Profile.arrayIdFollowers = json.array ?? []
                }, failure: { error in print(error.localizedDescription)})
                
            }, failure: { error in print(error.localizedDescription)})
            
            TwitterClient.swifter.getHomeTimeline(count: 12, maxID: nil, success: { json in
                guard let twee = json.array else { return }
                let viewModel =  twee
                    .map {Tweet(dict: $0)}
                    .map {ModelTweet(parse: $0)}
                    .map {ViewModelTweet(modelTweet: $0)}
                Profile.startTimeLine = viewModel
                if timer {
                    self.performSegue(withIdentifier: "LoginVC", sender: self)
                    self.progress?.stopAnimating()
                    self.progress?.removeFromSuperview()
                    self.progress = nil
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.3, execute: {
                        self.performSegue(withIdentifier: "LoginVC", sender: self)
                        self.progress?.stopAnimating()
                        self.progress?.removeFromSuperview()
                        self.progress = nil
                    })
                }
            }, failure: { error in print(error.localizedDescription)})
        }
    }
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if loadWeb {
            return nil
        } else {
            return TKFadeInAnimator(transitionDuration: 0.5, startingAlpha: 0.8)
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if loadWeb {
            return transition
        } else {
            return nil
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if loadWeb {
            self.logoMovedToTopConstraint.isActive = false
            self.logoHeihtSmallerConstraint.isActive = false
            self.logoVerticalConstraint = self.logo.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
            self.logoHeightOriginalConstraint = self.logo.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.1)
            self.logoVerticalConstraint.isActive = true
            self.logoHeightOriginalConstraint.isActive = true
            self.btn.alpha = 0
            self.titleLbl.alpha = 0
            self.subtitleLbl.alpha = 0
            
            self.presentingViewController?.modalPresentationStyle = .custom
        } else {
            self.btn.startFinishAnimation(0) {
                
                let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "CustomWebVC") as! CustomWebVC
                controller.requestToken = self.requestToken
                controller.swifter = self.swifter
                controller.transitioningDelegate = self
                self.present(controller, animated: true, completion: nil)
                controller.webView.addSubview(self.dummyWebViewInFirstVC!)
                self.loadWeb = true
            }
        }
    }
}






