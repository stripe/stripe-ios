//
//  SavedPaymentMethodRowButton.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/9/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol SavedPaymentMethodRowButtonDelegate: AnyObject {
    func didSelectButton(_ button: SavedPaymentMethodRowButton, with paymentMethod: STPPaymentMethod)
    func didSelectUpdateButton(_ button: SavedPaymentMethodRowButton, with paymentMethod: STPPaymentMethod)
}

final class SavedPaymentMethodRowButton: UIView {

    enum State: Equatable {
        case selected
        case unselected
        case editing(allowsRemoval: Bool, allowsUpdating: Bool)
    }

    // MARK: Internal properties
    var state: State = .unselected {
        didSet {
            if oldValue == .selected || oldValue == .unselected {
                previousSelectedState = oldValue
            }

            rowButton.isSelected = isSelected
            chevronButton.isHidden = !canUpdate && !canRemove
        }
    }

    var previousSelectedState: State = .unselected

    var isSelected: Bool {
        switch state {
        case .selected:
            return true
        case .unselected, .editing:
            return false
        }
    }

    let showDefaultPMBadge: Bool

    private var isEditing: Bool {
        switch state {
        case .selected, .unselected:
            return false
        case .editing:
            return true
        }
    }

    private var canUpdate: Bool {
        switch state {
        case .selected, .unselected:
            return false
        case .editing(_, let allowsUpdating):
            return allowsUpdating
        }
    }

    private var canRemove: Bool {
        switch state {
        case .selected, .unselected:
            return false
        case .editing(let allowsRemoval, _):
            return allowsRemoval
        }
    }

    weak var delegate: SavedPaymentMethodRowButtonDelegate?

    // MARK: Internal/private properties
    let paymentMethod: STPPaymentMethod
    private let appearance: PaymentSheet.Appearance

    // MARK: Private views

    private lazy var chevronButton: RowButton.RightAccessoryButton = {
        let chevronButton = RowButton.RightAccessoryButton(accessoryType: .update, appearance: appearance, didTap: handleUpdateButtonTapped)
        chevronButton.isHidden = true
        chevronButton.isUserInteractionEnabled = isEditing
        return chevronButton
    }()

    private lazy var rowButton: RowButton = {
        let button: RowButton = .makeForSavedPaymentMethod(paymentMethod: paymentMethod, appearance: appearance, badgeText: badgeText, rightAccessoryView: chevronButton, didTap: handleRowButtonTapped)

        return button
    }()

    private lazy var badgeText: String? = {
        return showDefaultPMBadge ? String.Localized.default_text : nil
    }()

    init(paymentMethod: STPPaymentMethod,
         appearance: PaymentSheet.Appearance,
         showDefaultPMBadge: Bool = false) {
        self.paymentMethod = paymentMethod
        self.appearance = appearance
        self.showDefaultPMBadge = showDefaultPMBadge
        super.init(frame: .zero)

        addAndPinSubview(rowButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Tap handlers
    @objc private func handleUpdateButtonTapped() {
        delegate?.didSelectUpdateButton(self, with: paymentMethod)
    }

    @objc private func handleRowButtonTapped(_: RowButton) {
        if isEditing {
            delegate?.didSelectUpdateButton(self, with: paymentMethod)
        }
        else {
            state = .selected
            delegate?.didSelectButton(self, with: paymentMethod)
        }
    }
}
