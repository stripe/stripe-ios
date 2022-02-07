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
            case icon(UIImage, tintColor: UIColor?)
        }

        let text: String
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
        label.font = Styling.itemFont
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    // TODO(IDPROD-3056): Use ActivityIndicator component
    private let activityIndicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .medium)
        } else {
            return UIActivityIndicatorView(style: .gray)
        }
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()

    // MARK: Button

    private let button: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = Styling.itemButtonFont
        button.setTitleColor(Styling.itemButtonTintColor, for: .normal)
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

    private var buttonTapHandler: () -> Void = {}

    // MARK: - TapHandler

    private var itemTapHandler: (() -> Void)?

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        setupViews()
        installConstraints()
        setupTapGesture()
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
        if itemTapHandler != nil {
            isAccessibilityElement = true
            accessibilityTraits = .button
            accessibilityLabel = viewModel.text
        } else {
            isAccessibilityElement = false
            accessibilityTraits = .none
            accessibilityLabel = nil
        }

        // Accessory

        buttonIsHidden = true
        activityIndicator.stp_stopAnimatingAndHide()
        iconView.isHidden = true

        switch viewModel.accessory {
        case .button(let title, let tapHandler):
            buttonIsHidden = false
            buttonTapHandler = tapHandler
            button.setTitle(title, for: .normal)

        case .activityIndicator:
            activityIndicator.stp_startAnimatingAndShow()

        case .icon(let image, let tintColor):
            iconView.isHidden = false
            iconView.image = image
            iconView.tintColor = tintColor

        case .none:
            break
        }
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
        buttonTapHandler()
    }
}
