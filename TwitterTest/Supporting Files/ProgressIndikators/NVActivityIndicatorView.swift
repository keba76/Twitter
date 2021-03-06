//
//  NVActivityIndicatorView.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/20/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit

/**
 
 */
public enum NVActivityIndicatorType: Int {
    /**
     Blank.
     
     - returns: Instance of NVActivityIndicatorAnimationBlank.
     */
    case blank
    /**
     
     BallScale.
     
     - returns: Instance of NVActivityIndicatorAnimationBallScale.
     */
    case ballScale
    /**
     
     LineScaleParty.
     
     - returns: Instance of NVActivityIndicatorAnimationLineScaleParty.
     */
    case lineScaleParty
    /**
     BallScaleMultiple.
     
     - returns: Instance of NVActivityIndicatorAnimationBallScaleMultiple.
     */
    case ballScaleMultiple
    /**
     
     BallRotate.
     
     - returns: Instance of NVActivityIndicatorAnimationBallRotate.
     */
    case ballRotate
    /**
     
     LineScalePulseOut.
     
     - returns: Instance of NVActivityIndicatorAnimationLineScalePulseOut.
     */
    case lineScalePulseOut
    /**
     LineScalePulseOutRapid.
     
     - returns: Instance of NVActivityIndicatorAnimationLineScalePulseOutRapid.
     */
    case lineScalePulseOutRapid
    /**
     
     BallSpinFadeLoader.
     
     - returns: Instance of NVActivityIndicatorAnimationBallSpinFadeLoader.
     */
    case ballSpinFadeLoader
    /**
     LineSpinFadeLoader.
     
     - returns: Instance of NVActivityIndicatorAnimationLineSpinFadeLoader.
     */
    case lineSpinFadeLoader
    
    static let allTypes = (blank.rawValue ... lineSpinFadeLoader.rawValue).map { NVActivityIndicatorType(rawValue: $0)! }
    
    func animation() -> NVActivityIndicatorAnimationDelegate {
        switch self {
        case .blank:
            return NVActivityIndicatorAnimationBlank()
        case .ballScale:
            return NVActivityIndicatorAnimationBallScale()
        case .lineScaleParty:
            return NVActivityIndicatorAnimationLineScaleParty()
        case .ballScaleMultiple:
            return NVActivityIndicatorAnimationBallScaleMultiple()
        case .lineScalePulseOut:
            return NVActivityIndicatorAnimationLineScalePulseOut()
        case .lineScalePulseOutRapid:
            return NVActivityIndicatorAnimationLineScalePulseOutRapid()
        case .ballSpinFadeLoader:
            return NVActivityIndicatorAnimationBallSpinFadeLoader()
        case .lineSpinFadeLoader:
            return NVActivityIndicatorAnimationLineSpinFadeLoader()
        case .ballRotate:
            return NVActivityIndicatorAnimationBallRotate()
        }
    }
}

/// Activity indicator view with nice animations
public final class NVActivityIndicatorView: UIView {
    /// Default type. Default value is .BallSpinFadeLoader.
    public static var DEFAULT_TYPE: NVActivityIndicatorType = .ballSpinFadeLoader
    
    /// Default color of activity indicator. Default value is UIColor.white.
    public static var DEFAULT_COLOR = UIColor.white
    
    /// Default color of text. Default value is UIColor.white.
    public static var DEFAULT_TEXT_COLOR = UIColor.white
    
    /// Default padding. Default value is 0.
    public static var DEFAULT_PADDING: CGFloat = 0
    
    /// Default size of activity indicator view in UI blocker. Default value is 60x60.
    public static var DEFAULT_BLOCKER_SIZE = CGSize(width: 60, height: 60)
    
    /// Default display time threshold to actually display UI blocker. Default value is 0 ms.
    public static var DEFAULT_BLOCKER_DISPLAY_TIME_THRESHOLD = 0
    
    /// Default minimum display time of UI blocker. Default value is 0 ms.
    public static var DEFAULT_BLOCKER_MINIMUM_DISPLAY_TIME = 0
    
