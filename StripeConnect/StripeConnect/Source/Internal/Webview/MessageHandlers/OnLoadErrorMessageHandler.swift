//
//  OnLoadErrorMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/9/24.
//

import Foundation

extension OnLoadErrorMessageHandler.Values.ErrorValue {
    func connectEmbedError(analyticsClient: ComponentAnalyticsClient) -> EmbeddedComponentError {
        // API Error is a catch all so defer to that if we get an unknown type.
        let errorType = EmbeddedComponentError.ErrorType(rawValue: type)
        if errorType == nil {
            analyticsClient.logUnexpectedLoadErrorType(type: type)
        }
        return .init(type: .init(rawValue: type) ?? .apiError, description: message)
    }
}

// Emitted when there is an error loading connect js
class OnLoadErrorMessageHandler: OnSetterFunctionCalledMessageHandler.Handler {
    struct Values: Codable, Equatable {
        let error: ErrorValue

        struct ErrorValue: Codable, Equatable {
            let type: String
            let message: String
        }
    }

    init(didReceiveMessage: @escaping (Values) -> Void) {
        super.init(setter: "setOnLoadError", didReceiveMessage: didReceiveMessage)
    }
}
