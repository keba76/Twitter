//
//  ProfilePageVC.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 2/25/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import UIKit

class ProfilePageVC: UIPageViewController, UIPageViewControllerDataSource {
    
    var user: ModelUser?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let firstVC = orderedVC.first {
            setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor.lightGray
        appearance.currentPageIndicatorTintColor = UIColor.gray
        dataSource = self
    }
    
    lazy var orderedVC: [UIViewController] = {
        return [self.newPageVC(side: "left"), self.newPageVC(side: "right")]
    }()
    private func newPageVC(side: String) -> UIViewController {
        if side == "left" {
            let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VC\(side)") as! ProfileLeftVC
            controller.user = user!
            return controller
        } else {
            let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VC\(side)") as! ProfileRightVC
            controller.user = user!
            return controller
        }
//        let controller = side == "left" ? UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VC\(side)") as! ProfileLeftVC : UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VC\(side)") as! ProfileRightVC
//        if controller is ProfileLeftVC {
//            
//        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = orderedVC.index(of: viewController) else { return nil }
        guard (index - 1) >= 0 else { return nil }
        return orderedVC[index - 1]
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = orderedVC.index(of: viewController) else { return nil }
        guard orderedVC.count > (index + 1) else { return nil }
        return orderedVC[index + 1]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedVC.count
    }
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstVC = viewControllers?.first, let firstIndex = orderedVC.index(of: firstVC) else {
            return 0
        }
        return firstIndex
    }
    
}
