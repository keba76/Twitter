    //
    //  DetailsVC.swift
    //  TwitterTest
    //
    //  Created by Ievgen Keba on 2/28/17.
    //  Copyright © 2017 Harman Inc. All rights reserved.
    //
    
    import UIKit
    
    class DetailsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
        
        @IBOutlet weak var tableView: UITableView!
        
        var tweet: ViewModelTweet?
        var tweetChain = [ViewModelTweet]()
        var instanceDetail: TwitterClient?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            
            instanceDetail = TwitterClient()
            tweetChain.append(tweet!)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.estimatedRowHeight = 270.0
            
            tableView.tableFooterView = UIView()
            
            reloadData()
        }
        
        func reloadData() {
            instanceDetail?.repliesTweets(tweetOrigin: tweet!, complited: { tweets in
                self.tweetChain.append(contentsOf: tweets)
                var index = [IndexPath]()
                if self.tweetChain.count > 1 {
                    for i in 1..<self.tweetChain.count {
                        let indexPath = IndexPath(row: i, section: 0)
                        index.append(indexPath)
                    }
                }
                self.tableView.insertRows(at: index, with: .top)
            })
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return tweetChain.count > 0 ? tweetChain.count : 1
            
        }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            var cells = UITableViewCell()
            if indexPath.row == 0 {
                if !tweet!.mediaImageURLs.isEmpty {
                    let cell = tableView.dequeueReusableCell(indexPath: indexPath) as TweetExpandedMediaCell
                    cell.tweets = tweetChain[indexPath.row]
                    cells = cell
                } else {
                    let cell = tableView.dequeueReusableCell(indexPath: indexPath) as TweetExpandedCompactCell
                    cell.tweets = tweetChain[indexPath.row]
                    cells = cell
                }
            }
            if tweetChain.count > 1 && indexPath.row != 0 {
                if !tweetChain[indexPath.row].mediaImageURLs.isEmpty {
                    let cell = tableView.dequeueReusableCell(indexPath: indexPath) as TweetMediaCell
                    cell.tweet = tweetChain[indexPath.row]
                    cells = cell
                    
                } else {
                    let cell = tableView.dequeueReusableCell(indexPath: indexPath) as TweetCompactCell
                    cell.tweet = tweetChain[indexPath.row]
                    cells = cell
                }
            }
            return cells
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
            if indexPath.row == 0 {
                return nil
            }
            return indexPath
        }

    }
           
