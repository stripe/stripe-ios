//
//  ApplicationURLOpener.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/14/24.
//

import UIKit

/// Protocol used to dependency inject `UIApplication.open` for use in tests
protocol ApplicationURLOpener {
    func canOpenURL(_ url: URL) -> Bool
    func open(
        _ url: URL,
        options: [UIApplication.OpenExternalURLOptionsKey: Any],
        completionHandler completion: OpenCompletionHandler?
    )
}

extension ApplicationURLOpener {
    // The signature of the `completionHandler` in UIApplication.open changed
    // in Xcode 16
    #if compiler(>=6.0)
    typealias OpenCompletionHandler = @MainActor @Sendable (Bool) -> Void
    #else
    typealias OpenCompletionHandler = (Bool) -> Void
    #endif

    func openIfPossible(_ url: URL) {
        guard canOpenURL(url) else {
            // TODO: MXMOBILE-2491 Log as analytics when url can't be opened.
            return
        }
        open(url, options: [:], completionHandler: nil)
    }
}

extension UIApplication: ApplicationURLOpener {}
