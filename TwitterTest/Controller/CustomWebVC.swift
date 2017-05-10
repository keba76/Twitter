//
//  CustomWebVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 4/15/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit

public class CustomWebVC: UIViewController {
    
    var swifter: Swifter?
    
    @IBOutlet weak var  webView: UIWebView!
    var requestToken: Credential.OAuthAccessToken?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        let failureHandler: (Error) -> Void = { error in
            self.alert(title: "Error", message: error.localizedDescription)
        }
        
        NotificationCenter.default.addObserver(forName: .SwifterCallbackNotification, object: nil, queue: .main) { notification in
            NotificationCenter.default.removeObserver(self)
            
            self.dismiss(animated: true, completion: nil)
            
            let url = notification.userInfo![Swifter.CallbackNotification.optionsURLKey] as! URL
            
            let parameters = url.query!.queryStringParameters
            self.requestToken?.verifier = parameters["oauth_verifier"]
            
            self.swifter?.postOAuthAccessToken(with: self.requestToken!, success: { accessToken, response in
                self.swifter?.client.credential = Credential(accessToken: accessToken!)
                TwitterClient.swifter = self.swifter
                
                let fileURL = Credential.dataFileURL()
                let data = Credential.OAuthAccessToken.Coding(event: (self.swifter?.client.credential?.accessToken)!)
                
                let dataNew = NSMutableData()
                let archiver = NSKeyedArchiver(forWritingWith: dataNew)
                archiver.encode(data, forKey: "rootKey")
                archiver.finishEncoding()
                dataNew.write(to: fileURL, atomically: true)
                
            }, failure: failureHandler)
        }
    }
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
