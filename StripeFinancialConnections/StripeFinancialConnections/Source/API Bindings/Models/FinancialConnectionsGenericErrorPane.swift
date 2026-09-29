//
//  FinancialConnectionsGenericErrorPane.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2026-08-12.
//

import Foundation
@_spi(STP) import StripeCore

/// A fully server-controlled error screen.
///
/// Unlike every other error pane, the server owns all of the content here. The API error shape
/// isn't flexible enough to carry a screen definition, so the backend tucks it into the
/// `extra_fields` object of the error instead. Any endpoint can opt in by setting
/// `use_generic_error_pane`, so parsing is intentionally endpoint-agnostic.
struct FinancialConnectionsGenericErrorPane: Equatable {
    /// What the primary button does.
    enum PrimaryCtaAction: String {
        /// Create a new auth session and send the user back through the institution's OAuth flow.
        case restartAuthFlow = "restart_auth_flow"
    }

    let heading: String
    let subheading: String
    let primaryCta: String
    /// `nil` when the server sends an action this version of the SDK doesn't know how to handle.
    let primaryCtaAction: PrimaryCtaAction?
    let iconUrl: String?
    let imageUrl: String?

    /// Returns `nil` if any of the content needed to render the pane is missing, which lets
    /// callers fall back to the standard error handling rather than showing a broken screen.
    init?(extraFields: [String: Any]) {
        guard
            let heading = extraFields["generic_error_pane_heading"] as? String,
            let subheading = extraFields["generic_error_pane_subheading"] as? String,
            let primaryCta = extraFields["generic_error_pane_primary_cta"] as? String
        else {
            return nil
        }
        self.heading = heading
        self.subheading = subheading
        self.primaryCta = primaryCta
        self.primaryCtaAction = (extraFields["generic_error_pane_primary_cta_action"] as? String)
            .flatMap(PrimaryCtaAction.init(rawValue:))
        self.iconUrl = extraFields["generic_error_pane_icon_url"] as? String
        self.imageUrl = extraFields["generic_error_pane_image_url"] as? String
    }

    /// Extracts a generic error pane from an API error, or returns `nil` if the error
    /// doesn't opt into one.
    static func from(error: Error) -> FinancialConnectionsGenericErrorPane? {
        guard
            let extraFields = error.extraFields,
            extraFields["use_generic_error_pane"] as? Bool == true
        else {
            return nil
        }
        return FinancialConnectionsGenericErrorPane(extraFields: extraFields)
    }
}
