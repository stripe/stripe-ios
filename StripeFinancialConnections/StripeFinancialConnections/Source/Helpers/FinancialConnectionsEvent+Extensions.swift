//
//  FinancialConnectionsEvent+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/10/23.
//

import Foundation
@_spi(STP) import StripeCore

extension FinancialConnectionsEvent {

    static func events(fromError error: Error) -> [FinancialConnectionsEvent] {
        var errorCodes: [FinancialConnectionsEvent.ErrorCode] = []
        if
            let error = error as? StripeError,
            case .apiError(let apiError) = error,
            let extraFields = apiError.allResponseFields["extra_fields"] as? [String: Any],
            let eventsToEmitString = extraFields["events_to_emit"] as? String,
            let eventsToEmitData = eventsToEmitString.data(using: .utf8),
            let eventsToEmitArray = try? JSONSerialization.jsonObject(
                with: eventsToEmitData,
                options: []
            ) as? [[String: Any]],
            let errorEventsToEmit = [[String: Any]]?(eventsToEmitArray.filter({ ($0["type"] as? String) == "error" })),
            !errorEventsToEmit.isEmpty
        {
            errorEventsToEmit.forEach { eventToEmit in
                if
                    let errorDictionary = eventToEmit["error"] as? [String: Any],
                    let errorCodeString = errorDictionary["error_code"] as? String,
                    let errorCode = FinancialConnectionsEvent.ErrorCode(rawValue: errorCodeString)
                {
                    errorCodes.append(errorCode)
                } else {
                    errorCodes.append(.unexpectedError)
                }
            }
        } else {
            errorCodes.append(.unexpectedError)
        }
        return errorCodes.map { errorCode in
            FinancialConnectionsEvent(
                name: .error,
                metadata: FinancialConnectionsEvent.Metadata(
                    errorCode: errorCode
                )
            )
        }
    }
}
