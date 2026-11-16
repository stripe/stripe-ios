//
//  EmbeddedLinkInlineVerificationView.swift
//  StripePaymentSheet
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

/// The Link row expanded so a returning customer can enter the code they were sent.
///
/// It only renders `State`. The verification attempt belongs to whoever creates the view, so a rebuilt list can show
/// the same attempt in a new view.
@MainActor
final class EmbeddedLinkInlineVerificationView: UIView {
    struct State: Equatable {
        enum Actions: Equatable {
            case none
            case resend(title: String, isEnabled: Bool)
            /// More than one action, behind a "More options" menu.
            case menu(items: [MenuItem], isEnabled: Bool)
        }

        struct MenuItem: Equatable {
            let action: LinkAuthFlowCoordinator.Action
            let title: String
            let systemImageName: String
            let isEnabled: Bool
        }

        var email: String
        var recipient: String
        var isCodeEntryEnabled: Bool
        var errorMessage: String?
        var actions: Actions
        var isActionLoading: Bool
        /// Changes when the code field should be cleared, e.g. after a new code is sent.
        var inputRevision: Int
        /// Changes when a submitted code was rejected.
        var invalidCodeRevision: Int
    }

    var onTapCode: (() -> Void)?
    var onClose: (() -> Void)?
    var onSwitchAccount: (() -> Void)?
    var onAction: ((LinkAuthFlowCoordinator.Action) -> Void)?
    var onCodeChanged: ((String) -> Void)?
    var onCodeEntered: ((String) -> Void)?
    /// The code field stopped being first responder, e.g. after Done, or because the host ended editing or removed the view.
    var onCodeEditingEnded: (() -> Void)?

    /// The part that has to stay visible while the customer types the code.
    let focusRegion = UIStackView()
    let codeField: OneTimeCodeTextField

    private let appearance: PaymentSheet.Appearance
    private let isFloating: Bool
    private let emailButton = ChevronMenuButton()
    private lazy var closeButton = CircularButton(style: .close, iconColor: appearance.colors.icon)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    /// Takes taps on the code field so the field never focuses itself; the owner decides where the code is entered.
    private let codeTapTarget = UIControl()
    private lazy var errorLabel = ElementsUI.makeErrorLabel(theme: appearance.asElementsTheme)
    private lazy var actionsButton: Button = {
        var configuration: Button.Configuration = .plain()
        configuration.font = appearance.scaledFont(for: appearance.font.base.medium, style: .subheadline, maximumPointSize: 25)
        configuration.foregroundColor = appearance.colors.text
        return Button(configuration: configuration, title: nil)
    }()
    /// Shows the actions menu on iOS 14+, layered over `actionsButton`.
    private let actionsMenuButton = UIButton(type: .system)
    /// The number pad has no return key, so this gives it a way to close.
    private lazy var doneToolbar = DoneButtonToolbar(delegate: self, theme: appearance.asElementsTheme)
    private var state: State?

    var isCodeFocused: Bool {
        codeField.isFirstResponder
    }

    /// The height the Done toolbar adds above the keyboard.
    var keyboardAccessoryHeight: CGFloat {
        doneToolbar.frame.height
    }

    init(appearance: PaymentSheet.Appearance, linkBrand: LinkBrand) {
        self.appearance = appearance
        self.isFloating = appearance.embeddedPaymentElement.row.style == .floatingButton
        // Link's own verification screen, scaled down: 56pt-tall digits with a 12pt radius.
        let digitHeight: CGFloat = 44
        self.codeField = OneTimeCodeTextField(
            configuration: .init(
                numberOfDigits: 6,
                enableDigitGrouping: false,
                font: appearance.scaledFont(for: appearance.font.base.medium, style: .title2, maximumPointSize: 28),
                itemCornerRadius: digitHeight * LinkUI.oneTimeCodeTextFieldCornerRadius / 56,
                itemHeight: digitHeight,
                itemMaxWidth: digitHeight / 1.16,
                itemFocusRingThickness: 1.5,
                itemFocusBackgroundColor: appearance.colors.componentBackground
            ),
            theme: Self.makeCodeFieldTheme(appearance: appearance)
        )
        super.init(frame: .zero)
        setUpViews(linkBrand: linkBrand)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Attributed text doesn't rescale with Dynamic Type on its own.
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory, let state {
            render(state)
        }
    }

