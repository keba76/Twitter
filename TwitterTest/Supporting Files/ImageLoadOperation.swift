//
//  ImageLoadOperation.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 4/30/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import Foundation
import SDWebImage

typealias ImageLoadOperationCompletionHandlerType = ((UIImage) -> ())?

class ImageLoadOperation: Operation {
    var url: URL
    var completionHandler: ImageLoadOperationCompletionHandlerType
    var image: UIImage?
    
    init(url: URL) {
        self.url = url
    }
    
    override func main() {
        if isCancelled {
            return
        }
        SDWebImageManager.shared().downloadImage(with: url, progress: { (_ , _) in
        }) { (image, error, cache , _ , _) in
            if image != nil, cache == .none {
                let urlString = self.url.absoluteString
                if urlString.contains("profile_images") {
                    let w = image!.size.width
                    let h = image!.size.height
                    let size = w/h > 0 ? CGSize(width: 200.0, height: 200/(w/h)) : CGSize(width: 200.0, height: 200 * (w/h))
                    DispatchQueue.global(qos: .userInitiated).async {
                        let tempImage = image?.imageWithImage(image: image!, scaledToSize: size)
                        SDWebImageManager.shared().saveImage(toCache: tempImage, for: self.url)
                        DispatchQueue.main.async {
                            guard !self.isCancelled, let image = image else { return }
                            self.image = image
                            self.completionHandler?(image)
                        }
                    }
                } else {
                    let w = image!.size.width
                    let h = image!.size.height
                    let size = w/h > 0 ? CGSize(width: 380.0, height: 380/(w/h)) : CGSize(width: 380.0, height: 380 * (w/h))
                    DispatchQueue.global(qos: .userInitiated).async {
                        let tempImage = image?.imageWithImage(image: image!, scaledToSize: size)
                        SDWebImageManager.shared().saveImage(toCache: tempImage, for: self.url)
                        DispatchQueue.main.async {
                            
                            guard !self.isCancelled, let image = image else { return }
                            self.image = image
                            self.completionHandler?(image)
                        }
                    }
                }
            }
            if image == nil {
                let urlString = self.url.absoluteString
                if urlString.contains("profile_images") {
                    let newUrl = urlString.replace(target: ".jpg", withString: "_bigger.jpg")
                    SDWebImageManager.shared().downloadImage(with: URL(string: newUrl), progress: { (_ , _) in
                    }) { (image, error, cache , _ , _) in
                        guard !self.isCancelled, let image = image else { return }
                        self.image = image
                        self.completionHandler?(image)
                    }
                }
                
            }
            guard !self.isCancelled, let image = image else { return }
            self.image = image
            self.completionHandler?(image)
        }
    }
}
