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

    enum State {
        case selected
        case unselected
        case editing(allowsRemoval: Bool, allowsUpdating: Bool)
    }

    // MARK: Internal properties
    var state: State = .unselected {
        didSet {
            previousState = oldValue
            
            rowButton.gestureRecognizers?.forEach {$0.isEnabled = !isEditing}
            rowButton.isSelected = isSelected
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
    
    // todo reuse
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [UIView.spacerView, circleView, updateButton, removeButton])
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
    
    private lazy var rowButton: RowButton = {
        let button: RowButton = .makeForSavedPaymentMethod(paymentMethod: paymentMethod, appearance: appearance) { [weak self] _ in
            guard let self, !isEditing else { return }
            state = .selected
            delegate?.didSelectButton(self, with: paymentMethod)
        }
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAndPinSubview(stackView)
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

// MARK: Helper extensions
// TODO(porter) Remove
extension UIView {
    static var spacerView: UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        view.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return view
    }
}

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

class RowButton: UIView {
    private let shadowRoundedRect: ShadowedRoundedRectangle
    let didTap: (RowButton) -> Void
    var isSelected: Bool = false {
        didSet {
            shadowRoundedRect.isSelected = isSelected
        }
    }

    static func makeForPaymentMethodType(paymentMethodType: PaymentSheet.PaymentMethodType, appearance: PaymentSheet.Appearance, didTap: @escaping (RowButton) -> Void) -> RowButton {
        let imageView = PaymentMethodTypeImageView(paymentMethodType: paymentMethodType, backgroundColor: appearance.colors.componentBackground)
        imageView.contentMode = .scaleAspectFit
        let subtext: String? = {
            switch paymentMethodType {
            case .stripe(.klarna):
                return ""
            default:
                // TODO: Add Afterpay
                return nil
            }
        }()
        return RowButton(appearance: appearance, imageView: imageView, text: paymentMethodType.displayName, subtext: subtext, didTap: didTap)
    }

    static func makeForSavedPaymentMethod(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance, didTap: @escaping (RowButton) -> Void) -> RowButton {
        let imageView = UIImageView(image: paymentMethod.makeSavedPaymentMethodRowImage())
        imageView.contentMode = .scaleAspectFit
        return RowButton(appearance: appearance, imageView: imageView, text: paymentMethod.paymentSheetLabel, didTap: didTap)
    }


    init(appearance: PaymentSheet.Appearance, imageView: UIImageView, text: String, subtext: String? = nil, rightAccessoryView: UIView? = nil, didTap: @escaping (RowButton) -> Void) {
        self.didTap = didTap
        self.shadowRoundedRect = ShadowedRoundedRectangle(appearance: appearance)
        super.init(frame: .zero)

        // Label and sublabel
        let labelsStackView = UIStackView(arrangedSubviews: [
            UILabel.makeVerticalRowButtonLabel(text: text, appearance: appearance),
        ])
        if let subtext {
            let sublabel = UILabel()
            sublabel.font = appearance.scaledFont(for: appearance.font.base.regular, style: .caption1, maximumPointSize: 20)
            sublabel.adjustsFontForContentSizeCategory = true
            sublabel.text = subtext
            sublabel.textColor = appearance.colors.componentPlaceholderText
            labelsStackView.addArrangedSubview(sublabel)
        }
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading

        // TODO: Accessory view

        addAndPinSubview(shadowRoundedRect)
        for view in [imageView, labelsStackView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 12),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12),
            imageView.heightAnchor.constraint(equalToConstant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 24),

            labelsStackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            labelsStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelsStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 4),
            labelsStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -4),
        ])
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        didTap(self)
    }
}

class PaymentMethodTypeImageView: UIImageView {
    let paymentMethodType: PaymentSheet.PaymentMethodType
    var resolvedBackgroundColor: UIColor? {
        return backgroundColor?.resolvedColor(with: traitCollection)
    }

    init(paymentMethodType: PaymentSheet.PaymentMethodType, backgroundColor: UIColor) {
        self.paymentMethodType = paymentMethodType
        super.init(image: nil)
        self.backgroundColor = backgroundColor
        self.contentMode = .scaleAspectFit
        updateImage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

#if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateImage()
    }
#endif

    func updateImage() {
        // Unfortunately the DownloadManager API returns either a placeholder image _or_ the actual image
        // Set the image now...
        let image = paymentMethodType.makeImage(forDarkBackground: resolvedBackgroundColor?.contrastingColor == .white) { [weak self] image in
            DispatchQueue.main.async {
                // ...and set it again if the callback is called with a downloaded image
                self?.setImage(image)
            }
        }
        setImage(image)
    }

    func setImage(_ image: UIImage) {
        if self.paymentMethodType.iconRequiresTinting  {
            self.image = image.withRenderingMode(.alwaysTemplate)
            tintColor = resolvedBackgroundColor?.contrastingColor
        } else {
            self.image = image
            tintColor = nil
        }
    }
}
extension UILabel {
    static func makeVerticalRowButtonLabel(text: String, appearance: PaymentSheet.Appearance) -> UILabel {
        let label = UILabel()
        label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .subheadline, maximumPointSize: 25)
        label.adjustsFontForContentSizeCategory = true
        label.text = text
        label.textColor = appearance.colors.componentText
        return label
    }
}
