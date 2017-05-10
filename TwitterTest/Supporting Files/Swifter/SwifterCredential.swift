//
//  Credential.swift
//  Swifter
//
//  Copyright (c) 2014 Matt Donnelly.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import Accounts

public class Credential {
    
    public struct OAuthAccessToken {
        
        public internal(set) var key: String
        public internal(set) var secret: String
        public internal(set) var verifier: String?
        
        public internal(set) var screenName: String?
        public internal(set) var userID: String?
        
        public init(key: String, secret: String) {
            self.key = key
            self.secret = secret
        }
        
        public init(key: String, secret: String, screenName: String, userID: String) {
            self.key = key
            self.secret = secret
            self.screenName = screenName
            self.userID = userID
        }
        
        public init(queryString: String) {
            var attributes = queryString.queryStringParameters
            
            self.key = attributes["oauth_token"]!
            self.secret = attributes["oauth_token_secret"]!
            
            self.screenName = attributes["screen_name"]
            self.userID = attributes["user_id"]
        }
        
        class Coding: NSObject, NSCoding {
            let event: OAuthAccessToken?
            
            init(event: OAuthAccessToken) {
                self.event = event
                super.init()
            }
            required init?(coder aDecoder: NSCoder) {
                guard let key = aDecoder.decodeObject(forKey: "key") as? String, let secret = aDecoder.decodeObject(forKey: "secret") as? String, let screenName = aDecoder.decodeObject(forKey: "screenName") as? String, let userID = aDecoder.decodeObject(forKey: "userID") as? String else { return nil }
                event = OAuthAccessToken(key: key, secret: secret, screenName: screenName, userID: userID)
                super.init()
            }
            func encode(with aCoder: NSCoder) {
                guard let event = event else { return }
                aCoder.encode(event.key, forKey: "key")
                aCoder.encode(event.secret, forKey: "secret")
                aCoder.encode(event.screenName, forKey: "screenName")
                aCoder.encode(event.userID, forKey: "userID")
            }
        }
    }
    
    public internal(set) var accessToken: OAuthAccessToken?
    public internal(set) var account: ACAccount?
    
    
    public init(accessToken: OAuthAccessToken) {
        self.accessToken = accessToken
    }
    
    public init(account: ACAccount) {
        self.account = account
    }
    
    static func dataFileURL() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        var url: URL? = URL(fileURLWithPath: "")
        url = urls.first!.appendingPathComponent("data.archive")
        return url!
    }
}



