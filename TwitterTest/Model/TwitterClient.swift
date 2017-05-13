 //
 //  TwitterClient.swift
 //  TwitterTest
 //
 //  Created by Ievgen Keba on 2/12/17.
 //  Copyright © 2017 Harman Inc. All rights reserved.
 //
 
 import Foundation
 import SimpleAuth
 import Social
 import UIKit
 import Accounts
 
 class TwitterClient {
    
    var tweet = [ViewModelTweet]()
    
    static var swifter: Swifter!
    
    static let shareInstance = TwitterClient()
    typealias complite = (_ data: [ViewModelTweet]) -> ()
    typealias compliteTweet = (_ data: ViewModelTweet) -> ()
    typealias compliteUser = (_ data: [ModelUser], _ cursor: String?) -> ()
    
    func timeLine(maxID: String? = nil, complited: @escaping complite) {
        let failureHandler: (Error) -> Void = { error in
            print(error.localizedDescription)
        }
        
        TwitterClient.swifter.getHomeTimeline(count: 20, maxID: maxID, success: { json in
            
            guard let twee = json.array else { return }
            //print(twee)
            var viewModel =  twee
                .map {Tweet(dict: $0)}
                .map {ModelTweet(parse: $0)}
                .map {ViewModelTweet(modelTweet: $0)}
            if maxID != nil {
                viewModel.removeFirst()
                complited(viewModel)
            } else { complited(viewModel) }
        }, failure: failureHandler)
    }
    
    func userTimeLine(id: String, maxID: String? = nil, complited: @escaping complite) {
        let failureHandler: (Error) -> Void = { error in
            print(error.localizedDescription)
        }
        
        TwitterClient.swifter.getTimeline(for: id, count: 20, maxID: maxID, success: { json in
            guard let twee = json.array else { return }
            //print(json)
            var viewModel =  twee
                .map {Tweet(dict: $0)}
                .map {ModelTweet(parse: $0)}
                .map {ViewModelTweet(modelTweet: $0)}
            if maxID != nil {
                viewModel.removeFirst()
                complited(viewModel)
            } else { complited(viewModel) }
        }, failure: failureHandler)
    }
    
    func repliesTweets(tweetOrigin: ViewModelTweet, complited: @escaping complite) {
        let failureHandler: (Error) -> Void = { error in
            print(error.localizedDescription)
        }
        let screenName = tweetOrigin.userScreenName
        let tweeID = tweetOrigin.retweetTweetID != nil ? tweetOrigin.retweetTweetID : tweetOrigin.tweetID
        //let tweeID = tweetOrigin.tweetID
        
        var tweets = [ViewModelTweet]()
        //TwitterClient.swifter.sea
        TwitterClient.swifter.searchTweet(using: "to:@\(screenName)",count: 50,  sinceID: tweeID, success: { (json, jsons) in
            guard let twee = json.array else { return }
            twee.forEach({ json in
                if json["in_reply_to_status_id_str"].string == tweeID {
                    
                    tweets.append(ViewModelTweet(modelTweet: ModelTweet(parse: Tweet(dict: json))))
                }
            })
            complited(tweets)
        }, failure: failureHandler)
    }
    
    func followersAndFollowing(userID: String, type: String, cursor: String? = nil,  complited: @escaping compliteUser) {
        let failureHandler: (Error) -> Void = { error in
            print(error.localizedDescription)
        }
        if type == "Following" {
            TwitterClient.swifter.getUserFollowing(for: .id(userID), cursor: cursor, count: 20, success: { (json, _ , nextCursor) in
                //print(json)
                guard let users = json.array else { return }
                var tempUsser = [ModelUser]()
                users.forEach {tempUsser.append(ModelUser(parse: User(dict: $0)))}
                complited(tempUsser, nextCursor)
            }, failure: failureHandler)
        } else {
            TwitterClient.swifter.getUserFollowers(for: .id(userID), cursor: cursor, count: 20, success: { (json, _ , nextCursor) in
                //print(json)
                guard let users = json.array else { return }
                var tempUsser = [ModelUser]()
                users.forEach {tempUsser.append(ModelUser(parse: User(dict: $0)))}
                print(tempUsser)
                complited(tempUsser, nextCursor)
            }, failure: failureHandler)
        }
    }
    
    func publishTweet(status: String?, media: Data?, complited: @escaping compliteTweet) {
        let failureHandler: (Error) -> Void = { error in
            print(error.localizedDescription)
        }
        if let pic = media, let text = status {
            TwitterClient.swifter.postTweet(status: text, media: pic, success: { json in
                let tweet = ViewModelTweet(modelTweet: ModelTweet(parse: Tweet(dict: json)))
                complited(tweet)
            }, failure: failureHandler)
        } else if let pic = media {
            TwitterClient.swifter.postTweet(status: "", media: pic, success: { json in
                let tweet = ViewModelTweet(modelTweet: ModelTweet(parse: Tweet(dict: json)))
                complited(tweet)
            }, failure: failureHandler)
        } else if let text = status {
            TwitterClient.swifter.postTweet(status: text, success: { json in
                let tweet = ViewModelTweet(modelTweet: ModelTweet(parse: Tweet(dict: json)))
                complited(tweet)
            }, failure: failureHandler)
        }
    }
    private func tweetQuote(data: JSON, complited: @escaping (ViewModelTweet) -> ()) {
        
    }
 }
