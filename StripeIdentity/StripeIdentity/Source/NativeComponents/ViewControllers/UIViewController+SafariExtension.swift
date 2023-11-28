//
//  UIViewController+Extension.swift
//  StripeIdentity
//
//  Created by Chen Cen on 9/28/23.
//

import Foundation

import SafariServices
import UIKit

extension UIViewController {
    func openInSafariViewController(url: URL) {
        guard url.scheme == "http" || url.scheme == "https" else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return
        }

        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .popover
        present(safariVC, animated: true, completion: nil)
    }
}
