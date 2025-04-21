//
//  LinkEmailElement.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 1/13/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

class LinkEmailElement: Element {
    let collectsUserInput: Bool = true

    weak var delegate: ElementDelegate?

    private let emailAddressElement: TextFieldElement

    private let activityIndicator: ActivityIndicator = {
        // TODO: Consider adding the activity indicator to TextFieldView
        let activityIndicator = ActivityIndicator(size: .medium)
        activityIndicator.setContentCompressionResistancePriority(.required, for: .horizontal)
        return activityIndicator
    }()

    private var infoView: LinkMoreInfoView?

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [emailAddressElement.view, activityIndicator])
        if let infoView = infoView {
            stackView.addArrangedSubview(infoView)
        }
        stackView.spacing = 0
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = .insets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: ElementsUI.contentViewInsets.trailing
        )
        if let infoView = infoView {
            NSLayoutConstraint.activate([
                activityIndicator.trailingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: -ElementsUI.contentViewInsets.trailing),
                infoView.widthAnchor.constraint(equalToConstant: LinkMoreInfoView.Constants.logoWidth),
            ])
        }
        return stackView
    }()

    var view: UIView {
        return stackView
    }

    public var emailAddressString: String? {
        return emailAddressElement.text
    }

    public var validationState: ElementValidationState {
        return emailAddressElement.validationState
    }

    public var indicatorTintColor: UIColor {
        get {
            return activityIndicator.color
        }

        set {
            activityIndicator.color = newValue
        }
    }

    public func startAnimating() {
        UIView.performWithoutAnimation {
            activityIndicator.startAnimating()
            stackView.setNeedsLayout()
            stackView.layoutSubviews()
        }
    }

    public func stopAnimating() {
        UIView.performWithoutAnimation {
            activityIndicator.stopAnimating()
            stackView.setNeedsLayout()
            stackView.layoutSubviews()
        }
    }

    public init(defaultValue: String? = nil, isOptional: Bool = false, showLogo: Bool, theme: ElementsAppearance = .default) {
        if showLogo {
            self.infoView = LinkMoreInfoView(theme: theme)
        }
        emailAddressElement = TextFieldElement.makeEmail(defaultValue: defaultValue,
                                                         isOptional: isOptional,
                                                         theme: theme)
        emailAddressElement.delegate = self
    }

    @discardableResult
    func beginEditing() -> Bool {
        return emailAddressElement.beginEditing()
    }
}

extension LinkEmailElement: ElementDelegate {
    func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }

    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }
}
