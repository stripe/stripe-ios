//
//  CVCReconfirmationView.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

class CVCReconfirmationView: UIView {

    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            paymentMethodInfoView,
            textFieldElement.view,
        ])
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.axis = .horizontal
        stackView.layer.borderWidth = appearance.borderWidth
        stackView.layer.cornerRadius = appearance.cornerRadius
        stackView.layer.borderColor = appearance.colors.componentBorder.cgColor
        return stackView
    }()

    lazy var paymentMethodInfoView: PaymentMethodInformationView = {
        let paymentMethodInfoView = PaymentMethodInformationView(paymentMethod: paymentMethod,
                                                                 appearance: appearance)
        return paymentMethodInfoView
    }()

    lazy var textFieldElement: TextFieldElement = {
        let textFieldElement = TextFieldElement(configuration: cvcElementConfiguration, theme: appearance.asElementsTheme)
        textFieldElement.delegate = elementDelegate
        textFieldElement.view.backgroundColor = appearance.colors.componentBackground
        textFieldElement.view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        textFieldElement.view.layer.cornerRadius = appearance.cornerRadius
        return textFieldElement
    }()

    lazy var cvcElementConfiguration: TextFieldElement.CVCConfiguration = {
        return TextFieldElement.CVCConfiguration(defaultValue: defaultValues.cvc) { [weak self] in
            return self?.paymentMethod.card?.brand ?? .unknown
        }
    }()

    let defaultValues: CVCRecollectionElement.DefaultValues
    var paymentMethod: STPPaymentMethod
    let appearance: PaymentSheet.Appearance
    weak var elementDelegate: ElementDelegate?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(defaultValues: CVCRecollectionElement.DefaultValues = .init(),
         paymentMethod: STPPaymentMethod,
         appearance: PaymentSheet.Appearance,
         elementDelegate: ElementDelegate) {
        self.defaultValues = defaultValues
        self.paymentMethod = paymentMethod
        self.appearance = appearance
        self.elementDelegate = elementDelegate
        super.init(frame: .zero)
        addAndPinSubview(stackView)

    }
    #if !STP_BUILD_FOR_VISION
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.stackView.layer.borderColor = appearance.colors.componentBorder.cgColor
    }
    #endif
}
