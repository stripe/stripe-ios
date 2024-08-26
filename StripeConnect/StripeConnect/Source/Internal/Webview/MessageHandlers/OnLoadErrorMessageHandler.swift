//
//  OnLoadErrorMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/9/24.
//

import Foundation

extension OnLoadErrorMessageHandler.Values.ErrorValue {
    var connectEmbedError: EmbeddedComponentError {
        // API Error is a catch all so defer to that if we get an unknown type.
        // TODO(MXMOBILE-2491): Log error analytic if `type` is unrecognized
        .init(type: .init(rawValue: type) ?? .apiError, description: message)
    }
}

// Emitted when there is an error loading connect js
class OnLoadErrorMessageHandler: OnSetterFunctionCalledMessageHandler<OnLoadErrorMessageHandler.Values> {
    struct Values: Codable, Equatable {
        let error: ErrorValue
        
        struct ErrorValue: Codable, Equatable {
            let type: String
            let message: String
        }
    }
    
    init(didReceiveMessage: @escaping (Values) -> Void) {
        super.init(setter: "setOnLoadError", didReceiveMessage: { values in
            if let values {
                didReceiveMessage(values)
            } else {
                //TODO: MXMOBILE-2491 Log as analytics
                debugPrint("Did not receive values for onLoad")
            }
        })
    }
}
