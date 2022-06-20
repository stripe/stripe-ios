//
//  SFSafariViewController+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/16/22.
//

import Foundation
import SafariServices

extension SFSafariViewController {
    
    @available(iOSApplicationExtension, unavailable)
    static func present(url: URL) {
        guard url.scheme == "http" || url.scheme == "https" else {
            UIApplication.shared.open(url, options: [:], completionHandler:  nil)
            return
        }
        let safariViewController = SFSafariViewController(url: url)
    
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        let rootViewController = window?.rootViewController?.presentedViewController ?? window?.rootViewController
        rootViewController?.present(safariViewController, animated: true, completion: nil)
    }
}
