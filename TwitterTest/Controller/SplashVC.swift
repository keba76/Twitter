//
//  SplashVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/11/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import Social
import Accounts

class SplashVC: UIViewController, SegueHandlerType {
    
    enum SegueIdentifier : String {
        case LoginVC
        case TabTaped
    }
    var swifter: Swifter!
    var progress: NVActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let fileURL = Credential.dataFileURL()
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccounts(with: accountType, options: nil) { granted, error in
            guard granted else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.alertWithHandler(title: "Warning", message: "There are no Twitter accounts configured. You can add a Twitter account in Settings.", handler: {
                        self.performSegueWithIdentifier(segueIdentifier: .LoginVC, sender: self)
                    })
                })
                //self.alert(title: "Error", message: error!.localizedDescription)
                return
            }
            let twitterAccounts = accountStore.accounts(with: accountType)!
            if !twitterAccounts.isEmpty {
                DispatchQueue.main.async {
                    let rectProgress = CGRect(x: self.view.bounds.width/2 - 67.0, y: self.view.bounds.height/2 - 67.0, width: 134.0, height: 134.0)
                    self.progress = NVActivityIndicatorView(frame: rectProgress, type: .ballScale, color: UIColor.white, padding: 12)
                    self.view.addSubview(self.progress!)
                    self.view.bringSubviewToFront(self.progress!)
                    self.progress?.startAnimating()
                    let twitterAccount = twitterAccounts[0] as! ACAccount
                    self.swifter = Swifter(account: twitterAccount)
                    TwitterClient.swifter = self.swifter
                    
                    self.getSomeDataAndSegue()
                }
                
            } else if FileManager.default.fileExists(atPath: fileURL.path) {
                DispatchQueue.main.async {
                    let rectProgress = CGRect(x: self.view.bounds.width/2 - 67.0, y: self.view.bounds.height/2 - 67.0, width: 134.0, height: 134.0)
                    self.progress = NVActivityIndicatorView(frame: rectProgress, type: .ballScale, color: UIColor.white, padding: 12)
                    self.view.addSubview(self.progress!)
                    self.view.bringSubviewToFront(self.progress!)
                    self.progress?.startAnimating()
                    let data = try! Data(contentsOf: fileURL)
                    NSKeyedUnarchiver.setClass(Credential.OAuthAccessToken.Coding.classForKeyedUnarchiver(), forClassName: "Credential")
                    let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
                    
                    let dataNew = unarchiver.decodeObject(forKey: "rootKey") as! Credential.OAuthAccessToken.Coding
                    unarchiver.finishDecoding()
                    
                    self.swifter = Swifter(consumerKey: "cjU5R9BJRgdoae2R4QngvRumt", consumerSecret: "ugmAekQO24abRoYDUZ4d3q1EHMCftVrSu0Sy875ApVbK4fh2QF")
                    self.swifter.client.credential = Credential(accessToken: dataNew.event!)
                    TwitterClient.swifter = self.swifter
                    self.getSomeDataAndSegue()
                }
                
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.alertWithHandler(title: "Warning", message: "There are no Twitter accounts configured. You can add a Twitter account in Settings.", handler: {
                        self.performSegueWithIdentifier(segueIdentifier: .LoginVC, sender: self)
                    })
                })
            }
        }
    }
    
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    func alertWithHandler(title: String, message: String, handler: @escaping () -> () ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            handler()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func getSomeDataAndSegue() {
        let myGroup = DispatchGroup()
        myGroup.enter()
        TwitterClient.swifter.verifyAccountCredentials(includeEntities: false, skipStatus: true, success: { json in
            let user = ModelUser(parse: User(dict: json))
            Profile.account = user
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4, execute: { myGroup.leave() })
            TwitterClient.swifter.getUserFollowersIDs(for: .id(user.id), count: 5000, success: { (json, _ , nextCursor) in
                Profile.arrayIdFollowers = json.array ?? []
            }, failure: { error in
                print(error.localizedDescription)})
        }, failure: { error in print(error.localizedDescription)})
        myGroup.enter()
        TwitterClient.swifter.getHomeTimeline(count: 30, maxID: nil, success: { json in
            //print(json)
            guard let twee = json.array else { return }
            let viewModel =  twee
                .map {Tweet(dict: $0)}
                .map {ModelTweet(parse: $0)}
                .map {ViewModelTweet(modelTweet: $0)}
            Profile.startTimeLine = viewModel
            myGroup.leave()
        }, failure: { error in print(error.localizedDescription)})
        myGroup.notify(queue: .main) {
            self.performSegueWithIdentifier(segueIdentifier: .TabTaped, sender: self)
            self.progress?.stopAnimating()
            self.progress?.removeFromSuperview()
            self.progress = nil
        }
    }
}




