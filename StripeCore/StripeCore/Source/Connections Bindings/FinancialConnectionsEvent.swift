//
//  FinancialConnectionsEvent.swift
//  StripeCore
//
//  Created by Krisjanis Gaidis on 4/16/24.
//

import Foundation

public struct FinancialConnectionsEvent {

    public enum Name: String {
        /// Invoked when the sheet successfully opens.
        case open = "open"

        /// Invoked when the manual entry flow is initiated.
        case manualEntryInitiated = "manual_entry_initiated"

        /// Invoked when “Agree and continue” is selected on the consent pane.
        case consentAcquired = "consent_acquired"

        /// Invoked when the search bar is selected, the user inputs search terms,
        /// and receives an API response.
        case searchInitiated = "search_initiated"

        /// Invoked when an institution is selected, either from featured institutions or search results.
        ///
        /// `institutionName` will be available in metadata as a `String`.
        case institutionSelected = "institution_selected"

        /// Invoked when the authorization is successfully completed.
        case institutionAuthorized = "institution_authorized"

        /// Invoked when accounts are selected and “confirm” is selected.
        case accountsSelected = "accounts_selected"

        /// Invoked when the flow is completed and selected accounts are correctly
        /// connected to the payment instrument.
        ///
        /// `manualEntry` will be available in metadata as a `Bool`.
        case success = "success"

        /// Invoked when an error is encountered. Refer to error codes for more details.
        ///
        /// `errorCode` will be available in metadata as `ErrorCode`.
        case error = "error"

        /// Invoked when the flow is cancelled, typically by the user pressing the "X" button.
        case cancel = "cancel"

        /// Invoked when the modal is launched in an external browser. After this event, no other events
        /// will be sent until the completion of the browser session with either 'success', 'cancel', or 'error'.
        case flowLaunchedInBrowser = "flow_launched_in_browser"
    }

    public struct Metadata {

        /// Dictionary containing metadata key-value pairs.
        ///
        /// For instance, `errorCode` could be a key `String` (`"error_code"`)
        /// mapped to a corresponding error code value `String` (`"unexpected_error"`).
        public let dictionary: [String: Any]

        private static let manualEntryKey = "manual_entry"

        /// A Boolean value that indicates if the user completed the process through the manual entry flow.
        ///
        /// This property is included as part of the `success` event.
        public var manualEntry: Bool? {
            return dictionary[Self.manualEntryKey] as? Bool
        }

        private static let institutionNameKey = "institution_name"

        /// A String value containing the name of the institution that the user selected.
        ///
        /// Appears as part of the `institutionSelected` event.
        public var institutionName: String? {
            return dictionary[Self.institutionNameKey] as? String
        }

        private static let errorCodeKey = "error_code"

        /// An `ErrorCode` value representing the type of error that occurred.
        ///
        /// Appears as part of the `error` event.
        public var errorCode: ErrorCode? {
            guard let errorCodeRawValue = dictionary[Self.errorCodeKey] as? String else {
                return nil
            }
            return ErrorCode(rawValue: errorCodeRawValue)
        }

        @_spi(STP) public init(
            institutionName: String? = nil,
            manualEntry: Bool? = nil,
            errorCode: ErrorCode? = nil
        ) {
            var dictionary: [String: Any] = [:]
            dictionary[Self.institutionNameKey] = institutionName
            dictionary[Self.manualEntryKey] = manualEntry
            dictionary[Self.errorCodeKey] = errorCode?.rawValue
            self.dictionary = dictionary
        }
    }

    public enum ErrorCode: String {

        /// The system could not retrieve account numbers for selected accounts.
        case accountNumbersUnavailable = "account_numbers_unavailable"

        /// The system could not retrieve accounts for the selected institution.
        case accountsUnavailable = "accounts_unavailable"

        /// For payment flows, no debitable account was available at the selected institution.
        case noDebitableAccount = "no_debitable_account"

        /// Authorization with the selected institution has failed.
        case authorizationFailed = "authorization_failed"

        /// The selected institution is down for expected maintenance.
        case institutionUnavailablePlanned = "institution_unavailable_planned"

        /// The selected institution is unexpectedly down.
        case institutionUnavailableUnplanned = "institution_unavailable_unplanned"

        /// A timeout occurred while communicating with our partner or downstream institutions.
        case institutionTimeout = "institution_timeout"

        /// An unexpected error occurred, either in an API call or on the client-side.
        case unexpectedError = "unexpected_error"

        /// The client secret that powers the session has expired.
        case sessionExpired = "session_expired"

        /// The hCaptcha challenge failed.
        case failedBotDetection = "failed_bot_detection"
    }

    /// The event's name. Represents the type of event that has occurred
    /// during the financial connection process.
    public let name: Name

    /// Event-associated metadata. Provides further detail related to the occurred event.
    public let metadata: Metadata

    @_spi(STP) public init(name: Name, metadata: Metadata = Metadata()) {
        self.name = name
        self.metadata = metadata
    }
}