    /// Default message displayed in UI blocker. Default value is nil.
    public static var DEFAULT_BLOCKER_MESSAGE: String?
    
    /// Default font of message displayed in UI blocker. Default value is bold system font, size 20.
    public static var DEFAULT_BLOCKER_MESSAGE_FONT = UIFont.boldSystemFont(ofSize: 20)
    
    /// Default background color of UI blocker. Default value is UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    public static var DEFAULT_BLOCKER_BACKGROUND_COLOR = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    
    /// Animation type.
    public var type: NVActivityIndicatorType = NVActivityIndicatorView.DEFAULT_TYPE
    
    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'type' instead.")
    @IBInspectable var typeName: String {
        get {
            return getTypeName()
        }
        set {
            _setTypeName(newValue)
        }
    }
    
    /// Color of activity indicator view.
    @IBInspectable public var color: UIColor = NVActivityIndicatorView.DEFAULT_COLOR
    
    /// Padding of activity indicator view.
    @IBInspectable public var padding: CGFloat = NVActivityIndicatorView.DEFAULT_PADDING
    
    /// Current status of animation, read-only.
    @available(*, deprecated: 3.1)
    public var animating: Bool { return isAnimating }
    
    /// Current status of animation, read-only.
    private(set) public var isAnimating: Bool = false
    
    /**
     Returns an object initialized from data in a given unarchiver.
     self, initialized using the data in decoder.
     
     - parameter decoder: an unarchiver object.
     
     - returns: self, initialized using the data in decoder.
     */
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
        isHidden = true
    }
    
    /**
     Create a activity indicator view.
     
     Appropriate NVActivityIndicatorView.DEFAULT_* values are used for omitted params.
     
     - parameter frame:   view's frame.
     - parameter type:    animation type.
     - parameter color:   color of activity indicator view.
     - parameter padding: padding of activity indicator view.
     
     - returns: The activity indicator view.
     */
    public init(frame: CGRect, type: NVActivityIndicatorType? = nil, color: UIColor? = nil, padding: CGFloat? = nil) {
        self.type = type ?? NVActivityIndicatorView.DEFAULT_TYPE
        self.color = color ?? NVActivityIndicatorView.DEFAULT_COLOR
        self.padding = padding ?? NVActivityIndicatorView.DEFAULT_PADDING
        super.init(frame: frame)
        isHidden = true
    }
    
    // Fix issue #62
    // Intrinsic content size is used in autolayout
    // that causes mislayout when using with MBProgressHUD.
    /**
     Returns the natural size for the receiving view, considering only properties of the view itself.
     
     A size indicating the natural size for the receiving view based on its intrinsic properties.
     
     - returns: A size indicating the natural size for the receiving view based on its intrinsic properties.
     */
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: bounds.height)
    }
    
    /**
     Start animating.
     */
    public final func startAnimating() {
        isHidden = false
        isAnimating = true
        layer.speed = 1
        setUpAnimation()
    }
    
    /**
     Stop animating.
     */
    public final func stopAnimating() {
        isHidden = true
        isAnimating = false
        layer.sublayers?.removeAll()
    }
    
    // MARK: Internal
    
    func _setTypeName(_ typeName: String) {
        for item in NVActivityIndicatorType.allTypes {
            if String(describing: item).caseInsensitiveCompare(typeName) == ComparisonResult.orderedSame {
                type = item
                break
            }
        }
    }
    
    func getTypeName() -> String {
        return String(describing: type)
    }
    
    // MARK: Privates
    
    private final func setUpAnimation() {
        let animation: NVActivityIndicatorAnimationDelegate = type.animation()
        var animationRect = frame.inset(by: UIEdgeInsets.init(top: padding, left: padding, bottom: padding, right: padding))
        let minEdge = min(animationRect.width, animationRect.height)
        
        layer.sublayers = nil
        animationRect.size = CGSize(width: minEdge, height: minEdge)
        animation.setUpAnimation(in: layer, size: animationRect.size, color: color)
    }
}

