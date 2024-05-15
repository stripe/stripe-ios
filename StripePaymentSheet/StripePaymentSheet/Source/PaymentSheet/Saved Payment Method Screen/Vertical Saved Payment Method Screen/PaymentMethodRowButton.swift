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

    struct ViewModel {
        let appearance: PaymentSheet.Appearance
        let paymentMethod: STPPaymentMethod
    }

    enum State {
        case selected
        case unselected
        case editing(allowsRemoval: Bool, allowsUpdating: Bool)
    }

    // MARK: Internal properties
    var state: State = .unselected {
        didSet {
            previousState = oldValue

            selectionTapGesture.isEnabled = !isEditing
            shadowRoundedRect.isSelected = isSelected
            circleView.isHidden = !isSelected
            updateButton.isHidden = !canUpdate
            removeButton.isHidden = !canRemove
        }
    }

    private(set) var previousState: State = .unselected

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

    private lazy var paymentMethodImageView: UIImageView = {
        let imageView = UIImageView(image: paymentMethod.makeSavedPaymentMethodRowImage())
        imageView.contentMode = .scaleAspectFit
        // TODO(porter) Do we want to round the corners?
        return imageView
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = paymentMethod.paymentSheetLabel
        label.font = appearance.scaledFont(for: appearance.font.base.medium,
                                                     style: .callout,
                                                     maximumPointSize: 25)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    // TODO(porter) Refactor CircleIconView out of SavedPaymentMethodCollectionView once it is deleted
    private lazy var circleView: SavedPaymentMethodCollectionView.CircleIconView = {
        let circleView = SavedPaymentMethodCollectionView.CircleIconView(icon: .icon_checkmark,
                                                                         fillColor: appearance.colors.primary)
        circleView.isHidden = true
        return circleView
    }()

    private lazy var updateButton: CircularButton = {
        let updateButton = CircularButton(style: .edit, iconColor: .white)
        updateButton.backgroundColor = appearance.colors.icon
        updateButton.isHidden = true
        updateButton.addTarget(self, action: #selector(handleUpdateButtonTapped), for: .touchUpInside)
        return updateButton
    }()

    lazy var removeButton: CircularButton = {
        let removeButton = CircularButton(style: .remove, iconColor: .white)
        removeButton.backgroundColor = appearance.colors.danger
        removeButton.isHidden = true
        removeButton.addTarget(self, action: #selector(handleRemoveButtonTapped), for: .touchUpInside)
        return removeButton
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [paymentMethodImageView, label, UIView.spacerView, circleView, updateButton, removeButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.directionalLayoutMargins = .init(top: 12, // Hardcoded from figma
                                                   leading: PaymentSheetUI.defaultPadding,
                                                   bottom: 12,
                                                   trailing: PaymentSheetUI.defaultPadding)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = 12 // Hardcoded from figma
        return stackView
    }()

    private lazy var shadowRoundedRect: ShadowedRoundedRectangle = {
        let shadowRoundedRect = ShadowedRoundedRectangle(appearance: appearance)
        shadowRoundedRect.translatesAutoresizingMaskIntoConstraints = false
        shadowRoundedRect.addAndPinSubview(stackView)
        return shadowRoundedRect
    }()

    private lazy var selectionTapGesture: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(handleSelectionTap))
    }()

    init(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance) {
        self.paymentMethod = paymentMethod
        self.appearance = appearance
        super.init(frame: .zero)

        addAndPinSubview(shadowRoundedRect)
        NSLayoutConstraint.activate([
            paymentMethodImageView.heightAnchor.constraint(equalToConstant: 20), // Hardcoded from figma
            paymentMethodImageView.widthAnchor.constraint(equalToConstant: 25),
        ])
        // TODO(porter) accessibility?
        addGestureRecognizer(selectionTapGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Tap handlers
    @objc private func handleSelectionTap() {
        state = .selected
        delegate?.didSelectButton(self, with: paymentMethod)
    }

    @objc private func handleUpdateButtonTapped() {
        delegate?.didSelectUpdateButton(self, with: paymentMethod)
    }

    @objc private func handleRemoveButtonTapped() {
        delegate?.didSelectRemoveButton(self, with: paymentMethod)
    }

}

// MARK: Helper extensions
extension UIView {
    static var spacerView: UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        view.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return view
    }
}
