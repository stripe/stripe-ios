//
//  EmbeddedPaymentMethodsView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/30/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

// TODO(porter) Probably shouldn't be public, just easy for testing.
@_spi(STP) public class EmbeddedPaymentMethodsView: UIView {
    private let appearance: PaymentSheet.Appearance

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = appearance.paymentOptionView.style == .floating ? appearance.paymentOptionView.paymentMethodRow.spacing : 0
        return stackView
    }()

    public init(savedPaymentMethod: STPPaymentMethod?,
                appearance: PaymentSheet.Appearance,
                shouldShowApplePay: Bool,
                shouldShowLink: Bool) {
        self.appearance = appearance
        super.init(frame: .zero)

        if let savedPaymentMethod {
            stackView.addArrangedSubview(RowButton.makeForSavedPaymentMethod(paymentMethod: savedPaymentMethod,
                                                                             appearance: appearance,
                                                                             didTap: handleRowSelection(selectedRowButton:)))
        }

        if shouldShowApplePay {
            stackView.addArrangedSubview(RowButton.makeForApplePay(appearance: appearance,
                                                                   didTap: handleRowSelection(selectedRowButton:)))
        }

        if shouldShowLink {
            stackView.addArrangedSubview(RowButton.makeForLink(appearance: appearance,
                                                               didTap: handleRowSelection(selectedRowButton:)))
        }

        // TODO(porter) Pass these in via init later
        let paymentMethodTypes: [PaymentSheet.PaymentMethodType] = [.stripe(.bancontact), .stripe(.klarna), .stripe(.card)]
        for type in paymentMethodTypes {
            stackView.addArrangedSubview(RowButton.makeForPaymentMethodType(paymentMethodType: type,
                                                                            savedPaymentMethodType: savedPaymentMethod?.type,
                                                                            appearance: appearance,
                                                                            shouldAnimateOnPress: true,
                                                                            didTap: handleRowSelection(selectedRowButton:)))
        }

        if appearance.paymentOptionView.style != .floating {
            stackView.addSeparators(color: appearance.paymentOptionView.paymentMethodRow.flat.separatorColor ?? appearance.colors.componentBorder,
                                    thickness: appearance.paymentOptionView.paymentMethodRow.flat.separatorThickness,
                                    inset: appearance.paymentOptionView.paymentMethodRow.flat.separatorInset ?? appearance.paymentOptionView.style.defaultInsets,
                                    addTopSeparator: appearance.paymentOptionView.paymentMethodRow.flat.topSeparatorEnabled,
                                    addBottomSeparator: appearance.paymentOptionView.paymentMethodRow.flat.bottomSeparatorEnabled)
        }

        addAndPinSubview(stackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Tap handling
    func handleRowSelection(selectedRowButton: RowButton) {
        for case let rowButton as RowButton in stackView.arrangedSubviews {
            rowButton.isSelected = rowButton === selectedRowButton
        }
    }
}

extension PaymentSheet.Appearance.PaymentOptionView.Style {

    var defaultInsets: UIEdgeInsets {
        switch self {
        case .flatRadio:
            return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
        case .flatCheck:
            return .zero
        case .floating:
            return .zero
        }
    }
}
