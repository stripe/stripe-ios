//
//  PaymentMethodTypeSelectorViewModel.swift
//  StripePaymentSheet
//
//  Created by Eduardo Urias on 8/23/23.
//

import Foundation
@_spi(STP) import StripeCore

class PaymentMethodTypeSelectorViewModel: ObservableViewModel {
    var notifier = ViewModelObservationNotifier()

    let paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    var selected: PaymentSheet.PaymentMethodType {
        didSet {
            assert(paymentMethodTypes.contains(selected))

            guard oldValue != selected else { return }

            logPaymentMethodTypeSelected()
            notifier.notify()
        }
    }

    // This property is only used for logging purposes.
    let isPaymentSheet: Bool

    var selectedItemIndex: Int {
        guard let index = paymentMethodTypes.firstIndex(of: selected) else {
            assertionFailure()
            return 0
        }
        return index
    }

    init(
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        initialPaymentMethodType: PaymentSheet.PaymentMethodType? = nil,
        isPaymentSheet: Bool = false
    ) {
        self.paymentMethodTypes = paymentMethodTypes
        let selectedItemIndex: Int = {
            if let initialPaymentMethodType = initialPaymentMethodType {
                return paymentMethodTypes.firstIndex(of: initialPaymentMethodType) ?? 0
            } else {
                return 0
            }
        }()

        self.selected = paymentMethodTypes[selectedItemIndex]
        self.isPaymentSheet = isPaymentSheet
    }

    func selectItem(at index: Int) {
        guard index >= 0 && index < paymentMethodTypes.count else {
            assertionFailure("Index out of bounds: \(index)")
            return
        }

        selected = paymentMethodTypes[index]
    }
}

// MARK: - Private methods

extension PaymentMethodTypeSelectorViewModel {
    private func logPaymentMethodTypeSelected() {
        // Only log this event when the selector is being used by PaymentSheet.
        if isPaymentSheet {
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(
                event: .paymentSheetCarouselPaymentMethodTapped,
                paymentMethodTypeAnalyticsValue: selected.identifier
            )
        }
    }
}
