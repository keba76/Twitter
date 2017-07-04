//
//  PhotoScaleVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/9/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift

class PhotoScaleVC: UIViewController {
    
    @IBOutlet weak var baseView: UIView!
    
    var image: UIImage?
    var urlVideo: URL?
    var imageView: ImageViewLayer?
    lazy var timeRemainingLabel = UILabel()
    var playbackBtn: CustomBtn?
    lazy var seekSlider = UISlider()
    lazy var mainViewConteinerForAction = UIView()
    var timeObserver: Any?
    
    var viewProgress: NVActivityIndicatorView?
    
    private var playbackLikelyToKeepUpContext = 0
    var playerRateBeforeSeek: Float = 0
    
    var dis = DisposeBag()
    
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    
    override func viewDidLoad() {
        AppUtility.lockOrientation(.all)
        
        imageView = ImageViewLayer(image: image)
        imageView!.contentMode = .scaleAspectFill
        baseView.addSubview(imageView!)
        guard let image = self.image else { return }
        imageView!.translatesAutoresizingMaskIntoConstraints = false
        baseView.addConstraint(NSLayoutConstraint(item: imageView!, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: (image.size.width / image.size.height), constant: 0))
        baseView.addConstraint(NSLayoutConstraint(item: imageView!, attribute: .centerX, relatedBy: .equal, toItem: baseView, attribute: .centerX, multiplier: 1, constant: 0))
        baseView.addConstraint(NSLayoutConstraint(item: imageView!, attribute: .centerY, relatedBy: .equal, toItem: baseView, attribute: .centerY, multiplier: 1, constant: 0))
        // add imageview side constraints
        for attribute: NSLayoutAttribute in [.top, .bottom, .leading, .trailing] {
            let constraintLowPriority = NSLayoutConstraint(item: imageView!, attribute: attribute, relatedBy: .equal, toItem: baseView, attribute: attribute, multiplier: 1, constant: 0)
            let constraintGreaterThan = NSLayoutConstraint(item: imageView!, attribute: attribute, relatedBy: .greaterThanOrEqual, toItem: baseView, attribute: attribute, multiplier: 1, constant: 0)
            constraintLowPriority.priority = 750
            baseView.addConstraints([constraintLowPriority,constraintGreaterThan])
        }
        
        if urlVideo != nil {
            let rectProgress = CGRect(x: view.bounds.width/2 - 20.0, y: view.bounds.height/2 - 20.0, width: 40.0, height: 40.0)
            viewProgress = NVActivityIndicatorView(frame: rectProgress, type: .ballRotate, color: UIColor.white, padding: 0)
            self.view.addSubview(self.viewProgress!)
            self.view.bringSubview(toFront: self.viewProgress!)
            self.viewProgress?.startAnimating()
            
            baseView.addSubview(mainViewConteinerForAction)
            imageView?.playerLayer.player = avPlayer
            let playerItem = AVPlayerItem(url: urlVideo!)
            avPlayer.replaceCurrentItem(with: playerItem)
            //avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            //avPlayerLayer.masksToBounds = true
            let interval = CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { elapsedTime in
                self.observeTime(elapsedTime: elapsedTime)
                self.syncScrubber(elapsedTime: elapsedTime)
                
            })
            avPlayer.addObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp",
                                 options: .new, context: &playbackLikelyToKeepUpContext)
            timeRemainingLabel.textColor = UIColor.white
            timeRemainingLabel.adjustsFontSizeToFitWidth = true
            timeRemainingLabel.sizeToFit()
            mainViewConteinerForAction.addSubview(timeRemainingLabel)
            playbackBtn = CustomBtn()
            playbackBtn!.setImage(UIImage(named: "playBtn"), for: .normal)
            mainViewConteinerForAction.addSubview(playbackBtn!)
            playbackBtn!.rx.tap.subscribe(onNext: {
                if self.avPlayer.rate > 0 {
                    self.avPlayer.pause()
                    self.playbackBtn!.setImage(UIImage(named: "pauseBtn"), for: .normal)
                } else {
                    self.avPlayer.play()
                    self.playbackBtn!.setImage(UIImage(named: "playBtn"), for: .normal)
                }
            }).addDisposableTo(dis)
            
