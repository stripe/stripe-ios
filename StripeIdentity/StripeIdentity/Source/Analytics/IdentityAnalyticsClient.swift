//
//  IdentityAnalyticsClient.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/7/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

/// Wrapper for AnalyticsClient that formats Identity-specific analytics
final class IdentityAnalyticsClient {

    enum EventName: String, Encodable {
        case sheetPresented = "sheet_presented"
        case sheetClosed = "sheet_closed"
        case verificationFailed = "verification_failed"
    }

    static let sharedAnalyticsClient = AnalyticsClientV2(
        clientId: "mobile-identity-sdk",
        origin: "stripe-identity-ios"
    )

    let verificationSessionId: String
    let analyticsClient: AnalyticsClientV2Protocol

    init(
        verificationSessionId: String,
        analyticsClient: AnalyticsClientV2Protocol = IdentityAnalyticsClient.sharedAnalyticsClient
    ) {
        self.verificationSessionId = verificationSessionId
        self.analyticsClient = analyticsClient
    }

    private func logAnalytic(
        _ eventName: EventName,
        metadata: [String: Any]
    ) {
        analyticsClient.log(
            eventName: eventName.rawValue,
            parameters: [
                "verification_session": verificationSessionId,
                "event_metadata": metadata
            ]
        )
    }

    func logSheetPresented() {
        logAnalytic(
            .sheetPresented,
            metadata: [:]
        )
    }

    func logSheetClosedOrFailed(
        result: IdentityVerificationSheet.VerificationFlowResult,
        sheetController: VerificationSheetControllerProtocol,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sheetClosedResult: String

        switch result {
        case .flowCompleted:
            sheetClosedResult = "flow_complete"
        case .flowCanceled:
            sheetClosedResult = "flow_canceled"
        case .flowFailed(error: let error):
            var metadata: [String: Any] = [:]

            // TODO(mludowise|IDPROD-3302): Log last_screen

            if let frontUploadMethod = sheetController.collectedData.idDocumentFront?.uploadMethod {
                metadata["doc_front_upload_type"] = frontUploadMethod.rawValue
            }
            if let backUploadMethod = sheetController.collectedData.idDocumentBack?.uploadMethod {
                metadata["doc_back_upload_type"] = backUploadMethod.rawValue
            }
            metadata["error"] = AnalyticsClientV2.serialize(
                error: error as AnalyticLoggableError,
                filePath: filePath,
                line: line
            )

            logAnalytic(
                .verificationFailed,
                metadata: metadata
            )
            return
        }

        logAnalytic(
            .sheetClosed,
            metadata: [
                "session_result": sheetClosedResult
            ]
        )
    }
}
