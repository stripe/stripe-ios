//
//  EmbeddedPaymentMethodsView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/30/24.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

@_spi(STP) public class EmbeddedPaymentMethodsView: UIView {
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        
        return stackView
    }()
    
    public init(savedPaymentMethod: STPPaymentMethod?,
                appearance: PaymentSheet.Appearance,
                shouldShowApplePay: Bool,
                shouldShowLink: Bool) {
        super.init(frame: .zero)
        
        if let savedPaymentMethod {
            stackView.addArrangedSubview(EmbeddedRowButton(appearance: appearance,
                                                           rowButton: .makeForSavedPaymentMethod(paymentMethod: savedPaymentMethod,
                                                                                                 appearance: appearance,
                                                                                                 didTap: handleRowSelection(embeddedRowButton:))))
        }
        
        if shouldShowApplePay {
            stackView.addArrangedSubview(EmbeddedRowButton(appearance: appearance,
                                                           rowButton: .makeForApplePay(appearance: appearance,
                                                                                       didTap: handleRowSelection(embeddedRowButton:))))
        }
        
        if shouldShowLink {
            stackView.addArrangedSubview(EmbeddedRowButton(appearance: appearance,
                                                           rowButton: .makeForLink(appearance: appearance,
                                                                                   didTap: handleRowSelection(embeddedRowButton:))))
        }
        
        // TODO(porter) Pass in some actual payment method types
        let types: [PaymentSheet.PaymentMethodType] = [.stripe(.bancontact), .stripe(.klarna), .stripe(.card)]
        for type in types {
            stackView.addArrangedSubview(EmbeddedRowButton(appearance: appearance,
                                                           rowButton: .makeForPaymentMethodType(paymentMethodType: type,
                                                                                                savedPaymentMethodType: savedPaymentMethod?.type,
                                                                                                appearance: appearance,
                                                                                                shouldAnimateOnPress: true,
                                                                                                didTap: handleRowSelection(embeddedRowButton:))))
        }
        
        if appearance.paymentOptionView.style != .floating {
            let defaultInsets: UIEdgeInsets = {
                switch appearance.paymentOptionView.style {
                case .flatRadio:
                    return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
                case .flatCheck:
                    return .zero
                case .floating:
                    return .zero
                }
            }()
            
            stackView.addSeparators(color: appearance.paymentOptionView.paymentMethodRow.flat.separatorColor ?? appearance.colors.componentBorder,
                                    thickness: appearance.paymentOptionView.paymentMethodRow.flat.separatorThickness,
                                    inset: appearance.paymentOptionView.paymentMethodRow.flat.separatorInset ?? defaultInsets,
                                    addTopSeparator: appearance.paymentOptionView.paymentMethodRow.flat.topSeparatorEnabled,
                                    addBottomSeparator: appearance.paymentOptionView.paymentMethodRow.flat.bottomSeparatorEnabled)
        }
        addAndPinSubview(stackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleRowSelection(embeddedRowButton: RowButton) {
        for case let rowButton as EmbeddedRowButton in stackView.arrangedSubviews {
            rowButton.isSelected = rowButton.rowButton === embeddedRowButton
        }
    }
}