    // MARK: Rendering

    func render(_ newState: State) {
        let previousState = state
        state = newState

        var emailTitle = AttributedString(newState.email)
        emailTitle.font = appearance.scaledFont(for: appearance.font.base.regular, style: .subheadline, maximumPointSize: 25)
        emailButton.configuration?.attributedTitle = emailTitle
        emailButton.accessibilityLabel = newState.email
        emailButton.accessibilityHint = Self.switchAccountTitle

        subtitleLabel.attributedText = makeSubtitle(recipient: newState.recipient)
        codeTapTarget.accessibilityLabel = subtitleLabel.attributedText?.string

        codeField.isEnabled = newState.isCodeEntryEnabled
        codeTapTarget.isEnabled = newState.isCodeEntryEnabled
        if let previousState {
            if previousState.inputRevision != newState.inputRevision {
                codeField.value = ""
            }
            if previousState.invalidCodeRevision != newState.invalidCodeRevision {
                if codeField.isFirstResponder {
                    // Clears the field once the animation finishes. The field only focuses when the customer taps it.
                    codeField.performInvalidCodeAnimation(refocusesWhenFinished: false)
                } else {
                    codeField.value = ""
                }
            }
        }

        errorLabel.text = newState.errorMessage
        errorLabel.setHiddenIfNecessary(newState.errorMessage == nil)

        renderActions(newState.actions, isLoading: newState.isActionLoading)
    }

