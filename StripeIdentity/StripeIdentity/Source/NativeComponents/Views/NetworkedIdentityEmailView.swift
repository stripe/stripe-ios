//
//  NetworkedIdentityEmailView.swift
//  StripeIdentity
//

@_spi(STP) import StripeUICore
import UIKit

protocol NetworkedIdentityEmailViewDelegate: AnyObject {
    func networkedIdentityEmailViewDidUpdate(_ view: NetworkedIdentityEmailView)
    func networkedIdentityEmailViewDidSubmit(_ view: NetworkedIdentityEmailView)
}

final class NetworkedIdentityEmailView: UIView {
    private enum Styling {
        static let spacing: CGFloat = 16
    }

    weak var delegate: NetworkedIdentityEmailViewDelegate?

    let emailElement: TextFieldElement
    private let emailSection: SectionElement

    var emailAddress: String {
        emailElement.text
    }

    var hasValidEmailAddress: Bool {
        emailElement.validationState.isValid
    }

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = IdentityUI.instructionsFont
        label.numberOfLines = 0
        return label
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = Styling.spacing
        return stackView
    }()

    init(bodyText: String) {
        emailElement = TextFieldElement.makeEmail(
            defaultValue: nil,
            theme: IdentityUI.identityElementsUITheme
        )
        emailSection = SectionElement(
            emailElement,
            theme: IdentityUI.identityElementsUITheme
        )
        super.init(frame: .zero)

        bodyLabel.text = bodyText
        emailSection.delegate = self
        stackView.addArrangedSubview(bodyLabel)
        stackView.addArrangedSubview(emailSection.view)
        addAndPinSubview(stackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(bodyText: String, isEnabled: Bool) {
        bodyLabel.text = bodyText
        if !isEnabled {
            emailElement.endEditing(true, continueToNextField: false)
        }
        emailElement.view.isUserInteractionEnabled = isEnabled
        isUserInteractionEnabled = isEnabled
        alpha = isEnabled ? 1 : 0.6
    }

    func beginEditing() {
        emailElement.beginEditing()
    }
}

extension NetworkedIdentityEmailView: ElementDelegate {
    func didUpdate(element: Element) {
        delegate?.networkedIdentityEmailViewDidUpdate(self)
    }

    func continueToNextField(element: Element) {
        guard hasValidEmailAddress else {
            emailElement.showValidationErrors()
            return
        }
        delegate?.networkedIdentityEmailViewDidSubmit(self)
    }
}
