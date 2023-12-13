//
//  UIApplication+StripePaymentSheet.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/20/23.
//

import Foundation
import UIKit

extension UIApplication {
    func stp_hackilyFumbleAroundUntilYouFindAKeyWindow() -> UIWindow? {
        // We really shouldn't do this: Try to find a way to get the user to pass us a window instead.
        #if canImport(CompositorServices)
        let windows = connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows }
            .flatMap { $0 }
            .sorted { firstWindow, _ in firstWindow.isKeyWindow }
        return windows.first
        #else
        return windows.first { $0.isKeyWindow }
        #endif
    }
}
