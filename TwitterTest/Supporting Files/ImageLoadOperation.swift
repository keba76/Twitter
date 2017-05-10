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
            guard !self.isCancelled, let image = image else { return }
            self.image = image
            self.completionHandler?(image)
        }
    }
}