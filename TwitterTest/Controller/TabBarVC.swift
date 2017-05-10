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
    
    static var tab: TabBars?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if self.selectedIndex == 0 {
            TabBarVC.tab = TabBars(rawValue: "profileVC")
        } else if self.selectedIndex == 1 {
            TabBarVC.tab = TabBars(rawValue: "homeVC")
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if tabBarController.selectedIndex == 1 {
            if let x = viewController as? UINavigationController {
                let controller = self.storyboard?.instantiateViewController(withIdentifier: "ProfileVC") as! ProfileVC
                x.viewControllers.removeAll()
                x.viewControllers.append(controller)
                Profile.account.userData = Variable<UserData>(UserData.tempValue(action: false))
                controller.user = Profile.account
                x.popToRootViewController(animated: true)
            }
        }
    }
}

