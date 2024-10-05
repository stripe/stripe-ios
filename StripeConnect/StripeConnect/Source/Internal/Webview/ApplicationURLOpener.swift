//
//  ApplicationURLOpener.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/14/24.
//

@_spi(STP) import StripeCore
import UIKit

private struct URLOpenError: Error, AnalyticLoggableErrorV2 {
    let url: URL

    func analyticLoggableSerializeForLogging() -> [String: Any] {
        ["url": url.sanitizedForLogging]
    }
}

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

    func openIfPossible(_ url: URL) throws {
        guard canOpenURL(url) else {
            throw URLOpenError(url: url)
        }
        open(url, options: [:], completionHandler: nil)
    }
}

extension UIApplication: ApplicationURLOpener {}
