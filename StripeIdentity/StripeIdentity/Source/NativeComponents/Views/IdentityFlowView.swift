//
//  IdentityFlowView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/28/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol IdentityFlowViewDelegate: AnyObject {
    func scrollViewFullyLaiedOut(_ scrollView: UIScrollView)
}

// swift-format-ignore: DontRepeatTypeInStaticProperties
/// Container view with a scroll view used in `IdentityFlowViewController`
class IdentityFlowView: UIView {
    typealias ContentViewModel = ViewModel.Content

    struct Style {
        static let defaultContentViewInsets = NSDirectionalEdgeInsets(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        static let buttonSpacing: CGFloat = 10
        static let buttonInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 16,
            bottom: 8,
            trailing: 16
        )

        static func buttonConfiguration(isPrimary: Bool) -> Button.Configuration {
            return isPrimary ? .identityPrimary() : .identitySecondary()
        }
    }

    struct ViewModel {
        struct Button {
            enum State {
                case enabled
                case disabled
                case loading
            }

            let text: String
            let state: State
            let isPrimary: Bool
            let didTap: () -> Void

            init(
                text: String,
                state: State = .enabled,
                isPrimary: Bool = true,
                didTap: @escaping () -> Void
            ) {
                self.text = text
                self.state = state
                self.isPrimary = isPrimary
                self.didTap = didTap
            }
        }

        struct Content: Equatable {
            let view: UIView
            let inset: NSDirectionalEdgeInsets?
        }

        let headerViewModel: HeaderView.ViewModel?
        let contentViewModel: Content
        let buttons: [Button]
        var scrollViewDelegate: UIScrollViewDelegate?
        var flowViewDelegate: IdentityFlowViewDelegate?
    }

    private let headerView = HeaderView()
    private let insetContentView = UIView()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .onDrag
        return scrollView
    }()

    private let scrollContainerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = Style.buttonSpacing
        return stackView
    }()

    private let buttonBackgroundView: UIView = {
        let buttonBackgroundView = UIView()
        buttonBackgroundView.backgroundColor = .systemBackground
        return buttonBackgroundView
    }()

    private var flowViewDelegate: IdentityFlowViewDelegate?

    // MARK: Configured properties
    private var contentViewModel: ContentViewModel?
    private var buttons: [Button] = []
    private var buttonTapActions: [() -> Void] = []
    private var initialScrollViewBottomInsect: CGFloat = 0

    // MARK: - Init

    init() {
        super.init(frame: .zero)

        backgroundColor = .systemBackground

        installViews()
        installConstraints()
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Configures the view.
    ///
    /// - Note: This method changes the view hierarchy and activates new
    /// constraints which can affect screen render performance. It should only be
    /// called from a view controller's `init` or `viewDidLoad`.
    func configure(with viewModel: ViewModel) {
        configureHeaderView(with: viewModel.headerViewModel)
        configureContentView(with: viewModel.contentViewModel)
        configureButtons(with: viewModel.buttons)
        flowViewDelegate = viewModel.flowViewDelegate
        if let scrollViewDelegate = viewModel.scrollViewDelegate {
            scrollView.delegate = scrollViewDelegate
        }
    }

    func adjustScrollViewForKeyboard(_ windowEndFrame: CGRect, isKeyboardHidden: Bool) {
        let endFrame = convert(windowEndFrame, from: window)

        // Adjust bottom inset to make space for keyboard
        let bottomInset =
            isKeyboardHidden ? initialScrollViewBottomInsect : (endFrame.height - frame.height + scrollView.frame.maxY)
        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        scrollView.horizontalScrollIndicatorInsets.bottom = bottomInset
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Update the scrollView's inset based on the height of the button
        // container so that the content displays above the container plus
        // buttonSpacing when scrolled all the way to the bottom
        let bottomInset = buttonBackgroundView.frame.height + Style.buttonSpacing
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        scrollView.contentInset.bottom = bottomInset

        if scrollView.contentSize.height > 0 {
            flowViewDelegate?.scrollViewFullyLaiedOut(scrollView)
        }

        initialScrollViewBottomInsect = scrollView.contentInset.bottom
    }
}

// MARK: - Private Helpers

