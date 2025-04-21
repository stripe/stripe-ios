//
//  CVCReconfirmationVerticalViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/16/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

class CVCReconfirmationVerticalViewController: UIViewController {
    private lazy var headerLabel: UILabel = {
        let header = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        header.text = String.Localized.confirm_your_cvc
        return header
    }()
    var paymentOption: PaymentOption {
        .saved(paymentMethod: paymentMethod, confirmParams: paymentOptionIntentConfirmParams)
    }
    var paymentOptionIntentConfirmParams: IntentConfirmParams? {
        let params = IntentConfirmParams(type: .stripe(.card))
        if let updatedParams = cvcRecollectionElement.updateParams(params: params) {
            return updatedParams
        }
        return nil
    }
    let paymentMethod: STPPaymentMethod
    let configuration: PaymentSheet.Configuration
    let cardBrand: STPCardBrand
    let cvcRecollectionElement: CVCRecollectionElement

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        paymentMethod: STPPaymentMethod,
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        elementDelegate: ElementDelegate
    ) {
        self.cvcRecollectionElement = CVCRecollectionElement(paymentMethod: paymentMethod,
            mode: .detailedWithInput,
            appearance: configuration.appearance
        )
        self.paymentMethod = paymentMethod
        self.configuration = configuration
        self.cardBrand = paymentMethod.card?.brand ?? .unknown
        self.cvcRecollectionElement.delegate = elementDelegate
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        // One stack view contains all our subviews
        let stackView = UIStackView(arrangedSubviews: [
            headerLabel,
            cvcRecollectionElement.view,
        ])
        stackView.spacing = 16
        stackView.axis = .vertical
        view.addAndPinSubview(stackView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.cvcRecollectionElement.beginEditing()
    }
}
