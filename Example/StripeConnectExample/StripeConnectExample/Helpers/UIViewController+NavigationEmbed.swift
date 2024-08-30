//
//  UIViewController+NavigationEmbed.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 8/26/24.
//

import UIKit

extension UIViewController {
    func embedInNavigationController() -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: self)
        self.navigationItem.largeTitleDisplayMode = .never
        return navigationController
    }
}
