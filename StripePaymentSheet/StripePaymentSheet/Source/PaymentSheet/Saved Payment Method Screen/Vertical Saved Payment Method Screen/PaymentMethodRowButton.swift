//
//  PaymentMethodRowButton.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/9/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol PaymentMethodRowButtonDelegate: AnyObject {
    func didSelectButton(_ button: PaymentMethodRowButton, with paymentMethod: STPPaymentMethod)
    func didSelectRemoveButton(_ button: PaymentMethodRowButton, with paymentMethod: STPPaymentMethod)
    func didSelectUpdateButton(_ button: PaymentMethodRowButton, with paymentMethod: STPPaymentMethod)
}

final class PaymentMethodRowButton: UIView {

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
            rowButton.isEnabled = !isEditing
            circleView.isHidden = !isSelected
            updateButton.isHidden = !canUpdate
            removeButton.isHidden = !canRemove
            stackView.isUserInteractionEnabled = isEditing
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

    weak var delegate: PaymentMethodRowButtonDelegate?

    // MARK: Internal/private properties
    let paymentMethod: STPPaymentMethod
    private let appearance: PaymentSheet.Appearance

    // MARK: Private views

    // TODO(porter) Refactor CircleIconView out of SavedPaymentMethodCollectionView once it is deleted
    private lazy var circleView: SavedPaymentMethodCollectionView.CircleIconView = {
        let circleView = SavedPaymentMethodCollectionView.CircleIconView(icon: .icon_checkmark,
                                                                         fillColor: appearance.colors.primary)
        circleView.isHidden = true
        return circleView
    }()

    private lazy var removeButton: CircularButton = {
        let removeButton = CircularButton(style: .remove, iconColor: .white)
        removeButton.backgroundColor = appearance.colors.danger
        removeButton.isHidden = true
        removeButton.addTarget(self, action: #selector(handleRemoveButtonTapped), for: .touchUpInside)
        return removeButton
    }()

    private lazy var updateButton: CircularButton = {
        let updateButton = CircularButton(style: .edit, iconColor: .white)
        updateButton.backgroundColor = appearance.colors.icon
        updateButton.isHidden = true
        updateButton.addTarget(self, action: #selector(handleUpdateButtonTapped), for: .touchUpInside)
        return updateButton
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView.makeRowButtonContentStackView(arrangedSubviews: [circleView, updateButton, removeButton])
        // margins handled by the `RowButton`
        stackView.directionalLayoutMargins = .zero
        stackView.isUserInteractionEnabled = isEditing
        return stackView
    }()

    private lazy var rowButton: RowButton = {
        let button: RowButton = .makeForSavedPaymentMethod(paymentMethod: paymentMethod, appearance: appearance, rightAccessoryView: stackView) { [weak self] _ in
            guard let self else { return }
            state = .selected
            delegate?.didSelectButton(self, with: paymentMethod)
        }

        return button
    }()

    init(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance) {
        self.paymentMethod = paymentMethod
        self.appearance = appearance
        super.init(frame: .zero)

        addAndPinSubview(rowButton)
        // TODO(porter) accessibility?
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Tap handlers
    @objc private func handleUpdateButtonTapped() {
        delegate?.didSelectUpdateButton(self, with: paymentMethod)
    }

    @objc private func handleRemoveButtonTapped() {
        delegate?.didSelectRemoveButton(self, with: paymentMethod)
    }

}
