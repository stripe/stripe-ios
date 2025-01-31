//
//  SFSafariViewController+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/16/22.
//

import Foundation
import SafariServices

extension SFSafariViewController {

    static func present(url: URL) {
        guard
            url.scheme == "http" || url.scheme == "https",
            let topMostViewController = UIViewController.topMostViewController()
        else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return
        }
        let safariViewController = SFSafariViewController(url: url)
        PresentationManager.shared.present(safariViewController, from: topMostViewController)
    }
}
