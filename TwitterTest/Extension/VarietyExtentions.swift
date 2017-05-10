//
//  VarietyExtentions.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/15/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import Foundation
import UIKit

extension String {
    
    func replace(target: String, withString: String) -> String {
        
        return self.replacingOccurrences(of: target, with: withString, options: CompareOptions.literal, range: nil)
    }
}

extension NSObject {
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension UIView {
    
    func round(corners: UIRectCorner, radius: CGFloat) {
        _round(corners: corners, radius: radius)
    }
    
    /**
     Rounds the given set of corners to the specified radius with a border
     
     - parameter corners:     Corners to round
     - parameter radius:      Radius to round to
     - parameter borderColor: The border color
     - parameter borderWidth: The border width
     */
    func round(corners: UIRectCorner, radius: CGFloat, borderColor: UIColor, borderWidth: CGFloat) {
        let mask = _round(corners: corners, radius: radius)
        addBorder(mask: mask, borderColor: borderColor, borderWidth: borderWidth)
    }
    
    func roundDifferentCorner(topLeftRadius r1: CGFloat, topRightRadius r2: CGFloat, bottomRightRadius r3: CGFloat, bottomLeftRadius r4: CGFloat, borderColor: UIColor, borderWidth: CGFloat) {
        let mask = _pathCorner(topLeftRadius: r1, topRightRadius: r2, bottomRightRadius: r3, bottomLeftRadius: r4)
        addBorder(mask: mask, borderColor: borderColor, borderWidth: borderWidth)
    }
    
    func fullyRound(diameter: CGFloat, borderColor: UIColor, borderWidth: CGFloat) {
        layer.masksToBounds = true
        layer.cornerRadius = diameter / 2
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor;
    }
    
}

private extension UIView {
    
    @discardableResult func _round(corners: UIRectCorner, radius: CGFloat) -> CAShapeLayer {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
        return mask
    }
    
    func _pathCorner(topLeftRadius r1: CGFloat, topRightRadius r2: CGFloat, bottomRightRadius r3: CGFloat, bottomLeftRadius r4: CGFloat) -> CAShapeLayer {
        let path = UIBezierPath(roundedRect: bounds, topLeftRadius: r1, topRightRadius: r2, bottomRightRadius: r3, bottomLeftRadius: r4)
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
        return mask
    }
    
    func addBorder(mask: CAShapeLayer, borderColor: UIColor, borderWidth: CGFloat) {
        let borderLayer = CAShapeLayer()
        borderLayer.path = mask.path
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.frame = bounds
        layer.addSublayer(borderLayer)
    }
    
}

extension UIBezierPath {
    convenience init(roundedRect rect: CGRect, topLeftRadius r1: CGFloat, topRightRadius r2: CGFloat, bottomRightRadius r3: CGFloat, bottomLeftRadius r4: CGFloat) {
        let left  = CGFloat(M_PI)
        let up    = CGFloat(1.5*M_PI)
        let down  = CGFloat(M_PI_2)
        let right = CGFloat(0.0)
        self.init()
        addArc(withCenter: CGPoint(x: rect.minX + r1, y: rect.minY + r1), radius: r1, startAngle: left,  endAngle: up,    clockwise: true)
        addArc(withCenter: CGPoint(x: rect.maxX - r2, y: rect.minY + r2), radius: r2, startAngle: up,    endAngle: right, clockwise: true)
        addArc(withCenter: CGPoint(x: rect.maxX - r3, y: rect.maxY - r3), radius: r3, startAngle: right, endAngle: down,  clockwise: true)
        addArc(withCenter: CGPoint(x: rect.minX + r4, y: rect.maxY - r4), radius: r4, startAngle: down,  endAngle: left,  clockwise: true)
        close()
    }
}

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>(indexPath: IndexPath) -> T where T: Reusable {
        return self.dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }
}


extension Array where Element:Hashable {
    func removeDuplicates() -> ([Element]) {
        var result = [Element]()
        
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        
        return (result)
    }
    
        /**
         Returns only the unique elements of an Array, in the order they appear in the Array
         
         - note: Items have to be hashable
         */
        var uniqueElements: Array<Element> {
            //Using a dictionary because it's faster to look up items in a dictionary than to
            //search trough an array. In other words, array.contans(item:) is O(n) complexity
            var seen: [Element: Bool] = [:]
            
            return self.flatMap { element in
                guard seen[element] == nil else {
                    //flatMap flattens out nil values
                    return nil
                }
                seen[element] = true
                return element
            }
        }
    }



extension String {
    static private let mappings = ["&quot;" : "\"","&amp;" : "&", "&lt;" : "<", "&gt;" : ">","&nbsp;" : " ","&iexcl;" : "¡","&cent;" : "¢","&pound;" : " £","&curren;" : "¤","&yen;" : "¥","&brvbar;" : "¦","&sect;" : "§","&uml;" : "¨","&copy;" : "©","&ordf;" : " ª","&laquo" : "«","&not" : "¬","&reg" : "®","&macr" : "¯","&deg" : "°","&plusmn" : "±","&sup2; " : "²","&sup3" : "³","&acute" : "´","&micro" : "µ","&para" : "¶","&middot" : "·","&cedil" : "¸","&sup1" : "¹","&ordm" : "º","&raquo" : "»&","frac14" : "¼","&frac12" : "½","&frac34" : "¾","&iquest" : "¿","&times" : "×","&divide" : "÷","&ETH" : "Ð","&eth" : "ð","&THORN" : "Þ","&thorn" : "þ","&AElig" : "Æ","&aelig" : "æ","&OElig" : "Œ","&oelig" : "œ","&Aring" : "Å","&Oslash" : "Ø","&Ccedil" : "Ç","&ccedil" : "ç","&szlig" : "ß","&Ntilde;" : "Ñ","&ntilde;":"ñ",]
    
