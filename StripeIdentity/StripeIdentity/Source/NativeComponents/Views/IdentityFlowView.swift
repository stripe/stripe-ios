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
            top: 4,
            leading: 16,
            bottom: 8,
            trailing: 16
        )
        static let buttontopInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 0,
            bottom: -8,
            trailing: 0
        )
        static let stackViewSpacing: CGFloat = 8

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

            enum Kind {
                case standard(text: String, isPrimary: Bool)
                case custom(makeControl: () -> UIControl)
            }

            let kind: Kind
            let state: State
            let didTap: () -> Void

            var text: String? {
                guard case let .standard(text, _) = kind else {
                    return nil
                }
                return text
            }

            var isPrimary: Bool {
                guard case let .standard(_, isPrimary) = kind else {
                    return false
                }
                return isPrimary
            }

            init(
                text: String,
                state: State = .enabled,
                isPrimary: Bool = true,
                didTap: @escaping () -> Void
            ) {
                self.kind = .standard(text: text, isPrimary: isPrimary)
                self.state = state
                self.didTap = didTap
            }

            init(
                makeControl: @escaping () -> UIControl,
                state: State = .enabled,
                didTap: @escaping () -> Void
            ) {
                self.kind = .custom(makeControl: makeControl)
                self.state = state
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
        var buttonTopContentViewModel: HTMLTextView.ViewModel?
        var scrollViewDelegate: UIScrollViewDelegate?
        var flowViewDelegate: IdentityFlowViewDelegate?
    }

    private let headerView = HeaderView()
    private let insetContentView = UIView()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .none
        return scrollView
    }()

    private let scrollContainerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Style.stackViewSpacing
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
        // systemBackground might be different in dark/light mode
        buttonBackgroundView.backgroundColor = .systemBackground
        return buttonBackgroundView
    }()

    private let buttonTopBackgroundView: UIView = {
        let buttonTopBackgroundView = UIView()
        // systemBackground might be different in dark/light mode
        buttonTopBackgroundView.backgroundColor = .systemBackground
        return buttonTopBackgroundView
    }()

    private let buttonTopContentView = HTMLTextView()

    private var flowViewDelegate: IdentityFlowViewDelegate?

    // MARK: Configured properties
    private var contentViewModel: ContentViewModel?
    private var buttons: [UIControl] = []
    private var buttonTapActions: [() -> Void] = []
    private var buttonKinds: [ViewModel.Button.Kind.ReuseIdentifier] = []
    private var initialScrollViewBottomInsect: CGFloat = 0

    // MARK: - Init

    init() {
        super.init(frame: .zero)

        backgroundColor = .systemBackground

        setUpScollView()
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
    func configure(with viewModel: ViewModel) throws {
        configureHeaderView(with: viewModel.headerViewModel)
        configureContentView(with: viewModel.contentViewModel)
        configureButtons(with: viewModel.buttons)
        try configureButtonTop(with: viewModel.buttonTopContentViewModel)
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
        let bottomInset = buttonBackgroundView.frame.height + Style.buttonSpacing + buttonTopBackgroundView.frame.height

        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        scrollView.contentInset.bottom = bottomInset

        if scrollView.contentSize.height > 0 {
            flowViewDelegate?.scrollViewFullyLaiedOut(scrollView)
        }

        initialScrollViewBottomInsect = scrollView.contentInset.bottom
    }
}

// MARK: - UIGestureRecognizerDelegate
extension IdentityFlowView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Allow the tap gesture recognizer to recognize the tap
        // only if the touch is outside the subviews of the scrollView
        if let touchedView = touch.view, touchedView === scrollView {
            return true
        }
        return false
    }
}

// MARK: - Private Helpers