    private func makeSubtitle(recipient: String) -> NSAttributedString {
        let font = appearance.scaledFont(for: appearance.font.base.regular, style: .subheadline, maximumPointSize: 25)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        // Keeps the masked number in order in right-to-left languages.
        let isolatedRecipient = "\u{2068}\(recipient)\u{2069}"
        let text = String(format: String.Localized.enter_code_sent_to, isolatedRecipient)
        let subtitle = NSMutableAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: appearance.colors.textSecondary,
            .paragraphStyle: paragraphStyle,
        ])
        if let range = text.range(of: isolatedRecipient) {
            subtitle.addAttributes([
                .foregroundColor: appearance.colors.text,
                .font: appearance.scaledFont(for: appearance.font.base.medium, style: .subheadline, maximumPointSize: 25),
            ], range: NSRange(range, in: text))
        }
        return subtitle
    }

    private func renderActions(_ actions: State.Actions, isLoading: Bool) {
        actionsMenuButton.isHidden = true
        actionsButton.isAccessibilityElement = true
        switch actions {
        case .none:
            actionsButton.setHiddenIfNecessary(true)
        case .resend(let title, let isEnabled):
            actionsButton.setHiddenIfNecessary(false)
            actionsButton.title = title
            actionsButton.isEnabled = isEnabled && !isLoading
            actionsButton.isLoading = isLoading
        case .menu(let items, let isEnabled):
            actionsButton.setHiddenIfNecessary(false)
            actionsButton.title = Self.moreOptionsTitle
            actionsButton.isEnabled = isEnabled && !isLoading
            actionsButton.isLoading = isLoading
            if #available(iOS 14.0, *), isEnabled, !isLoading {
                actionsMenuButton.isHidden = false
                actionsMenuButton.accessibilityLabel = Self.moreOptionsTitle
                actionsButton.isAccessibilityElement = false
                actionsMenuButton.showsMenuAsPrimaryAction = true
                actionsMenuButton.menu = UIMenu(children: items.map { item in
                    UIAction(
                        title: item.title,
                        image: UIImage(systemName: item.systemImageName),
                        attributes: item.isEnabled ? [] : [.disabled]
                    ) { [weak self] _ in
                        self?.onAction?(item.action)
                    }
                })
            }
        }
    }

    // MARK: Layout

    private func setUpViews(linkBrand: LinkBrand) {
        accessibilityIdentifier = "embedded_link_inline_verification"
        let container: UIView
        if isFloating {
            container = ShadowedRoundedRectangle(appearance: appearance)
        } else {
            container = UIView()
            container.layer.borderWidth = max(appearance.borderWidth, 1)
            container.layer.borderColor = appearance.colors.componentBorder.cgColor
            container.applyCornerRadiusOrConfiguration(for: appearance)
        }
        addAndPinSubview(container)

        var emailButtonConfiguration = UIButton.Configuration.plain()
        emailButtonConfiguration.contentInsets = .zero
        // Keeps the merchant's text color instead of the tint color.
        emailButtonConfiguration.baseForegroundColor = appearance.colors.text
        emailButtonConfiguration.image = UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold))
        emailButtonConfiguration.imagePlacement = .trailing
        emailButtonConfiguration.imagePadding = 4
        emailButtonConfiguration.titleLineBreakMode = .byTruncatingMiddle
        emailButton.configuration = emailButtonConfiguration
        emailButton.contentHorizontalAlignment = .leading
        emailButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        if #available(iOS 14.0, *) {
            emailButton.showsMenuAsPrimaryAction = true
            emailButton.menu = UIMenu(children: [
                UIAction(title: Self.switchAccountTitle) { [weak self] _ in self?.onSwitchAccount?() },
            ])
        } else {
            emailButton.addTarget(self, action: #selector(showSwitchAccountActionSheet), for: .touchUpInside)
        }
        closeButton.accessibilityLabel = String.Localized.close
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        closeButton.setContentHuggingPriority(.required, for: .horizontal)
        closeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        let header = UIStackView(arrangedSubviews: [emailButton, closeButton])
        header.alignment = .center
        header.spacing = 8

        titleLabel.text = Self.title
        titleLabel.font = appearance.scaledFont(for: appearance.font.base.medium, style: .body, maximumPointSize: 30)
        titleLabel.textColor = appearance.colors.text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityTraits = .header
        subtitleLabel.numberOfLines = 0

        // Colors the focused digit's border.
        codeField.tintColor = appearance.colors.selectedComponentBorder ?? appearance.colors.text
        codeField.customInputAccessoryView = doneToolbar
        codeField.addTarget(self, action: #selector(codeFieldChanged), for: .valueChanged)
        codeField.addTarget(self, action: #selector(codeFieldEndedEditing), for: .editingDidEnd)
        codeTapTarget.isAccessibilityElement = true
        codeTapTarget.accessibilityTraits = .button
        codeTapTarget.addTarget(self, action: #selector(didTapCode), for: .touchUpInside)
        let codeContainer = UIView()
        codeContainer.addAndPinSubview(codeField)
        codeContainer.addAndPinSubview(codeTapTarget)

        errorLabel.textAlignment = .center
        errorLabel.setHiddenIfNecessary(true)

        actionsButton.addTarget(self, action: #selector(didTapActions), for: .touchUpInside)
        let actionsContainer = UIView()
        actionsContainer.addSubview(actionsButton)
        actionsButton.translatesAutoresizingMaskIntoConstraints = false
        actionsMenuButton.translatesAutoresizingMaskIntoConstraints = false
        actionsMenuButton.isHidden = true
        actionsContainer.addSubview(actionsMenuButton)
        NSLayoutConstraint.activate([
            actionsButton.topAnchor.constraint(equalTo: actionsContainer.topAnchor),
            actionsButton.bottomAnchor.constraint(equalTo: actionsContainer.bottomAnchor),
            actionsButton.centerXAnchor.constraint(equalTo: actionsContainer.centerXAnchor),
            actionsButton.leadingAnchor.constraint(greaterThanOrEqualTo: actionsContainer.leadingAnchor),
            actionsMenuButton.topAnchor.constraint(equalTo: actionsButton.topAnchor),
            actionsMenuButton.bottomAnchor.constraint(equalTo: actionsButton.bottomAnchor),
            actionsMenuButton.leadingAnchor.constraint(equalTo: actionsButton.leadingAnchor),
            actionsMenuButton.trailingAnchor.constraint(equalTo: actionsButton.trailingAnchor),
        ])

        focusRegion.axis = .vertical
        focusRegion.spacing = 12
        [titleLabel, subtitleLabel, codeContainer, errorLabel, actionsContainer].forEach(focusRegion.addArrangedSubview)
        focusRegion.setCustomSpacing(4, after: titleLabel)
        focusRegion.setCustomSpacing(16, after: subtitleLabel)

        let logo = UIImageView(image: linkBrand.paymentSheetLogoImage)
        logo.contentMode = .scaleAspectFit
        logo.isAccessibilityElement = true
        logo.accessibilityLabel = linkBrand.accessibilityDisplayName
        logo.heightAnchor.constraint(equalToConstant: titleLabel.font.pointSize).isActive = true
        let footer = UIStackView(arrangedSubviews: [logo, UIView()])

        let content = UIStackView(arrangedSubviews: [header, makeDivider(), focusRegion, makeDivider(), footer])
        content.axis = .vertical
        content.spacing = 16
        // The card can scroll under a navigation bar or the status bar; its padding shouldn't grow when it does.
        container.insetsLayoutMarginsFromSafeArea = false
        container.addAndPinSubview(content, directionalLayoutMargins: .init(top: 12, leading: 16, bottom: 16, trailing: 16))
    }

    /// Unfocused digits are shaded and borderless; the focused digit takes the component background.
    private static func makeCodeFieldTheme(appearance: PaymentSheet.Appearance) -> ElementsAppearance {
        var theme = appearance.asElementsTheme
        let componentBackground = appearance.colors.componentBackground
        theme.colors.componentBackground = UIColor { traitCollection in
            let resolvedColor = componentBackground.resolvedColor(with: traitCollection)
            return resolvedColor.isBright ? resolvedColor.darken(by: 0.04) : resolvedColor.lighten(by: 0.08)
        }
        theme.colors.border = .clear
        return theme
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = appearance.embeddedPaymentElement.row.flat.separatorColor ?? appearance.colors.componentBorder
        divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        return divider
    }

    // MARK: Focus

    /// Starts typing in the card. Taps on the code field otherwise only call `onTapCode`.
    func focusCode() {
        codeTapTarget.isHidden = true
        codeField.becomeFirstResponder()
    }

    func resignCode() {
        codeField.resignFirstResponder()
        codeTapTarget.isHidden = false
    }

    /// Shows digits typed into a previous card for the same attempt, without submitting them.
    func restoreCode(_ code: String) {
        codeField.value = code
    }

    // MARK: Actions

    @objc private func didTapClose() {
        onClose?()
    }

    @objc private func didTapCode() {
        onTapCode?()
    }

    @objc private func codeFieldChanged() {
        onCodeChanged?(codeField.value)
        if codeField.isComplete {
            onCodeEntered?(codeField.value)
        }
    }

    @objc private func codeFieldEndedEditing() {
        codeTapTarget.isHidden = false
        onCodeEditingEnded?()
    }

    @objc private func didTapActions() {
        guard let state else { return }
        switch state.actions {
        case .none:
            break
        case .resend:
            onAction?(.resend)
        case .menu(let items, _):
            // iOS 13 can't open a button menu on its primary action.
            presentActionSheet(items.map { item in (item.title, item.isEnabled, { [weak self] in self?.onAction?(item.action) }) })
        }
    }

    @objc private func showSwitchAccountActionSheet() {
        presentActionSheet([(Self.switchAccountTitle, true, { [weak self] in self?.onSwitchAccount?() })])
    }

    private func presentActionSheet(_ items: [(title: String, isEnabled: Bool, handler: () -> Void)]) {
        guard let presenter = findViewController(for: self) else { return }
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for item in items {
            let action = UIAlertAction(title: item.title, style: .default) { _ in item.handler() }
            action.isEnabled = item.isEnabled
            sheet.addAction(action)
        }
        sheet.addAction(UIAlertAction(title: String.Localized.cancel, style: .cancel))
        sheet.popoverPresentationController?.sourceView = self
        sheet.popoverPresentationController?.sourceRect = bounds
        presenter.present(sheet, animated: true)
    }

    // MARK: Strings

    static var title: String {
        STPLocalizedString(
            "Use your saved information",
            "Title of the Link verification shown inline when a returning Link customer is recognized."
        )
    }

    static var switchAccountTitle: String {
        STPLocalizedString(
            "Switch accounts",
            "Menu action to stop using the recognized Link account and use a different one."
        )
    }

    static var moreOptionsTitle: String {
        STPLocalizedString("More options", "Button opening Link authentication actions.")
    }
}

extension EmbeddedLinkInlineVerificationView.State {
    /// The state of `coordinator`'s attempt, for the account `email`.
    @MainActor
    init(coordinator: LinkAuthFlowCoordinator, email: String) {
        let resendTitle: String = {
            let seconds = coordinator.resendSecondsRemaining
            guard seconds > 0 else { return String.Localized.resend_code }
            return String(format: STPLocalizedString("Resend code in %d seconds", "Link OTP resend cooldown, in seconds."), seconds)
        }()
        let actions: Actions
        switch coordinator.actions.count {
        case 0:
            actions = .none
        case 1:
            actions = .resend(title: resendTitle, isEnabled: coordinator.canResend)
        default:
            actions = .menu(
                items: coordinator.actions.map { action in
                    switch action {
                    case .resend:
                        return MenuItem(action: .resend, title: resendTitle, systemImageName: "arrow.clockwise", isEnabled: coordinator.canResend)
                    case .email:
                        let title = STPLocalizedString("Email code", "Link authentication action to receive an email verification code.")
                        return MenuItem(action: .email, title: title, systemImageName: "envelope", isEnabled: true)
                    }
                },
                isEnabled: !coordinator.isLoadingOTP
            )
        }
        self.init(
            email: email,
            recipient: coordinator.recipient,
            isCodeEntryEnabled: coordinator.canSubmitCode,
            errorMessage: coordinator.errorMessage,
            actions: actions,
            isActionLoading: coordinator.isLoadingOTP,
            inputRevision: coordinator.inputRevision,
            invalidCodeRevision: coordinator.invalidCodeRevision
        )
    }
}

/// A button whose menu opens from its chevron, so the menu doesn't cover the title.
private final class ChevronMenuButton: UIButton {
    override func menuAttachmentPoint(for configuration: UIContextMenuConfiguration) -> CGPoint {
        guard let imageView else { return super.menuAttachmentPoint(for: configuration) }
        return convert(CGPoint(x: imageView.bounds.midX, y: imageView.bounds.maxY), from: imageView)
    }

    // The menu grows out of this preview.
    @available(iOS 16.0, *)
    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configuration: UIContextMenuConfiguration,
        highlightPreviewForItemWithIdentifier identifier: any NSCopying
    ) -> UITargetedPreview? {
        guard let imageView, imageView.window != nil else {
            return super.contextMenuInteraction(interaction, configuration: configuration, highlightPreviewForItemWithIdentifier: identifier)
        }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: imageView, parameters: parameters)
    }
}

extension EmbeddedLinkInlineVerificationView: @preconcurrency DoneButtonToolbarDelegate {
    func didTapDone(_ toolbar: DoneButtonToolbar) {
        resignCode()
    }
}
