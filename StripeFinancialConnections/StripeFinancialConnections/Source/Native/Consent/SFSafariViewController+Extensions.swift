//
//  SFSafariViewController+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/16/22.
//

import Foundation
import SafariServices

extension SFSafariViewController {
    
    static func present(url: URL, from viewController: UIViewController) {
        guard url.scheme == "http" || url.scheme == "https" else {
            // TODO(kgaidis): Fix once we can use non-extension API's.
            // UIApplication.shared.open(url, options: [:], completionHandler:  nil)
            return
        }
        let safariViewController = SFSafariViewController(url: url)
        viewController.present(safariViewController, animated: true, completion: nil)
    }
    
    @available(iOSApplicationExtension, unavailable)
    static func present(url: URL) {
        guard
            url.scheme == "http" || url.scheme == "https",
            let topMostViewController = UIViewController.topMostViewController()
        else {
             UIApplication.shared.open(url, options: [:], completionHandler:  nil)
            return
        }
        let safariViewController = SFSafariViewController(url: url)
        topMostViewController.present(safariViewController, animated: true, completion: nil)
    }
}
