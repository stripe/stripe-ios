//
//  ConnectionsSDKInterface.swift
//  StripeCore
//
//  Created by Vardges Avetisyan on 2/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) @frozen public enum FinancialConnectionsSDKResult {
    case completed(linkedBank: LinkedBank)
    case cancelled
    case failed(error: Error)
}

@_spi(STP) public protocol FinancialConnectionsSDKInterface {
    init()
    func presentFinancialConnectionsSheet(
        apiClient: STPAPIClient,
        clientSecret: String,
        returnURL: String?,
        onEvent: ((FinancialConnectionsEvent) -> Void)?,
        from presentingViewController: UIViewController,
        completion: @escaping (FinancialConnectionsSDKResult) -> Void
    )
}

// MARK: - Types

@_spi(STP) public protocol LinkedBank {
    var sessionId: String { get }
    var accountId: String { get }
    var displayName: String? { get }
    var bankName: String? { get }
    var last4: String? { get }
    var instantlyVerified: Bool { get }
}

public struct FinancialConnectionsEvent {

   public enum Name: String {
       /// The sheet successfully opens
       case open = "open"

       /// Manual entry flow initiated
       case manualEntryInitiated = "manual_entry_initiated"

       /// “Agree and continue” selected on consent pane
       case consentAcquired = "consent_acquired"

       /// The search bar is selected, the user types some search terms and gets an API response
       case searchInitiated = "search_initiated"

       /// Institution selected, either from featured institutions or search results
       ///
       /// `institution_name` will be available in metadata as a String.
       case institutionSelected = "institution_selected"

       /// Successful authorization completed
       case institutionAuthorized = "institution_authorized"

       /// Accounts selected and “confirm” selected
       case accountsSelected = "accounts_selected"

       /// The flow is completed and selected accounts are correctly attached to the payment instrument.
       //
       // Note that this doesn’t mean the user has actually clicked “Done”;
       // at this point that action just closes the modal.
       // We won’t emit an event for that.
       ///
       /// `manual_entry` will be available in metadata as a Bool.
       case success = "success"

       /// An error is encountered; see error codes for more
       ///
       /// `error_code` will be available in metadata as ErrorCode
       case error = "error"

       /// The modal is closed by the user by clicking the “X” button.
       case cancel = "cancel"

       /// The modal is launched on an external browser. After receiving this event, no other events
       /// will be sent until the browser session is completed with either 'success', 'cancel' or 'error'.
       case flowLaunchedInBrowser = "flow_launched_in_browser"
   }

   public struct Metadata {

       public let dictionary: [String: Any]

       private static let manualEntryKey = "manual_entry"
       public var manualEntry: Bool? {
           return dictionary[Self.manualEntryKey] as? Bool
       }

       private static let institutionNameKey = "institution_name"
       public var institutionNameKey: String? {
           return dictionary[Self.institutionNameKey] as? String
       }

       private static let errorCodeKey = "error_code"
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
       /// Cannot retrieve account numbers for selected accounts
       case accountNumbersUnavailable = "account_numbers_unavailable"

       /// Cannot retrieve accounts for the selected institution
       case accountsUnavailable = "accounts_unavailable"

       /// For payments flows, no debitable account is available at the selected institution
       case noDebitableAccount = "no_debitable_account"

       /// Authorizing with the selected institution has failed
       case authorizationFailed = "authorization_failed"

       /// Institution the user selects is down for expected maintenance
       case institutionUnavailablePlanned = "institution_unavailable_planned"

       /// Institution the user selects is unexpectedly down
       case institutionUnavailableUnplanned = "institution_unavailable_unplanned"

       /// Timed out talking to our partner or downstream institutions
       case institutionTimeout = "institution_timeout"

       /// Something unexpected errors, either in an API call or on the client
       case unexpectedError = "unexpected_error"

       /// Client secret powering the session has expired
       case sessionExpired = "session_expired"

       /// Failed hCaptcha challenge
       case failedBotDetection = "failed_bot_detection"
   }

   public let name: Name
   public let metadata: Metadata

    @_spi(STP) public init(name: Name, metadata: Metadata = Metadata()) {
       self.name = name
       self.metadata = metadata
   }
}
