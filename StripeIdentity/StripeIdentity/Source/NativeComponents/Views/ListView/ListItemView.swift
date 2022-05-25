//
//  ListItemView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/11/22.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/**
 A row inside of a `ListView`
 */
final class ListItemView: UIView {
    typealias Styling = ListView.Styling

    struct ViewModel {
        enum Accessory {
            case button(title: String, onTap: () -> Void)
            case activityIndicator
            case icon(UIImage)
        }

        let text: String
        let accessibilityLabel: String?
        let accessory: Accessory?
        let onTap: (() -> Void)?
    }

    // MARK: - Properties

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = Styling.itemAccessibilitySpacing
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        return stackView
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.font = Styling.font
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let activityIndicator: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .medium)
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        return imageView
    }()

    // MARK: Button

    private lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = Styling.font
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        return button
    }()

    /*
     UIButtons are taller than UILabels because they add additional padding
     around the text to increase the tap target. However, we want the button to
     visually align with the label and maintain consistent padding around the
     stackView.

     This view will be added to the stackView instead of the button and
     constrained to the button's width so that we achieve visual alignment with
     consistent padding and maintain the button's intrinsic height to ensure a
     the tap target is big enough.
     */
    private let buttonSpacer = UIView()

    private var buttonIsHidden: Bool {
        get {
            return button.isHidden
        }
        set {
            button.isHidden = newValue
            buttonSpacer.isHidden = newValue
        }
    }

    private var buttonTapHandler: (() -> Void)?

    // MARK: - TapHandler

    private var itemTapHandler: (() -> Void)?

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        setupViews()
        installConstraints()
        setupTapGesture()

        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(with viewModel: ViewModel) {
        // Label
        label.text = viewModel.text

        // Tap Handler
        self.itemTapHandler = viewModel.onTap

        // Accessory
        configureAccessory(with: viewModel.accessory)

        // Accessibility
        if itemTapHandler != nil {
            accessibilityTraits = .button
        } else {
            if case .button = viewModel.accessory {
                accessibilityTraits = .button
            } else {
                accessibilityTraits = .none
            }
        }
        self.accessibilityLabel = viewModel.accessibilityLabel ?? viewModel.text
    }

    func configureAccessory(with accessoryViewModel: ViewModel.Accessory?) {
        // Hide old accessory views
        buttonIsHidden = true
        activityIndicator.stopAnimating()
        iconView.isHidden = true

        // Reset button tap handler
        buttonTapHandler = nil

        // Configure the new accessory
        switch accessoryViewModel {
        case .button(let title, let tapHandler):
            assert(itemTapHandler == nil, "ListItemView should not be configured with both a button and a tap action or button will be inaccessible to accessibility to VoiceOver")

            buttonIsHidden = false
            buttonTapHandler = tapHandler
            button.setTitle(title, for: .normal)

        case .activityIndicator:
            activityIndicator.startAnimating()

        case .icon(let image):
            iconView.isHidden = false
            iconView.image = image

        case .none:
            break
        }

        // Notify the accessibility VoiceOver that layout has changed
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }

    // MARK: - Overrides

    override func accessibilityActivate() -> Bool {
        // If user activates item with accessibility VoiceOver, use either the
        // item or button's tap handler, depending on configuration

        if let itemTapHandler = itemTapHandler {
            itemTapHandler()
            return true
        }

        if let buttonTapHandler = buttonTapHandler {
            buttonTapHandler()
            return true
        }

        return false
    }

    // MARK: - Private

    private func setupViews() {
        addAndPinSubview(stackView, insets: Styling.itemInsets)
        addSubview(button)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(buttonSpacer)
        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(iconView)
    }

    private func installConstraints() {
        button.setContentHuggingPriority(.required, for: .horizontal)
        activityIndicator.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        button.translatesAutoresizingMaskIntoConstraints = false

        // Constrain button and buttonSpacer to be centered with same width
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalTo: buttonSpacer.widthAnchor),
            button.centerYAnchor.constraint(equalTo: buttonSpacer.centerYAnchor),
            button.centerXAnchor.constraint(equalTo: buttonSpacer.centerXAnchor),
        ])
    }

    private func setupTapGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapItem))
        addGestureRecognizer(gesture)
    }

    @objc private func didTapItem() {
        itemTapHandler?()
    }

    @objc private func didTapButton() {
        buttonTapHandler?()
    }
}
