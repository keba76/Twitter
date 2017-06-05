//
//  Reusable.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/1/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit

protocol Reusable: class {
    static var reuseIdentifier: String { get }
}
extension Reusable {
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}
extension UITableViewCell: Reusable {}

