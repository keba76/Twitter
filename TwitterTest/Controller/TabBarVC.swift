//
//  TabBarVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 3/19/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit
import RxSwift

enum TabBars: String {
    case homeVC = "homeVC"
    case profileVC = "profileVC"
    case none = "none"
}

class TabBarVC: UITabBarController, UITabBarControllerDelegate {
    
    static var tab:TabBars? = TabBars(rawValue: "homeVC")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item == tabBar.items?[0] {
            TabBarVC.tab = TabBars(rawValue: "homeVC")
        } else if item == tabBar.items?[1] {
            TabBarVC.tab = TabBars(rawValue: "profileVC")
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if tabBarController.selectedIndex == 1 {
            if let x = viewController as? UINavigationController, let controller = x.viewControllers.first as? ProfileVC {
                print(x.viewControllers.first!)
                controller.user = Profile.account
            }
        }
    }
}