extension IdentityFlowView {
    fileprivate func installViews() {
        // Install scroll subviews: header + content
        scrollContainerStackView.addArrangedSubview(headerView)
        scrollContainerStackView.addArrangedSubview(insetContentView)
        scrollView.addAndPinSubview(scrollContainerStackView)

        // Arrange container stack view: scroll + button
        addAndPinSubview(scrollView)
        addSubview(buttonBackgroundView)
        buttonBackgroundView.addAndPinSubviewToSafeArea(
            buttonStackView,
            insets: Style.buttonInsets
        )
    }

    fileprivate func installConstraints() {
        buttonBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Constrain buttons to bottom
            buttonBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Make scroll view's content full-width
            scrollView.contentLayoutGuide.leadingAnchor.constraint(
                equalTo: scrollView.leadingAnchor
            ),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(
                equalTo: scrollView.trailingAnchor
            ),
        ])
    }

    @objc fileprivate func didTapButton(button: Button) {
        buttonTapActions.stp_boundSafeObject(at: button.index)?()
    }
}

// MARK: - Private Helpers: View Configurations

extension IdentityFlowView {
    fileprivate func configureButtons(with buttonViewModels: [ViewModel.Button]) {
        // If there are no buttons to display, hide the container view
        guard buttonViewModels.count > 0 else {
            buttonBackgroundView.isHidden = true
            return
        }
        buttonBackgroundView.isHidden = false

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
            let button = Button(
                index: index,
                target: self,
                action: #selector(didTapButton(button:))
            )
            buttonStackView.addArrangedSubview(button)
            return button
        }
    }

    fileprivate func configureContentView(with contentViewModel: ContentViewModel) {
        guard self.contentViewModel != contentViewModel else {
            // Nothing to do if view hasn't changed
            return
        }

        self.contentViewModel?.view.removeFromSuperview()
        self.contentViewModel = contentViewModel

        insetContentView.addAndPinSubview(
            contentViewModel.view,
            insets: contentViewModel.inset ?? Style.defaultContentViewInsets
        )
    }

    fileprivate func configureHeaderView(with viewModel: HeaderView.ViewModel?) {
        if let headerViewModel = viewModel {
            headerView.configure(with: headerViewModel)
            headerView.isHidden = false
        } else {
            headerView.isHidden = true
        }
    }
}

extension IdentityFlowView.ViewModel {
    init(
        headerViewModel: HeaderView.ViewModel?,
        contentView: UIView,
        buttonText: String,
        state: Button.State = .enabled,
        didTapButton: @escaping () -> Void
    ) {
        self.init(
            headerViewModel: headerViewModel,
            contentViewModel: .init(view: contentView, inset: nil),
            buttons: [
                .init(
                    text: buttonText,
                    state: state,
                    isPrimary: true,
                    didTap: didTapButton
                ),
            ]
        )
    }

    init(
        headerViewModel: HeaderView.ViewModel?,
        contentView: UIView,
        buttons: [Button]
    ) {
        self.init(
            headerViewModel: headerViewModel,
            contentViewModel: .init(view: contentView, inset: nil),
            buttons: buttons
        )
    }
}

extension IdentityFlowView.ViewModel.Button {
    static func continueButton(
        state: State = .enabled,
        didTap: @escaping () -> Void
    ) -> Self {
        return .init(
            text: String.Localized.continue,
            state: state,
            isPrimary: true,
            didTap: didTap
        )
    }
}

extension StripeUICore.Button {
    fileprivate convenience init(
        index: Int,
        target: Any?,
        action: Selector
    ) {
        self.init()
        self.tag = index
        addTarget(target, action: action, for: .touchUpInside)
    }

    fileprivate var index: Int {
        return tag
    }

    fileprivate func configure(with viewModel: IdentityFlowView.ViewModel.Button) {
        self.title = viewModel.text
        self.configuration = IdentityFlowView.Style.buttonConfiguration(
            isPrimary: viewModel.isPrimary
        )
        self.isEnabled = viewModel.state == .enabled
        self.isLoading = viewModel.state == .loading
    }
}

// MARK: - Button.Configuration
extension Button.Configuration {

    static var buttonFont: UIFont {
        return IdentityUI.preferredFont(forTextStyle: .body, weight: .medium)
    }

    /// The default button configuration.
    static func identityPrimary() -> Self {
        var configuration: Button.Configuration = .primary()
        configuration.font = buttonFont
        configuration.disabledForegroundColor = .systemGray
        return configuration
    }

    /// A less prominent button.
    static func identitySecondary() -> Self {
        var configuration: Button.Configuration = .secondary()
        configuration.font = buttonFont
        return configuration
    }
}
