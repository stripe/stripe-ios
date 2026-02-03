//
//  STPVisionSupport.swift
//  StripeCore
//
//  Created for visionOS compatibility.
//

import AuthenticationServices
import UIKit

/// Creates a fallback ASPresentationAnchor when no window is available.
/// This is needed for ASWebAuthenticationSession's presentationContextProvider.
@_spi(STP) public func stp_makeFallbackPresentationAnchor() -> ASPresentationAnchor {
    if let windowScene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first {
        return UIWindow(windowScene: windowScene)
    }
    #if os(visionOS)
    fatalError("No window scene available for ASPresentationAnchor on visionOS")
    #else
    return ASPresentationAnchor()
    #endif
}