            let resizeImageMinimun = UIImage(named: "sliderMaximum")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 5.0), resizingMode: .tile)
            let resizeImageMaximum = UIImage(named: "sliderMinimum")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 5.0), resizingMode: .stretch)
            seekSlider.setMinimumTrackImage(resizeImageMinimun, for: .normal)
            seekSlider.setMaximumTrackImage(resizeImageMaximum, for: .normal)
            seekSlider.setThumbImage(UIImage(named: "slider"), for: .normal)
            mainViewConteinerForAction.addSubview(seekSlider)
            seekSlider.addTarget(self, action: #selector(sliderBeganTracking), for: .touchDown)
            seekSlider.addTarget(self, action: #selector(sliderEndedTracking), for: [.touchUpInside, .touchUpOutside])
            seekSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
            
        }
        baseView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(actionClose(_:))))
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &playbackLikelyToKeepUpContext {
            if avPlayer.currentItem!.isPlaybackLikelyToKeepUp {
                self.viewProgress?.stopAnimating()
                self.viewProgress?.removeFromSuperview()
            } else {
                self.viewProgress?.startAnimating()
            }
        }
    }
    
    private func playerItemDuration() -> CMTime {
        let thePlayerItem = avPlayer.currentItem
        if thePlayerItem?.status == .readyToPlay {
            return thePlayerItem!.duration
        }
        return kCMTimeInvalid
    }
    
    func syncScrubber(elapsedTime: CMTime) {
        let playerDuration = playerItemDuration()
        if CMTIME_IS_INVALID(playerDuration) {
            seekSlider.minimumValue = 0.0
            return
        }
        let duration = Float(CMTimeGetSeconds(playerDuration))
        if duration.isFinite && duration > 0 {
            seekSlider.minimumValue = 0.0
            seekSlider.maximumValue = duration
            let time = Float(CMTimeGetSeconds(elapsedTime))
            seekSlider.setValue(time, animated: true)
            if seekSlider.value == seekSlider.maximumValue {
                seekSlider.value = 0.0
                avPlayer.seek(to: CMTime(value: CMTimeValue.allZeros, timescale: 1))
            }
        }
    }
    func updateTime(_ timer: Timer) {
        seekSlider.value = Float(CMTimeGetSeconds(avPlayer.currentItem!.duration))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if urlVideo != nil {
            let controlsHeight: CGFloat = 30.0
            let widthLbl: CGFloat = 56.0
            let widthBtn: CGFloat = 17.0
            mainViewConteinerForAction.autoresizingMask = [.flexibleWidth, .flexibleLeftMargin, .flexibleRightMargin]
            timeRemainingLabel.autoresizingMask = .flexibleLeftMargin
            seekSlider.autoresizingMask = .flexibleWidth
            if imageView!.bounds.height >= self.view.frame.height - controlsHeight {
                mainViewConteinerForAction.frame = CGRect(x: imageView!.frame.origin.x, y: imageView!.frame.maxY - controlsHeight, width: imageView!.frame.size.width, height: controlsHeight)
                let xLbl = mainViewConteinerForAction.frame.maxX - widthLbl
                let xBtn = mainViewConteinerForAction.frame.minX + 14.0
                let xSlider = xBtn + widthBtn + 10.0
                let widthSlider = xLbl - 10.0 - xSlider
                timeRemainingLabel.frame = CGRect(x: xLbl, y: 0.0, width: widthLbl, height: controlsHeight)
                playbackBtn!.frame = CGRect(x: xBtn, y: 0.0, width: widthBtn, height: controlsHeight)
                seekSlider.frame = CGRect(x: xSlider, y: 0.0, width: widthSlider, height: controlsHeight)
            } else {
                mainViewConteinerForAction.frame = CGRect(x: imageView!.frame.origin.x, y: imageView!.frame.maxY, width: imageView!.frame.size.width, height: controlsHeight)
                let xLbl = mainViewConteinerForAction.frame.maxX - widthLbl
                let xBtn = mainViewConteinerForAction.frame.minX + 14.0
                let xSlider = xBtn + widthBtn + 10.0
                let widthSlider = xLbl - 10.0 - xSlider
                timeRemainingLabel.frame = CGRect(x: xLbl, y: 0.0, width: widthLbl, height: controlsHeight)
                playbackBtn!.frame = CGRect(x: xBtn, y: 0.0, width: widthBtn, height: controlsHeight)
                seekSlider.frame = CGRect(x: xSlider, y: 0.0, width: widthSlider, height: controlsHeight)
            }
            avPlayer.play()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation.isLandscape {
            if urlVideo != nil {
                coordinator.animateAlongsideTransition(in: mainViewConteinerForAction, animation: { _ in
                    var frame = self.mainViewConteinerForAction.frame
                    frame.origin.x = self.imageView!.frame.minX
                    frame.origin.y = self.imageView!.frame.maxY - 40.0
                    frame.size.width = self.imageView!.frame.size.width
                    self.mainViewConteinerForAction.frame = frame
                }, completion: { _ in })
            }
        } else {
            if urlVideo != nil {
                coordinator.animateAlongsideTransition(in: mainViewConteinerForAction, animation: { _ in
                    var frame = self.mainViewConteinerForAction.frame
                    frame.origin.x = self.imageView!.frame.minX
                    frame.size.width = self.imageView!.frame.size.width
                    if self.imageView!.bounds.height >= self.view.frame.height - 30.0 {
                        frame.origin.y = self.imageView!.frame.maxY - 30.0
                    } else {
                        frame.origin.y = self.imageView!.frame.maxY
                    }
                    self.mainViewConteinerForAction.frame = frame
                }, completion: { _ in })
            }
        }
    }
    
    func sliderBeganTracking(slider: UISlider) {
        playerRateBeforeSeek = avPlayer.rate
        avPlayer.pause()
    }
    func sliderEndedTracking(slider: UISlider) {
        let elapsedTime: Float64 = Float64(seekSlider.value)
        updateTimeLabel(elapsedTime: elapsedTime)
        avPlayer.seek(to: CMTimeMakeWithSeconds(elapsedTime, 1000)) { (completed: Bool) -> Void in
            if self.playerRateBeforeSeek > 0 {
                self.avPlayer.play()
            }
        }
    }
    func sliderValueChanged(slider: UISlider) {
        let elapsedTime: Float64 = Float64(seekSlider.value)
        updateTimeLabel(elapsedTime: elapsedTime)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if urlVideo != nil {
            avPlayer.removeObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp")
            avPlayer.removeTimeObserver(timeObserver!)
        }
    }
    
    func actionClose(_ tap: UITapGestureRecognizer) {
        avPlayer.pause()
        
        if UIDevice.current.orientation.isLandscape {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
                let value = UIInterfaceOrientation.portrait.rawValue
                UIDevice.current.setValue(value, forKey: "orientation")
            }, completion: { finished in
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            })
        } else {
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func observeTime(elapsedTime: CMTime) {
        let duration = CMTimeGetSeconds(avPlayer.currentItem!.duration)
        if duration.isFinite {
            let elapsedTime = CMTimeGetSeconds(elapsedTime)
            updateTimeLabel(elapsedTime: elapsedTime)
        }
    }
    
    private func updateTimeLabel(elapsedTime: Float64) {
        let timeRemaining: Float64 = CMTimeGetSeconds(playerItemDuration()) - elapsedTime
        timeRemainingLabel.text = String(format: "%02d:%02d", ((lround(timeRemaining) / 60) % 60), lround(timeRemaining) % 60)
    }
}


