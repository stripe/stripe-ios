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

    lazy var stackView: UIStackView = {
        let stackView = mode == .detailedWithInput
        ? UIStackView(arrangedSubviews: [
            cvcPaymentMethodInformationView,
            textFieldElement.view,
        ])
        : UIStackView(arrangedSubviews: [
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

    lazy var cvcPaymentMethodInformationView: CVCPaymentMethodInformationView = {
        let paymentMethodInfoView = CVCPaymentMethodInformationView(paymentMethod: paymentMethod,
                                                                    appearance: appearance)
        return paymentMethodInfoView
    }()

    lazy var textFieldElement: TextFieldElement = {
        let textFieldElement = TextFieldElement(configuration: cvcElementConfiguration, theme: appearance.asElementsTheme)
        textFieldElement.delegate = elementDelegate
        textFieldElement.view.backgroundColor = appearance.colors.componentBackground
        textFieldElement.view.layer.maskedCorners = mode == .detailedWithInput
        ? [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        : [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMinXMaxYCorner]
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
         elementDelegate: ElementDelegate) {
        self.defaultValues = defaultValues
        self.paymentMethod = paymentMethod
        self.mode = mode
        self.appearance = appearance
        self.elementDelegate = elementDelegate
        super.init(frame: .zero)

        self.titleLabel.isHidden = mode == .detailedWithInput
        let brand = (self.paymentMethod.card?.brand ?? .unknown) == .amex
        ? String.Localized.cvv
        : String.Localized.cvc

        self.titleLabel.text = String(format: String.Localized.cvc_section_title, brand)

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

    func update() {
        if case let .invalid(error, shouldDisplay) = textFieldElement.validationState, shouldDisplay {
            errorLabel.text = error.localizedDescription
            errorLabel.isHidden = false
            errorLabel.textColor = appearance.asElementsTheme.colors.danger
        } else {
            errorLabel.text = nil
            errorLabel.isHidden = true
        }
    }
}
