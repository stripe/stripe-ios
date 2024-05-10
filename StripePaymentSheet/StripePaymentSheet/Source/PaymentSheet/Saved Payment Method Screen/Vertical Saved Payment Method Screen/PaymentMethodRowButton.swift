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
    func didSelectButton(_ button: PaymentMethodRowButton)
    // TODO(porter) Add did delete and did update
}

final class PaymentMethodRowButton: UIView {

    struct ViewModel {
        let appearance: PaymentSheet.Appearance
        let text: String
        let image: UIImage
        // TODO(porter) Add can remove and can update
    }

    enum State {
        case selected
        case unselected
        case editing
    }

    // MARK: Internal properties
    var state: State = .unselected {
        didSet {
            previousState = oldValue

            switch state {
            case .selected:
                shadowRoundedRect.isSelected = true
                circleView.alpha = 1.0
            case .unselected:
                shadowRoundedRect.isSelected = false
                circleView.alpha = 0.0
            case .editing:
                shadowRoundedRect.isSelected = false
                circleView.alpha = 0.0
                // TODO(porter) show edit buttons (edit and delete)
            }
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

    var isEditing: Bool {
        switch state {
        case .selected, .unselected:
            return false
        case .editing:
            return true
        }
    }

    weak var delegate: PaymentMethodRowButtonDelegate?

    // MARK: Private properties
    private let viewModel: ViewModel

    // MARK: Private views

    private lazy var paymentMethodImageView: UIImageView = {
        let imageView = UIImageView(image: viewModel.image)
        imageView.contentMode = .scaleAspectFit
        // TODO(porter) Do we want to round the corners?
        return imageView
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = viewModel.text
        label.font = viewModel.appearance.scaledFont(for: viewModel.appearance.font.base.medium,
                                                     style: .callout,
                                                     maximumPointSize: 25)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var circleView: CheckmarkCircleView = {
        let circleView = CheckmarkCircleView(fillColor: viewModel.appearance.colors.primary)
        circleView.alpha = 0.0
        return circleView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [paymentMethodImageView, label, UIView.spacerView, circleView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.directionalLayoutMargins = .init(top: 12, // Hardcoded from figma
                                                   leading: PaymentSheetUI.defaultPadding,
                                                   bottom: 12,
                                                   trailing: PaymentSheetUI.defaultPadding)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.setCustomSpacing(12, after: paymentMethodImageView) // Hardcoded from figma
        return stackView
    }()

    private lazy var shadowRoundedRect: ShadowedRoundedRectangle = {
        let shadowRoundedRect = ShadowedRoundedRectangle(appearance: viewModel.appearance)
        shadowRoundedRect.translatesAutoresizingMaskIntoConstraints = false
        shadowRoundedRect.addAndPinSubview(stackView)
        return shadowRoundedRect
    }()

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)

        addAndPinSubview(shadowRoundedRect)
        NSLayoutConstraint.activate([
            paymentMethodImageView.heightAnchor.constraint(equalToConstant: 20), // Hardcoded from figma
            paymentMethodImageView.widthAnchor.constraint(equalToConstant: 25),
        ])
        // TODO(porter) accessibility?
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Tap handlers
    @objc private func handleTap() {
        // Ignore selection taps when editing
        guard !isEditing else { return }
        shadowRoundedRect.isSelected = true
        circleView.alpha = 1.0
        delegate?.didSelectButton(self)
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