    func stringByDecodingXMLEntities() -> String {
        
        guard let _ = self.range(of: "&", options: [.literal]) else {
            return self
        }
        
        var result = ""
        
        let scanner = Scanner(string: self)
        scanner.charactersToBeSkipped = nil
        
        let boundaryCharacterSet = CharacterSet(charactersIn: " \t\n\r;")
        
        repeat {
            var nonEntityString: NSString? = nil
            
            if scanner.scanUpTo("&", into: &nonEntityString) {
                if let s = nonEntityString as? String {
                    result.append(s)
                }
            }
            
            if scanner.isAtEnd {
                break
            }
            
            var didBreak = false
            for (k,v) in String.mappings {
                if scanner.scanString(k, into: nil) {
                    result.append(v)
                    didBreak = true
                    break
                }
            }
            
            if !didBreak {
                
                if scanner.scanString("&#", into: nil) {
                    
                    var gotNumber = false
                    var charCodeUInt: UInt32 = 0
                    var charCodeInt: Int32 = -1
                    var xForHex: NSString? = nil
                    
                    if scanner.scanString("x", into: &xForHex) {
                        gotNumber = scanner.scanHexInt32(&charCodeUInt)
                    }
                    else {
                        gotNumber = scanner.scanInt32(&charCodeInt)
                    }
                    
                    if gotNumber {
                        let newChar = String(format: "%C", (charCodeInt > -1) ? charCodeInt : charCodeUInt)
                        result.append(newChar)
                        scanner.scanString(";", into: nil)
                    }
                    else {
                        var unknownEntity: NSString? = nil
                        scanner.scanUpToCharacters(from: boundaryCharacterSet, into: &unknownEntity)
                        let h = xForHex ?? ""
                        let u = unknownEntity ?? ""
                        result.append("&#\(h)\(u)")
                    }
                }
                else {
                    scanner.scanString("&", into: nil)
                    result.append("&")
                }
            }
            
        } while (!scanner.isAtEnd)
        
        return result
    }
}

extension UIView
{
    func addCornerRadiusAnimation(from: CGFloat, to: CGFloat, duration: CFTimeInterval)
    {
        let animation = CABasicAnimation(keyPath:"cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        self.layer.add(animation, forKey: "cornerRadius")
        self.layer.cornerRadius = to
    }
}

extension UIImage {
    func forceLazyImageDecompression() -> UIImage {
        
            UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
            self.draw(at: CGPoint.zero)
            UIGraphicsEndImageContext()
        return self
    }


class func getEmptyImageWithColor(color: UIColor) -> UIImage
{
    let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 1, height: 1))
    UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1), true, 0)
    color.setFill()
    UIRectFill(rect)
    let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return image
}
}

extension UITapGestureRecognizer {
    
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        //        var sizeOfString = CGSize()
        //        let font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular)
        //
        //            let finalDate = "..."
        //            let fontAttributes = [NSFontAttributeName: font] // it says name, but a UIFont works
        //            sizeOfString = (finalDate as NSString).size(attributes: fontAttributes)
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)
        
        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        
        let labelSize = label.bounds.size
        textContainer.size = labelSize
        
        
        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        
        
        let lastRange = NSRange(location: targetRange.location + targetRange.length - 1, length: 1)
        
        let lastPoint = layoutManager.boundingRect(forGlyphRange: lastRange, in: textContainer)
        
        
        // let y = layoutManager.boundingRect(forGlyphRange: targetRange, in: textContainer)
        
        //let textBoundingBox = layoutManager.usedRect(for: textContainer)
        
        
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInLabel, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if indexOfCharacter == layoutManager.characterIndex(for: CGPoint(x: locationOfTouchInLabel.x + 8.0, y: locationOfTouchInLabel.y) , in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil) {
            return false
        }
        
        if locationOfTouchInLabel.y < lastPoint.origin.y || locationOfTouchInLabel.y >= lastPoint.origin.y && locationOfTouchInLabel.x  <= lastPoint.origin.x + lastPoint.width {
            return NSLocationInRange(indexOfCharacter, targetRange)
        } else { return false }
        
        
    }
    
}

extension UIView {
    func mask(withRect rect: CGRect, inverse: Bool = false) {
        let path = UIBezierPath(rect: rect)
        let maskLayer = CAShapeLayer()
        if inverse {
            path.append(UIBezierPath(rect: self.bounds))
            maskLayer.fillRule = kCAFillRuleEvenOdd
        }
        maskLayer.path = path.cgPath
        self.layer.mask = maskLayer
    }
    
    func mask(withPath path: UIBezierPath, inverse: Bool = false) {
        let path = path
        let maskLayer = CAShapeLayer()
        if inverse {
            path.append(UIBezierPath(rect: self.bounds))
            maskLayer.fillRule = kCAFillRuleEvenOdd
        }
        maskLayer.path = path.cgPath
        self.layer.mask = maskLayer
    }
}