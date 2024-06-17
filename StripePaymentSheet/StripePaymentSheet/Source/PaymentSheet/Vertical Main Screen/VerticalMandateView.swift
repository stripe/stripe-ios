//
//  VerticalMandateView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 6/11/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class VerticalMandateView: UIView {
    var paymentMethodType: PaymentSheet.PaymentMethodType? {
        didSet {
            updateUI()
        }
    }
    let formProvider: (PaymentSheet.PaymentMethodType) -> PaymentMethodElement?
    private var mandateView: UIView?
    var isDisplayingMandate: Bool {
        return mandateView != nil
    }

    init(formProvider: @escaping (PaymentSheet.PaymentMethodType) -> (PaymentMethodElement?)) {
        self.formProvider = formProvider
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUI() {
        // Remove old mandate view, if any
        mandateView?.removeFromSuperview()
        mandateView = nil
        guard let paymentMethodType else {
            return
        }

        // Generate the form
        guard
            let form = formProvider(paymentMethodType),
            !form.collectsUserInput
        else {
            // If it collects user input, the mandate will be displayed in the form and not here
            return
        }
        // Get the mandate from the form, if available
        // 🙋‍♂️ Note: assumes mandates are SimpleMandateElement!
        guard let mandateElement = form.getAllUnwrappedSubElements().compactMap({ $0 as? SimpleMandateElement }).first else {
            return
        }
        // Display the mandate
        addAndPinSubview(mandateElement.view)
        mandateView = mandateElement.view
    }
}