extension PhotoScaleVC: ImageTransitionProtocol {
    
    func tranisitionSetup() { baseView.isHidden = true }
    
    func tranisitionCleanup() { baseView.isHidden = false }
    
    //return the imageView window frame
    func imageWindowFrame() -> CGRect {
        
        let baseViewFrame = baseView.superview!.convert(baseView.frame, to: nil)
        
        let baseViewRatio = baseView.frame.size.width / baseView.frame.size.height
        let imageRatio = (image?.size.width)! / (image?.size.height)!
        let touchesSides = (imageRatio > baseViewRatio)
        
        if touchesSides {
            let height = baseViewFrame.size.width / imageRatio
            let yPoint = baseViewFrame.origin.y + (baseViewFrame.size.height - height) / 2
            return CGRect(x:baseViewFrame.origin.x, y:yPoint, width:baseViewFrame.size.width, height:height)
        } else {
            let width = baseViewFrame.size.height * imageRatio
            let xPoint = baseViewFrame.origin.x + (baseViewFrame.size.width - width) / 2
            return CGRect(x:xPoint, y:baseViewFrame.origin.y, width:width, height:baseViewFrame.size.height)
        }
    }
}

class ImageViewLayer: UIImageView {
    var player: AVPlayer? {
        get { return playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    var playerLayer: AVPlayerLayer { return layer as! AVPlayerLayer }
    
    override class var layerClass: AnyClass { return AVPlayerLayer.self }
}

class CustomBtn: UIButton {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let rect = self.bounds.insetBy(dx: -10.0, dy: -10.0)
        if rect.contains(point) { return self }
        return nil
    }
}



