//
//  EmbeddedLinkInlineVerificationExperiment.swift
//  StripePaymentSheet
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

/// Measures inline Link verification in the Embedded Payment Element.
///
/// `treatment` shows inline verification, and `control` and `control_test` keep the existing Link row. Sessions without an assignment show it,
/// so turning the experiment off ships it to everyone the server flag enables.
struct EmbeddedLinkInlineVerificationExperiment: LoggableExperiment {
    static let experimentName = "ocs_mobile_embedded_link_inline_otp"

    let name: String = experimentName
    let arbId: String
    let group: ExperimentGroup
    let dimensions: [String: String]

    var showsInlineVerification: Bool {
        group == .treatment
    }

    /// Returns nil when the session has no assignment.
    init?(elementsSession: STPElementsSession, dimensions: [String: String]) {
        guard let assignment = elementsSession.experimentsData?.experimentAssignments[Self.experimentName] else {
            return nil
        }
        self.arbId = elementsSession.experimentsData?.arbId ?? ""
        self.group = assignment
        self.dimensions = dimensions.merging([
            "in_app_elements_integration_type": ExperimentIntegrationShape.embedded.rawValue,
            "elements_session_id": elementsSession.sessionID,
            "mobile_session_id": AnalyticsHelper.shared.sessionID ?? "N/a",
            "mobile_sdk_version": StripeAPIConfiguration.STPSDKVersion,
        ]) { experimentValue, _ in experimentValue }
    }

    /// Whether to show inline verification, given the session's assignment if it has one.
    static func showsInlineVerification(for experiment: Self?) -> Bool {
        experiment?.showsInlineVerification ?? true
    }
}
