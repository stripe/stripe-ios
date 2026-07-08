//
//  STPVisionSupport.swift
//  StripePaymentSheet
//
//  Created for visionOS compatibility.
//

import AuthenticationServices
#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

/// Creates a fallback ASPresentationAnchor when no window is available.
/// On visionOS, UIWindow() without a scene is deprecated, so we find a scene first.
func stp_makeFallbackPresentationAnchor() -> ASPresentationAnchor {
    #if !os(visionOS)
    return ASPresentationAnchor()
    #else
    if let windowScene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first {
        return UIWindow(windowScene: windowScene)
    }
    fatalError()
    #endif
}
