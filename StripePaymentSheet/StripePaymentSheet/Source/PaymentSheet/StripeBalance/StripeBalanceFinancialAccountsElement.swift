//
//  StripeBalanceFinancialAccountsElement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 11/12/26.
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

/// Lists the buyer's financial accounts so they can choose which one to pay from with Stripe balance.
/// Accounts that can't cover the payment are shown with the reason, but can't be selected. Nothing is selected until the buyer chooses.
@MainActor
final class StripeBalanceFinancialAccountsElement: @preconcurrency PaymentMethodElement {
    static let apiPath = "stripe_balance[financial_account]"

    struct NoFinancialAccountSelectedError: ElementValidationError {
        var localizedDescription: String { "" }
    }

    weak var delegate: ElementDelegate?
    let collectsUserInput: Bool = true
    var view: UIView { stackView }

    private(set) var selectedFinancialAccountID: String?
    private let rows: [StripeBalanceFinancialAccountRow]
    private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()

    var validationState: ElementValidationState {
        guard selectedFinancialAccountID != nil else {
            return .invalid(error: NoFinancialAccountSelectedError(), shouldDisplay: false)
        }
        return .valid
    }

    /// - Parameters:
    ///   - financialAccounts: The buyer's accounts, loaded with PaymentSheet. `nil` only for forms PaymentSheet doesn't show, since it doesn't offer Stripe balance without them.
    ///   - defaultFinancialAccountID: The account to select if it's selectable, e.g. the buyer's previous choice.
    init(financialAccounts: StripeBalanceFinancialAccounts?, defaultFinancialAccountID: String?, appearance: PaymentSheet.Appearance) {
        rows = financialAccounts.map { financialAccounts in
            financialAccounts.accounts.map {
                StripeBalanceFinancialAccountRow(financialAccount: $0, currency: financialAccounts.currency, appearance: appearance)
            }
        } ?? []
        if rows.contains(where: { $0.financialAccount.id == defaultFinancialAccountID && $0.financialAccount.isSelectable }) {
            selectedFinancialAccountID = defaultFinancialAccountID
        }

        let theme = appearance.asElementsTheme
        // Asks the buyer to choose, so the rows read as options rather than information
        let titleLabel = ElementsUI.makeSectionTitleLabel(theme: theme)
        titleLabel.text = Self.titleText
        titleLabel.adjustsFontForContentSizeCategory = true
        stackView.addArrangedSubview(titleLabel)
        stackView.setCustomSpacing(8, after: titleLabel)
        for row in rows {
            row.addTarget(self, action: #selector(didTapRow), for: .touchUpInside)
            stackView.addArrangedSubview(row)
        }
        updateRowSelection()
    }

    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        guard let selectedFinancialAccountID else {
            return nil
        }
        params.paymentMethodParams.additionalAPIParameters[Self.apiPath] = selectedFinancialAccountID
        return params
    }

    @objc private func didTapRow(_ row: StripeBalanceFinancialAccountRow) {
        guard row.isEnabled, row.financialAccount.id != selectedFinancialAccountID else { return }
        selectedFinancialAccountID = row.financialAccount.id
        selectionFeedbackGenerator.selectionChanged()
        updateRowSelection()
        delegate?.didUpdate(element: self)
    }

    private func updateRowSelection() {
        rows.forEach { $0.isSelected = $0.financialAccount.id == selectedFinancialAccountID }
    }

    // MARK: - Strings

    private static var titleText: String {
        STPLocalizedString(
            "Pay from",
            "Title above the list of the customer's Stripe balance accounts, asking them to choose the one to pay from"
        )
    }
}

/// A selectable row with a radio button, the account's name, and its available balance in the payment's currency.
/// Styled like PaymentSheet's floating payment method rows. Accounts that can't cover the payment are disabled and say why.
final class StripeBalanceFinancialAccountRow: UIControl {
    let financialAccount: StripeBalanceFinancialAccount
    private let appearance: PaymentSheet.Appearance
    private lazy var backgroundView = ShadowedRoundedRectangle(appearance: appearance)
    private lazy var radioButton = RadioButton(appearance: appearance)
    private let contentStackView = UIStackView()

