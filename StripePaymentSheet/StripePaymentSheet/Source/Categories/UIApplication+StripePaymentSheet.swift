//
//  UIApplication+StripePaymentSheet.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/20/23.
//

import Foundation
@_spi(STP) import StripeCore
#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

extension UIApplication {
    func stp_hackilyFumbleAroundUntilYouFindAKeyWindow() -> UIWindow? {
        // We really shouldn't do this: Try to find a way to get the user to pass us a window instead.
        return connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    /// Returns a `UIWindowScene` suitable for reading traits or finding key windows.
    ///
    /// Prefers a scene with `activationState == .foregroundActive`, but falls back to any
    /// connected `UIWindowScene` (e.g. when the scene is `.foregroundInactive` during app
    /// transitions). Logs an error only when no `UIWindowScene` exists at all.
    var activeOrFirstScene: UIWindowScene? {
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
