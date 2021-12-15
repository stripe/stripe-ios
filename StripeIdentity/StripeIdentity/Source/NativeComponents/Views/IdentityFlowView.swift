//
//  IdentityFlowView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/28/21.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/**
 Container view with a scroll view used in `IdentityFlowViewController`
 */
class IdentityFlowView: UIView {

    struct Style {
        static let contentViewInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        static let buttonSpacing: CGFloat = 10
        static let buttonInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    }

    struct ViewModel {
        struct Button {
            let text: String
            let isEnabled: Bool
            let configuration: StripeUICore.Button.Configuration
            let didTap: () -> Void
        }

        let contentView: UIView
        let buttons: [Button]
    }

    private let scrollView = UIScrollView()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = Style.buttonSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = Style.buttonInsets
        return stackView
    }()

    private let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = Style.buttonInsets.top
        return stackView
    }()

    // MARK: Configured properties

    private var contentView: UIView?
    private var buttons: [Button] = []
    private var buttonTapActions: [() -> Void] = []

    // MARK: - Init

    init() {
        super.init(frame: .zero)

        backgroundColor = CompatibleColor.systemBackground

        installViews()
        installConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     Configures the view.

     - Note: This method changes the view hierarchy and activates new
     constraints which can affect screen render performance. It should only be
     called from a view controller's `init` or `viewDidLoad`.
     */
    func configure(with viewModel: ViewModel) {
        installContentView(viewModel.contentView)
        configureButtons(with: viewModel.buttons)
    }

    func adjustScrollViewForKeyboard(_ windowEndFrame: CGRect, isKeyboardHidden: Bool) {
        let endFrame = convert(windowEndFrame, from: window)

        // Adjust bottom inset to make space for keyboard
        let bottomInset = isKeyboardHidden ? 0 : (endFrame.height - frame.height + scrollView.frame.maxY)
        scrollView.contentInset.bottom = bottomInset
        scrollView.scrollIndicatorInsets.bottom = bottomInset
    }
}

// MARK: - Private Helpers

private extension IdentityFlowView {
    func configureButtons(with buttonViewModels: [ViewModel.Button]) {
        // If there are no buttons to display, hide the stack view
        guard buttonViewModels.count > 0 else {
            buttonStackView.isHidden = true
            return
        }
        buttonStackView.isHidden = false

        // Configure buttons and tapActions based from models after we ensure
        // there are the right number of buttons
        defer {
            // Configure buttons
            zip(buttonViewModels, buttons).forEach { (viewModel, button) in
                button.configure(with: viewModel)
            }

            // Cache tap actions
            buttonTapActions = buttonViewModels.map { $0.didTap }
        }

        // Only rebuild buttons if the number of buttons has changed
        guard buttonViewModels.count != buttons.count else {
            return
        }

        // Remove old buttons and create new ones and add them to the stack view
        buttons.forEach { $0.removeFromSuperview() }
        buttons = buttonViewModels.enumerated().map { index, _ in
            let button = Button(index: index, target: self, action: #selector(didTapButton(button:)))
            buttonStackView.addArrangedSubview(button)
            return button
        }
    }

    func installViews() {
        containerStackView.addArrangedSubview(scrollView)
        containerStackView.addArrangedSubview(buttonStackView)
        addAndPinSubview(containerStackView)
    }

    func installConstraints() {
        // Make scroll view's content full-width
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
        ])
    }

    func installContentView(_ contentView: UIView) {
        guard self.contentView !== contentView else {
            // Nothing to do if view hasn't changed
            return
        }

        self.contentView?.removeFromSuperview()
        self.contentView = contentView
        scrollView.addSubview(contentView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // Pin contentView to scrollView's contentLayoutGuide
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -Style.contentViewInsets.top),
            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -Style.contentViewInsets.leading),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: Style.contentViewInsets.trailing),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: Style.contentViewInsets.bottom),
        ])
    }

    @objc func didTapButton(button: Button) {
        buttonTapActions.stp_boundSafeObject(at: button.index)?()
    }
}

extension IdentityFlowView.ViewModel {
    init(contentView: UIView,
         buttonText: String,
         isButtonEnabled: Bool = true,
         didTapButton: @escaping () -> Void) {
        self.init(
            contentView: contentView,
            buttons: [.init(
                text: buttonText,
                isEnabled: isButtonEnabled,
                configuration: .primary(),
                didTap: didTapButton
            )]
        )
    }
}

fileprivate extension StripeUICore.Button {
    convenience init(
        index: Int,
        target: Any?,
        action: Selector
    ) {
        self.init()
        self.tag = index
        addTarget(target, action: action, for: .touchUpInside)
    }

    var index: Int {
        return tag
    }

    func configure(with viewModel: IdentityFlowView.ViewModel.Button) {
        self.title = viewModel.text
        self.configuration = viewModel.configuration
        self.isEnabled = viewModel.isEnabled
    }
}