    override var isSelected: Bool {
        didSet {
            backgroundView.isSelected = isSelected
            radioButton.isOn = isSelected
            updateAccessibilityTraits()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.contentStackView.alpha = self.isHighlighted ? 0.5 : 1
            }
        }
    }

    init(financialAccount: StripeBalanceFinancialAccount, currency: String?, appearance: PaymentSheet.Appearance) {
        self.financialAccount = financialAccount
        self.appearance = appearance
        super.init(frame: .zero)
        isEnabled = financialAccount.isSelectable
        setUpViews(currency: currency)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews(currency: String?) {
        let name = financialAccount.displayName ?? String(format: Self.unnamedAccountFormat, String(financialAccount.id.suffix(4)))
        // The formatted amount shows the currency, as in "£392.04 available". There's no currency to show a balance in when setting up.
        let availableBalanceText = currency.flatMap { financialAccount.availableBalance(in: $0) }.map {
            String(format: Self.availableBalanceFormat, String.localizedAmountDisplayString(for: $0.value, currency: $0.currency))
        }

        let titleLabel = UILabel()
        titleLabel.text = name
        titleLabel.font = appearance.scaledFont(for: appearance.font.base.medium, style: .subheadline, maximumPointSize: 25)
        titleLabel.textColor = isEnabled ? appearance.colors.componentText : appearance.colors.textSecondary
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true

        let subtitleLabel = UILabel()
        subtitleLabel.attributedText = makeSubtitle(availableBalanceText: availableBalanceText)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.isHidden = subtitleLabel.attributedText?.length ?? 0 == 0

        let labelsStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelsStackView.axis = .vertical
        labelsStackView.spacing = 2

        radioButton.alpha = isEnabled ? 1 : 0.5
        radioButton.setContentHuggingPriority(.required, for: .horizontal)
        contentStackView.addArrangedSubview(radioButton)
        contentStackView.addArrangedSubview(labelsStackView)
        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.spacing = 12
        contentStackView.isUserInteractionEnabled = false

        backgroundView.isEnabled = isEnabled
        backgroundView.isUserInteractionEnabled = false
        addAndPinSubview(backgroundView)
        addAndPinSubview(contentStackView, insets: .insets(top: 14, leading: 14, bottom: 14, trailing: 14))
        NSLayoutConstraint.activate([
            radioButton.widthAnchor.constraint(equalToConstant: radioButton.intrinsicContentSize.width),
            radioButton.heightAnchor.constraint(equalToConstant: radioButton.intrinsicContentSize.height),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
        ])

        isAccessibilityElement = true
        accessibilityLabel = [name, availableBalanceText, reason].compactMap { $0 }.joined(separator: ", ")
        updateAccessibilityTraits()
    }

    /// The available balance, after why the account can't be selected if it can't, as in "Insufficient balance · £25.00 available"
    private func makeSubtitle(availableBalanceText: String?) -> NSAttributedString {
        let font = appearance.scaledFont(for: appearance.font.base.regular, style: .caption1, maximumPointSize: 20)
        let subtitle = NSMutableAttributedString()
        if let reason {
            subtitle.append(NSAttributedString(string: reason, attributes: [.font: font, .foregroundColor: appearance.colors.danger]))
        }
        if let availableBalanceText {
            let separator = subtitle.length > 0 ? " · " : ""
            subtitle.append(NSAttributedString(
                string: separator + availableBalanceText,
                attributes: [.font: font, .foregroundColor: appearance.colors.textSecondary]
            ))
        }
        return subtitle
    }

    private var reason: String? {
        guard !financialAccount.isSelectable else { return nil }
        switch financialAccount.ineligibleReason {
        case .insufficientBalance:
            return STPLocalizedString(
                "Insufficient balance",
                "Shown with a Stripe balance account whose available balance can't cover the payment; the account can't be selected"
            )
        case .currencyMismatch:
            return STPLocalizedString(
                "Currency not supported",
                "Shown with a Stripe balance account that can't pay in the payment's currency; the account can't be selected"
            )
        case .unparsable, nil:
            // A reason this SDK doesn't know about disables the account without a label
            return nil
        }
    }

    private func updateAccessibilityTraits() {
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        accessibilityTraits = traits
    }

    // MARK: - Strings

    private static var unnamedAccountFormat: String {
        STPLocalizedString(
            "Financial account · ...%@",
            "Name of a customer's Stripe balance account that has no name of its own; %@ is the last four characters of the account's ID"
        )
    }

    private static var availableBalanceFormat: String {
        STPLocalizedString(
            "%@ available",
            "The available balance of a customer's Stripe balance account; %@ is a formatted amount such as £392.04"
        )
    }
}
