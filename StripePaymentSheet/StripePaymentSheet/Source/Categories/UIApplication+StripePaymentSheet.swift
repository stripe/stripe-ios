//
//  UIApplication+StripePaymentSheet.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/20/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension UIApplication {
    func stp_hackilyFumbleAroundUntilYouFindAKeyWindow() -> UIWindow? {
        // We really shouldn't do this: Try to find a way to get the user to pass us a window instead.
        let windowScenes = connectedScenes
            .compactMap { $0 as? UIWindowScene }

        #if DEBUG
        debugPrintWindowLookup(windowScenes: windowScenes)
        #endif

        let selectedWindow = windowScenes
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        #if DEBUG
        if let selectedWindow {
            print("[STPWindowLookupDebug] selected \(stpDebugDescription(for: selectedWindow))")
        } else {
            print("[STPWindowLookupDebug] selected nil")
        }
        #endif

        return selectedWindow
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

#if DEBUG
private func debugPrintWindowLookup(windowScenes: [UIWindowScene]) {
    print("[STPWindowLookupDebug] connected UIWindowScenes: \(windowScenes.count)")
    for (sceneIndex, scene) in windowScenes.enumerated() {
        let sceneDescription = [
            "scene[\(sceneIndex)]",
            "id=\(scene.session.persistentIdentifier)",
            "activation=\(stpDebugDescription(for: scene.activationState))",
            "windows=\(scene.windows.count)",
        ].joined(separator: " ")
        print("[STPWindowLookupDebug] \(sceneDescription)")

        for (windowIndex, window) in scene.windows.enumerated() {
            print("[STPWindowLookupDebug]   window[\(windowIndex)] \(stpDebugDescription(for: window))")
        }
    }
}

private func stpDebugDescription(for window: UIWindow) -> String {
    let rootDescription: String
    if let rootViewController = window.rootViewController {
        let topViewController = rootViewController.findTopMostPresentedViewController()
        rootDescription = "root=\(type(of: rootViewController)) top=\(type(of: topViewController))"
    } else {
        rootDescription = "root=nil top=nil"
    }

    let sceneID = window.windowScene?.session.persistentIdentifier ?? "nil"
    return "window=\(ObjectIdentifier(window)) scene=\(sceneID) isKey=\(window.isKeyWindow) hidden=\(window.isHidden) \(rootDescription)"
}

private func stpDebugDescription(for activationState: UIScene.ActivationState) -> String {
    switch activationState {
    case .unattached:
        return "unattached"
    case .foregroundActive:
        return "foregroundActive"
    case .foregroundInactive:
        return "foregroundInactive"
    case .background:
        return "background"
    @unknown default:
        return "unknown"
    }
}
#endif
