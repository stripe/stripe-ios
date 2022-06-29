//
//  VerificationSheetFlowControllerError.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/27/22.
//

import Foundation
@_spi(STP) import StripeCore

/// An error that prevents the user from finishing the verification flow
enum VerificationSheetFlowControllerError: Error {
    /// A field is required prior to this step in the flow but has not been submitted yet
    case missingRequiredInput(Set<StripeAPI.VerificationPageFieldType>)
    /// There is no screen to display to the user matching the requirements sent from the server
    case noScreenForRequirements(Set<StripeAPI.VerificationPageFieldType>)
    /// The server did not include a `selfie` config, but `face` is a missing field
    case missingSelfieConfig
    /// Attempted to open a URL that could not be constructed from the given string
    case malformedURL(String)
    /// An unknown error occurred elsewhere in the stack
    case unknown(Error)
}

extension VerificationSheetFlowControllerError: LocalizedError {
    /// Localized description of the error that displays to the user inside `ErrorViewController`
    var localizedDescription: String {
        // Note: Since this displays to end-users, these are all errors that
        // occur as a result of a bad server-side configuration that the user
        // cannot action on, only display a generic error message.
        return NSError.stp_unexpectedErrorMessage()
    }
}

extension VerificationSheetFlowControllerError: AnalyticLoggableError {
    func analyticLoggableSerializeForLogging() -> [String : Any] {
        var payload: [String: Any]
        switch self {
        case .missingRequiredInput(let fields):
            payload = [
                "type": "missing_required_input",
                "fields": fields.map { $0.rawValue }.sorted()
            ]
        case .noScreenForRequirements(let fields):
            payload = [
                "type": "no_screen_for_requirements",
                "fields": fields.map { $0.rawValue }.sorted()
            ]
        case .missingSelfieConfig:
            payload = [
                "type": "missing_selfie"
            ]
        case .malformedURL(let value):
            payload = [
                "type": "malformed_url",
                "value": value
            ]
        case .unknown(let error):
            return error.serializeForLogging()
        }

        payload["domain"] = (self as NSError).domain
        return payload
    }
}
