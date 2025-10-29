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

    /// Returns the currently active `UIWindowScene` in the foreground.
    ///
    /// This function searches through all scenes connected to the shared application,
    /// filters for those of type `UIWindowScene`, and returns the first one whose
    /// activation state is `.foregroundActive`.
    ///
    /// - Returns: The `UIWindowScene` instance that is currently active and in the foreground,
    ///            or `nil` if there is no such scene.
    var activeScene: UIWindowScene? {
        let activeScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
        if activeScene == nil {
            let errorAnalytic = ErrorAnalytic(
                event: .unexpectedPaymentSheetError,
                error: Error.missingActiveScene
            )
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure("Couldn't find active scene!")
        }
        return activeScene
    }
    enum Error: Swift.Error {
       case missingActiveScene
    }
}
