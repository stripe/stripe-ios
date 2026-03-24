//
//  UIApplication+StripePaymentSheet.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/20/23.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

extension UIApplication {
    func stp_hackilyFumbleAroundUntilYouFindAKeyWindow() -> UIWindow? {
        // We really shouldn't do this: Try to find a way to get the user to pass us a window instead.
        #if os(visionOS)
        let windows = connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows }
            .flatMap { $0 }
            .sorted { firstWindow, _ in firstWindow.isKeyWindow }
        return windows.first
        #else
        return activeScene?.windows.first { $0.isKeyWindow }
        #endif
    }

    /// Returns a `UIWindowScene` suitable for reading traits or finding key windows.
    ///
    /// Prefers a scene with `activationState == .foregroundActive`, but falls back to any
    /// connected `UIWindowScene` (e.g. when the scene is `.foregroundInactive` during app
    /// transitions). Logs an error only when no `UIWindowScene` exists at all.
    var activeScene: UIWindowScene? {
        let windowScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        let scene = windowScenes.first(where: { $0.activationState == .foregroundActive })
            ?? windowScenes.first

        if scene == nil {
            let errorAnalytic = ErrorAnalytic(
                event: .unexpectedPaymentSheetError,
                error: Error.missingActiveScene
            )
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure("Couldn't find active scene!")
        }
        return scene
    }
    enum Error: Swift.Error {
       case missingActiveScene
    }
}
