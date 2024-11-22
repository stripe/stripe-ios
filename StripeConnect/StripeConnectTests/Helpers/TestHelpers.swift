//
//  TestHelpers.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 9/6/24.
//

import Foundation
import UIKit

enum TestHelpers {

    // Setting the default timeout to 5 seconds to minimize flakiness because web view operations
    // can be slow especially when running tests in parallel.
    static let defaultTimeout = 5.0

    static func withTimeout<T>(seconds: TimeInterval = defaultTimeout, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TestHelperError.timeout(seconds: seconds)
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

extension UIViewController {
    // Overriding the user interface style alone does not trigger a trait collection change
    // the view also needs to be added to a window.
    func triggerTraitCollectionChange(style: UIUserInterfaceStyle) {
        let window = UIWindow()
        window.rootViewController = self
        window.makeKeyAndVisible()
        window.overrideUserInterfaceStyle = style

        // NOTE: On iOS 16 and lower, we need to trigger a layout on the VC to
        // trigger a trait collection change. This is not needed on 17+
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
}

enum TestHelperError: Error, CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case let .timeout(seconds):
            return "Operation timed out after \(seconds) seconds"
        }
    }

    case timeout(seconds: TimeInterval)
}
