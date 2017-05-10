//
//  ProfileRightVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/17/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift

class ProfileRightVC: UIViewController {
    
    @IBOutlet weak var descriptions: UILabel!
    
    let dis = DisposeBag()
    
    var user = ModelUser()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var text = user.description
        text = text.replace(target: "\n", withString: " ")
        text = text.replace(target: "\r", withString: "")
        
        let t = text.search(text: text)
        
        let mutText = NSMutableAttributedString(string: text)
        mutText.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 13.0, weight: UIFontWeightRegular), range: NSRange(location: 0, length: text.characters.count))
        
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 1.0
        style.lineBreakMode = NSLineBreakMode.byWordWrapping
        style.alignment = NSTextAlignment.center
        mutText.addAttribute(NSParagraphStyleAttributeName, value: style, range: NSRange(location: 0, length: mutText.string.characters.count))
        self.descriptions.attributedText = mutText
        if let s = user.entitiesDescription, s.count > 0 {
            s.forEach({ data in
                let range = mutText.mutableString.range(of: data["url"].string!, options: [.caseInsensitive])
                let name = NSMutableAttributedString(string: data["display_url"].string!, attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 13.0, weight: UIFontWeightRegular), NSForegroundColorAttributeName : UIColor(red: 36/255.0, green: 144/255.0, blue: 212/255.0, alpha: 1)])
                mutText.replaceCharacters(in: range, with: name)
            })
            self.descriptions.attributedText = mutText
        }
        
        if t.count > 0 {
            
            t.forEach({ word in
                if word.characters.first == "@" {
                    let range = mutText.mutableString.range(of: word, options: [.caseInsensitive])
                    let name = NSMutableAttributedString(string: word, attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 13.0, weight: UIFontWeightBold), NSForegroundColorAttributeName : UIColor(red: 25/255.0, green: 109/255.0, blue: 161/255.0, alpha: 1)])
                    mutText.replaceCharacters(in: range, with: name)
                } else {
                    let range = mutText.mutableString.range(of: word, options: [.caseInsensitive])
                    let name = NSMutableAttributedString(string: word, attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 13.0, weight: UIFontWeightRegular), NSForegroundColorAttributeName : UIColor.gray])
                    mutText.replaceCharacters(in: range, with: name)
                }
            })
            self.descriptions.attributedText = mutText
        }
    }
}

extension String {
    
    func search(text: String) -> ([String]) {
        var controlInt = false
        var controlString = ""
        
        var _text = [String]()
        for (index, x) in text.characters.enumerated() {
            switch x {
            case let char where (char == "@" || char == "#") && ((text as NSString).substring(with: NSRange(location: index - 1, length: 1)) == " " || index == 0) :
                controlString.append(char)
                print((text as NSString).substring(with: NSRange(location: index - 1, length: 1)))
                controlInt = true
            case let char where char != " " && controlInt:
                controlString.append(char)
                fallthrough
            case x:
                if controlInt && (x == " " || index == text.characters.count - 1) {
                    controlInt = false
                    _text.append(controlString)
                    controlString = ""
                }
            default:
                break
            }
        }
        return (_text)
    }
}
