//
//  EmbeddedPaymentMethodsView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/30/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

// TODO(porter) Probably shouldn't be public, just easy for testing.
@_spi(EmbeddedPaymentMethodsViewBeta) public class EmbeddedPaymentMethodsView: UIView {
    private let embeddedAppearance: EmbeddedAppearance

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = embeddedAppearance.style == .floating ? embeddedAppearance.floating.spacing : 0
        return stackView
    }()

    // TODO(porter) Remove later, just for use in EmbeddedPlaygroundViewController since PaymentMethodType and AccessoryType aren't public
    public convenience init(savedPaymentMethod: STPPaymentMethod?,
                            embeddedAppearance: EmbeddedAppearance,
                            shouldShowApplePay: Bool,
                            shouldShowLink: Bool) {
        let paymentMethodTypes: [PaymentSheet.PaymentMethodType] = [.stripe(.bancontact), .stripe(.klarna), .stripe(.card)]
        let savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType? = .viewMore

        self.init(paymentMethodTypes: paymentMethodTypes, savedPaymentMethod: savedPaymentMethod, embeddedAppearance: embeddedAppearance, shouldShowApplePay: shouldShowApplePay, shouldShowLink: shouldShowLink, savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType)
    }

    init(paymentMethodTypes: [PaymentSheet.PaymentMethodType],
         savedPaymentMethod: STPPaymentMethod?,
         embeddedAppearance: EmbeddedAppearance,
         shouldShowApplePay: Bool,
         shouldShowLink: Bool,
         savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?) {
        self.embeddedAppearance = embeddedAppearance
        super.init(frame: .zero)
        let rowButtonAppearance = embeddedAppearance.style.appearanceForStyle(appearance: embeddedAppearance)

        if let savedPaymentMethod {
            let accessoryButton: RowButton.RightAccessoryButton? = {
                if let savedPaymentMethodAccessoryType {
                    return RowButton.RightAccessoryButton(accessoryType: savedPaymentMethodAccessoryType, embeddedAppearance: rowButtonAppearance, didTap: didTapAccessoryButton)
                } else {
                    return nil
                }
            }()
            stackView.addArrangedSubview(RowButton.makeForSavedPaymentMethod(paymentMethod: savedPaymentMethod,
                                                                             embeddedAppearance: rowButtonAppearance,
                                                                             rightAccessoryView: accessoryButton,
                                                                             didTap: handleRowSelection(selectedRowButton:)))
        }

        // Add card before Apple Pay and Link if present and before any other LPMs
        if paymentMethodTypes.contains(.stripe(.card)) {
            stackView.addArrangedSubview(RowButton.makeForPaymentMethodType(paymentMethodType: .stripe(.card),
                                                                            savedPaymentMethodType: savedPaymentMethod?.type,
                                                                            embeddedAppearance: rowButtonAppearance,
                                                                            shouldAnimateOnPress: true,
                                                                            didTap: handleRowSelection(selectedRowButton:)))
        }

        if shouldShowApplePay {
            stackView.addArrangedSubview(RowButton.makeForApplePay(embeddedAppearance: rowButtonAppearance,
                                                                   didTap: handleRowSelection(selectedRowButton:)))
        }

        if shouldShowLink {
            stackView.addArrangedSubview(RowButton.makeForLink(embeddedAppearance: rowButtonAppearance,
                                                               didTap: handleRowSelection(selectedRowButton:)))
        }

        for paymentMethodType in paymentMethodTypes where paymentMethodType != .stripe(.card) {
            stackView.addArrangedSubview(RowButton.makeForPaymentMethodType(paymentMethodType: paymentMethodType,
                                                                            subtitle: VerticalPaymentMethodListViewController.subtitleText(for: paymentMethodType),
                                                                            savedPaymentMethodType: savedPaymentMethod?.type,
                                                                            embeddedAppearance: rowButtonAppearance,
                                                                            shouldAnimateOnPress: true,
                                                                            didTap: handleRowSelection(selectedRowButton:)))
        }

        if rowButtonAppearance.style != .floating {
            stackView.addSeparators(color: embeddedAppearance.flat.separatorColor ?? embeddedAppearance.colors.componentBorder,
                                    backgroundColor: embeddedAppearance.colors.componentBackground,
                                    thickness: embeddedAppearance.flat.separatorThickness,
                                    inset: embeddedAppearance.flat.separatorInset ?? rowButtonAppearance.style.defaultInsets,
                                    addTopSeparator: embeddedAppearance.flat.topSeparatorEnabled,
                                    addBottomSeparator: embeddedAppearance.flat.bottomSeparatorEnabled)
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

    func didTapAccessoryButton() {
        // TODO(porter)
    }
}

extension EmbeddedAppearance.Style {

    var defaultInsets: UIEdgeInsets {
        switch self {
        case .flatRadio:
            return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
        case .floating:
            return .zero
        }
    }

    fileprivate func appearanceForStyle(appearance: EmbeddedAppearance) -> EmbeddedAppearance {
        switch self {
        case .flatRadio:
            // TODO(porter) See if there is a better way to do this, less sneaky
            var appearance = appearance
            appearance.borderWidth = 0.0
            appearance.colors.componentBorderSelected = .clear
            appearance.cornerRadius = 0.0
            appearance.shadow = .disabled
            return appearance
        case .floating:
            return appearance
        }
    }
}