extension IdentityFlowView {
    fileprivate func setUpScollView() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.delegate = self
        scrollView.addGestureRecognizer(tapGesture)
    }

    @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        // Dismiss the keyboard when the scrollView is tapped
        scrollView.endEditing(true)
    }

    fileprivate func installViews() {
        // Install scroll subviews: header + content
        scrollContainerStackView.addArrangedSubview(headerView)
        scrollContainerStackView.addArrangedSubview(insetContentView)
        scrollView.addAndPinSubview(scrollContainerStackView)

        // Arrange container stack view: scroll + button
        addAndPinSubview(scrollView)
        addSubview(buttonTopBackgroundView)
        buttonTopBackgroundView.addSubview(buttonTopContentView)

        addSubview(buttonBackgroundView)
        buttonBackgroundView.addAndPinSubviewToSafeArea(
            buttonStackView,
            insets: Style.buttonInsets
        )
    }

    fileprivate func installConstraints() {
        buttonBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        buttonTopBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        buttonTopContentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Constrain buttonTop top of buttons
            buttonTopBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonTopBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonTopBackgroundView.bottomAnchor.constraint(equalTo: buttonBackgroundView.topAnchor),

            buttonTopContentView.centerXAnchor.constraint(equalTo: buttonTopBackgroundView.centerXAnchor),
            // Limit width without pinning
            buttonTopContentView.widthAnchor.constraint(lessThanOrEqualTo: buttonTopBackgroundView.widthAnchor, constant: -(Style.buttonInsets.leading + Style.buttonInsets.trailing)),
            buttonTopContentView.topAnchor.constraint(equalTo: buttonTopBackgroundView.topAnchor, constant: Style.buttontopInsets.top),
            buttonTopContentView.bottomAnchor.constraint(equalTo: buttonTopBackgroundView.bottomAnchor, constant: Style.buttontopInsets.bottom),

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

    @objc fileprivate func didTapButton(button: UIControl) {
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
                if let stripeButton = button as? StripeUICore.Button {
                    stripeButton.configureStripeButton(with: viewModel)
                } else {
                    button.configureControl(with: viewModel)
                }
            }

            // Cache tap actions
            buttonTapActions = buttonViewModels.map { $0.didTap }
        }

        let newButtonKinds = buttonViewModels.map { $0.kind.reuseIdentifier }

        // Only rebuild buttons if the number or kind of buttons has changed
        guard buttonViewModels.count != buttons.count || newButtonKinds != buttonKinds else {
            return
        }

        // Remove old buttons and create new ones and add them to the stack view
        buttons.forEach { $0.removeFromSuperview() }
        buttons = buttonViewModels.indices.map { index in
            let button = buttonViewModels[index].makeControl()
            button.index = index
            button.addTarget(self, action: #selector(didTapButton(button:)), for: .touchUpInside)
            buttonStackView.addArrangedSubview(button)
            return button
        }
        buttonKinds = newButtonKinds
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

    fileprivate func configureButtonTop(with viewModel: HTMLTextView.ViewModel?) throws {
        buttonTopContentView.isHidden = true
        if let viewModel = viewModel {
            do {
                try buttonTopContentView.configure(with: viewModel)
                buttonTopContentView.isHidden = false
            } catch {
                throw error
            }
        }
    }

    static func privacyPolicyLineContentStyle() -> HTMLStyle {
        let boldFont = IdentityUI.preferredFont(forTextStyle: UIFont.TextStyle.caption1, weight: .bold)
        let contentColor = IdentityUI.htmlLineTextColor
        return .init(
            bodyFont: IdentityUI.preferredFont(forTextStyle: UIFont.TextStyle.caption1),
            bodyColor: contentColor,
            h1Font: boldFont,
            h2Font: boldFont,
            h3Font: boldFont,
            h4Font: boldFont,
            h5Font: boldFont,
            h6Font: boldFont,
            isLinkUnderlined: true,
            shouldCenterText: false,
            linkColor: contentColor
        )
    }
}

extension IdentityFlowView.ViewModel {
    init(
        headerViewModel: HeaderView.ViewModel?,
        contentView: UIView,
        buttonText: String,
        state: Button.State = .enabled,
        buttonTopContentViewModel: HTMLTextView.ViewModel? = nil,
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
            ],
            buttonTopContentViewModel: buttonTopContentViewModel
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

    fileprivate func makeControl() -> UIControl {
        switch kind {
        case .standard:
            return Button()
        case let .custom(makeControl):
            return makeControl()
        }
    }
}

extension IdentityFlowView.ViewModel.Button.Kind {
    fileprivate enum ReuseIdentifier: Equatable {
        case standard
        case custom
    }

    fileprivate var reuseIdentifier: ReuseIdentifier {
        switch self {
        case .standard:
            return .standard
        case .custom:
            return .custom
        }
    }
}

extension UIControl {
    fileprivate var index: Int {
        get {
            return tag
        }
        set {
            tag = newValue
        }
    }

    fileprivate func configureControl(with viewModel: IdentityFlowView.ViewModel.Button) {
        isEnabled = viewModel.state == .enabled
    }
}

extension StripeUICore.Button {
    fileprivate func configureStripeButton(with viewModel: IdentityFlowView.ViewModel.Button) {
        guard case let .standard(text, isPrimary) = viewModel.kind else {
            return
        }
        title = text
        configuration = IdentityFlowView.Style.buttonConfiguration(
            isPrimary: isPrimary
        )
        isEnabled = viewModel.state == .enabled
        isLoading = viewModel.state == .loading
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
