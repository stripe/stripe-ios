//
//  CVCRecollectionView.swift
//  StripePaymentSheet
//
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

import UIKit

class CVCRecollectionView: UIView {
    lazy var titleLabel: UILabel = {
        return ElementsUI.makeSectionTitleLabel(theme: appearance.asElementsTheme)
    }()
    lazy var errorLabel: UILabel = {
        return ElementsUI.makeErrorLabel(theme: appearance.asElementsTheme)
    }()
    let textFieldView: UIView

    lazy var stackView: UIStackView = {
        let stackView = mode == .detailedWithInput
        ? UIStackView(arrangedSubviews: [
            cvcPaymentMethodInformationView,
            textFieldView,
        ])
        : UIStackView(arrangedSubviews: [
            textFieldView,
        ])

        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.axis = .horizontal
        stackView.layer.borderWidth = appearance.borderWidth
        stackView.layer.cornerRadius = appearance.cornerRadius
        stackView.layer.borderColor = appearance.colors.componentBorder.cgColor
        return stackView
    }()

    lazy var cvcPaymentMethodInformationView: CVCPaymentMethodInformationView = {
        let paymentMethodInfoView = CVCPaymentMethodInformationView(paymentMethod: paymentMethod,
                                                                    appearance: appearance)
        return paymentMethodInfoView
    }()

    let defaultValues: CVCRecollectionElement.DefaultValues
    var paymentMethod: STPPaymentMethod
    let mode: CVCRecollectionElement.Mode
    let appearance: PaymentSheet.Appearance
    weak var elementDelegate: ElementDelegate?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(defaultValues: CVCRecollectionElement.DefaultValues = .init(),
         paymentMethod: STPPaymentMethod,
         mode: CVCRecollectionElement.Mode,
         appearance: PaymentSheet.Appearance,
         textFieldView: UIView) {
        self.defaultValues = defaultValues
        self.paymentMethod = paymentMethod
        self.mode = mode
        self.appearance = appearance
        self.textFieldView = textFieldView
        super.init(frame: .zero)

        self.titleLabel.isHidden = mode == .detailedWithInput
        self.titleLabel.text = String(format: String.Localized.cvc_section_title, String.Localized.cvc)

        let stack = UIStackView(arrangedSubviews: [titleLabel, stackView, errorLabel])
        if mode == .inputOnly {
            stack.insertArrangedSubview(.makeSpacerView(height: 10), at: 0)
        }
        stack.axis = .vertical
        stack.spacing = 4
        addAndPinSubview(stack)

    }
    #if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.stackView.layer.borderColor = appearance.colors.componentBorder.cgColor
    }
    #endif
}
