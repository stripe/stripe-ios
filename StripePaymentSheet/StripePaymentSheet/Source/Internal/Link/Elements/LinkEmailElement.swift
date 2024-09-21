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
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.setContentCompressionResistancePriority(.required, for: .horizontal)
        return activityIndicator
    }()

    private var infoView: LinkMoreInfoView?

    lazy var view: UIView = {
        let view = UIView()
        view.addSubview(emailAddressElement.view)
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: emailAddressElement.view.leadingAnchor, constant: ElementsUI.contentViewInsets.leading),
            view.centerYAnchor.constraint(equalTo: activityIndicator.centerYAnchor),
            view.centerYAnchor.constraint(equalTo: emailAddressElement.view.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: emailAddressElement.view.trailingAnchor),
            view.topAnchor.constraint(equalTo: emailAddressElement.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: emailAddressElement.view.bottomAnchor),
        ])
        if let infoView = infoView {
            infoView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(infoView)
            NSLayoutConstraint.activate([
                emailAddressElement.view.trailingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: ElementsUI.contentViewInsets.trailing),
                view.trailingAnchor.constraint(equalTo: infoView.trailingAnchor),
                view.centerYAnchor.constraint(equalTo: infoView.centerYAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                emailAddressElement.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: ElementsUI.contentViewInsets.trailing),
            ])
        }
        return view
    }()

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
            view.setNeedsLayout()
            view.layoutSubviews()
        }
    }

    public func stopAnimating() {
        UIView.performWithoutAnimation {
            activityIndicator.stopAnimating()
            view.setNeedsLayout()
            view.layoutSubviews()
        }
    }

    public init(defaultValue: String? = nil, isOptional: Bool = false, showLogo: Bool, theme: ElementsUITheme = .default) {
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
