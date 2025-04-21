//
//  FormHeaderView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 6/4/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class FormHeaderView: UIView {

    private lazy var label: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: appearance)
        if paymentMethodType == .stripe(.card) {
            label.text = shouldUseNewCardHeader ? String.Localized.add_new_card : String.Localized.add_card
        } else if paymentMethodType == .stripe(.USBankAccount) {
            label.text = String.Localized.add_us_bank_account
        } else {
            label.text = paymentMethodType.displayName
        }

        return label
    }()

    private lazy var imageView: PaymentMethodTypeImageView? = {
        switch paymentMethodType {
        case .stripe(.card), .stripe(.USBankAccount):
            // Don't show an image on the form header for card and US bank account
            return nil
        default:
            return PaymentMethodTypeImageView(paymentMethodType: paymentMethodType, contrastMatchingColor: appearance.colors.componentText, currency: currency)
        }
    }()

    private var promoBadgeView: PromoBadgeView?

    private lazy var spacerView: UIView = {
        // This spacer makes sure that the promo badge is aligned correctly
        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return spacerView
    }()

    private lazy var stackView: UIStackView = {
        var views = [imageView, label].compactMap { $0 }
        if let promoBadgeView {
            views.append(contentsOf: [promoBadgeView, spacerView])
        }

        let stackView = UIStackView(arrangedSubviews: views)
        stackView.spacing = 12
        if imageView == nil {
            // Avoid stackview ambiguous height
            stackView.alignment = .fill
        } else {
            stackView.alignment = .center
        }
        return stackView
    }()

    private let paymentMethodType: PaymentSheet.PaymentMethodType
    private let shouldUseNewCardHeader: Bool // true if the customer has a saved payment method that is type card
    private let appearance: PaymentSheet.Appearance
    private let currency: String?
    private var incentive: PaymentMethodIncentive?

    init(
        paymentMethodType: PaymentSheet.PaymentMethodType,
        shouldUseNewCardHeader: Bool,
        appearance: PaymentSheet.Appearance,
        currency: String?,
        incentive: PaymentMethodIncentive?
    ) {
        self.paymentMethodType = paymentMethodType
        self.shouldUseNewCardHeader = shouldUseNewCardHeader
        self.appearance = appearance
        self.currency = currency
        self.incentive = incentive
        self.promoBadgeView = Self.makePromoBadge(for: incentive, with: appearance)
        super.init(frame: .zero)
        addAndPinSubview(stackView)

        if let imageView {
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 20),
                imageView.heightAnchor.constraint(equalToConstant: 20),
            ])
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setIncentive(_ incentive: PaymentMethodIncentive?) {
        guard incentive != self.incentive else {
            return
        }

        if let promoBadgeView {
            stackView.removeArrangedSubview(promoBadgeView)
            promoBadgeView.removeFromSuperview()

            stackView.removeArrangedSubview(spacerView)
            spacerView.removeFromSuperview()
        }

        self.incentive = incentive

        if let incentive {
            promoBadgeView = Self.makePromoBadge(for: incentive, with: appearance)
            if let promoBadgeView {
                stackView.addArrangedSubview(promoBadgeView)
                stackView.addArrangedSubview(spacerView)
            }
        }
    }

    private static func makePromoBadge(
        for incentive: PaymentMethodIncentive?,
        with appearance: PaymentSheet.Appearance
    ) -> PromoBadgeView? {
        guard let incentive else {
            return nil
        }

        return PromoBadgeView(
            appearance: appearance,
            tinyMode: false,
            text: incentive.displayText
        )
    }
}
