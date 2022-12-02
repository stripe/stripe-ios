//
//  STPInputTextFieldValidator.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

enum STPValidatedInputState {
    case unknown
    case incomplete(description: String?)
    case invalid(errorMessage: String?)
    case valid(message: String?)
    case processing
}

/// :nodoc:
extension STPValidatedInputState: Equatable {

}

class STPInputTextFieldValidator: NSObject {

    var defaultErrorMessage: String? {
        return nil
    }

    var observersHash = NSHashTable<AnyObject>.weakObjects()

    weak var textField: STPInputTextField?

    public var inputValue: String?

    var validationState: STPValidatedInputState = .unknown {
        didSet {
            updateObservers(with: validationState, previous: oldValue)
        }
    }

    public func addObserver(_ validationObserver: STPFormInputValidationObserver) {
        // This is not thread safe: https://jira.corp.stripe.com/browse/MOBILESDK-108
        observersHash.add(validationObserver)
    }

    public func removeObserver(_ validationObserver: STPFormInputValidationObserver) {
        // This is not thread safe: https://jira.corp.stripe.com/browse/MOBILESDK-108
        observersHash.remove(validationObserver)
    }

    func updateObservers(with state: STPValidatedInputState, previous: STPValidatedInputState) {
        guard let textField = textField,
            observersHash.count > 0
        else {
            return
        }
        let observersCopy = observersHash.allObjects.compactMap({
            $0 as? STPFormInputValidationObserver
        })
        for observer in observersCopy {
            observer.validationDidUpdate(to: state, from: previous, for: inputValue, in: textField)
        }
    }
}
