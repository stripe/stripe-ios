//
//  CVCRecollectionElement.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

final class CVCRecollectionElement: ContainerElement {
    var elements: [Element] {
        return [sectionElement]
    }

    enum Mode {
        /// Has a title. Doesn't have an information view.
        case inputOnly
        /// Doesn't have a title. Has an information view.
        case detailedWithInput
    }
    weak var delegate: ElementDelegate?
    var mode: Mode
    lazy var view: UIView = {
        let stack = UIStackView(arrangedSubviews: [sectionElement.view])
        if mode == .inputOnly {
            stack.insertArrangedSubview(.makeSpacerView(height: 10), at: 0)
        }
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()
    var paymentMethod: STPPaymentMethod
    let appearance: PaymentSheet.Appearance

    lazy var textFieldElement: TextFieldElement = {
        let configuration = TextFieldElement.CVCConfiguration { [weak self] in
            return self?.paymentMethod.card?.brand ?? .unknown
        }
        return TextFieldElement(configuration: configuration, theme: appearance.asElementsTheme)
    }()

    lazy var sectionElement: SectionElement = {
        let title = mode == .inputOnly ? String(format: String.Localized.cvc_section_title, String.Localized.cvc) : nil
        let elements: [Element]
        switch mode {
        case .inputOnly:
            elements = [textFieldElement]
        case .detailedWithInput:
            let cardDetails = StaticElement(view: CardDetailView(paymentMethod: paymentMethod, appearance: appearance))
            elements = [SectionElement.MultiElementRow([cardDetails, textFieldElement], theme: appearance.asElementsTheme)]
        }
        let sectionElement = SectionElement(title: title, elements: elements, selectionBehavior: .default, theme: appearance.asElementsTheme)
        sectionElement.delegate = self
        return sectionElement
    }()

    init(
        paymentMethod: STPPaymentMethod,
        mode: Mode,
        appearance: PaymentSheet.Appearance
    ) {
        self.paymentMethod = paymentMethod
        self.appearance = appearance
        self.mode = mode
    }

    func beginEditing() {
        DispatchQueue.main.async {
            self.textFieldElement.beginEditing()
        }
    }

    var validationState: ElementValidationState {
        return textFieldElement.validationState
    }
    func clearTextFields() {
        textFieldElement.setText("")
    }
}

extension CVCRecollectionElement: ElementDelegate {
    func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }
    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }
}

extension CVCRecollectionElement: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        if case .valid = textFieldElement.validationState {
            let cardOptions = STPConfirmCardOptions()
            let cvc = textFieldElement.text
            cardOptions.cvc = cvc
            #if DEBUG
            // There's no way to test an invalid recollected cvc in the API, so we hardcode a way:
            if cvc == "666" {
                cardOptions.cvc = "test_invalid_cvc"
            }
            #endif
            params.confirmPaymentMethodOptions.cardOptions = cardOptions
            return params
        }
        return nil
    }
}

// MARK: - CardDetailView - e.g. [VISA] 4242
final class CardDetailView: UIView {
    private let appearance: PaymentSheet.Appearance
    private let paymentMethod: STPPaymentMethod
    lazy var paymentMethodImage: UIImageView = {
        let imageView = UIImageView(image: paymentMethod.makeIcon())
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    lazy var paymentMethodLabelPrimary: UILabel = {
        let label = UILabel()
        label.font = appearance.scaledFont(for: appearance.font.base, style: .body, maximumPointSize: 15)
        label.textColor = appearance.colors.componentText
        label.numberOfLines = 0
        label.text = paymentMethod.paymentSheetLabel
        return label
    }()

    lazy var hStackView: UIStackView = {
        let hStackView = UIStackView(arrangedSubviews: [paymentMethodImage, paymentMethodLabelPrimary])
        hStackView.axis = .horizontal
        hStackView.spacing = 5.0
        hStackView.alignment = .center
        return hStackView
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance) {
        self.appearance = appearance
        self.paymentMethod = paymentMethod
        super.init(frame: .zero)
        self.backgroundColor = appearance.asElementsTheme.colors.readonlyComponentBackground
        addAndPinSubview(hStackView, insets: appearance.textFieldInsets)
    }
}
