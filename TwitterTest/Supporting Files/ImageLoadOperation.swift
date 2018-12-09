//
//  ImageLoadOperation.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 6/16/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import Foundation
import SDWebImage

typealias ImageLoadOperationCompletionHandlerType = ((UIImage) -> ())?

class ImageLoadOperation: CoreOperationAsync {
    var url: URL
    var completionHandler: ImageLoadOperationCompletionHandlerType
    var image: UIImage?
    
    init(url: URL) {
        self.url = url
        super.init()
    }
    
    override func start() {
        super.start()
        
        SDWebImageManager.shared().loadImage(with: url, progress: { (_ , _, _) in
        }) { (image, error, _, cache, _ , _) in
            if image != nil, cache == .none {
                let urlString = self.url.absoluteString
                if urlString.contains("profile_images") {
                    let w = image!.size.width
                    let h = image!.size.height
                    let size = w/h > 0 ? CGSize(width: 200.0, height: 200/(w/h)) : CGSize(width: 200.0, height: 200 * (w/h))
                    
                    let tempImage = image?.imageWithImage(image: image!, scaledToSize: size)
                    SDWebImageManager.shared().saveImage(toCache: tempImage, for: self.url)
                    
                    guard !self.isCancelled, let image = image else { self.finish(); return }
                    self.image = image
                    self.completionHandler?(image)
                    self.finish()
                } else {
                    let w = image!.size.width
                    let h = image!.size.height
                    let size = w/h > 0 ? CGSize(width: 380.0, height: 380/(w/h)) : CGSize(width: 380.0, height: 380 * (w/h))
                    let tempImage = image?.imageWithImage(image: image!, scaledToSize: size)
                    SDWebImageManager.shared().saveImage(toCache: tempImage, for: self.url)
                    
                    guard !self.isCancelled, let image = image else { self.finish(); return }
                    self.image = image
                    self.completionHandler?(image)
                    self.finish()
                }
            }
            if image == nil {
                let urlString = self.url.absoluteString
                if urlString.contains("profile_images") {
                    var newUrl = urlString.replace(target: ".jpg", withString: "_bigger.jpg")
                    if urlString.contains("jpeg") {
                        newUrl = urlString.replace(target: ".jpeg", withString: "_bigger.jpeg")
                    }
                    SDWebImageManager.shared().loadImage(with: URL(string: newUrl), progress: { (_ , _, _) in
                    }) { (image, error, cache , _ , _, _) in
                        guard !self.isCancelled, let image = image else { self.finish(); return }
                        
                        self.image = image
                        self.completionHandler?(image)
                        self.finish()
                    }
                }
            }
            guard !self.isCancelled, let image = image else { self.finish(); return }
            self.image = image
            self.completionHandler?(image)
            self.finish()
        }
    }
    
    override func cancel() {
        super.cancel()
        self.finish()
    }
}
