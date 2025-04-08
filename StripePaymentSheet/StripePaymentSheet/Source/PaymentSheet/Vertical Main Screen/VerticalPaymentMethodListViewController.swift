//
//  VerticalPaymentMethodListViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/20/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

// MARK: - VerticalPaymentMethodListViewController
/// A simple container VC for the VerticalPaymentMethodListView, which displays payment options in a vertical list.
class VerticalPaymentMethodListViewController: UIViewController {
    /// Returns the number of row buttons in the vertical list
    var rowCount: Int {
        return rowButtons.count
    }
    var rowButtons: [RowButton] {
        return stackView.arrangedSubviews.compactMap { $0 as? RowButton }
    }
    private(set) var currentSelection: RowButtonType?
    let stackView = UIStackView()
    let appearance: PaymentSheet.Appearance
    let currency: String?
    private(set) var incentive: PaymentMethodIncentive?
    weak var delegate: VerticalPaymentMethodListViewControllerDelegate?

    // Properties moved from initializer captures
    private var overrideHeaderView: UIView?
    private var savedPaymentMethod: STPPaymentMethod?
    private var initialSelection: RowButtonType?
    private var savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?
    private var shouldShowApplePay: Bool
    private var shouldShowLink: Bool
    private var paymentMethodTypes: [PaymentSheet.PaymentMethodType]

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(
        initialSelection: RowButtonType?,
        savedPaymentMethod: STPPaymentMethod?,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        shouldShowApplePay: Bool,
        shouldShowLink: Bool,
        savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?,
        overrideHeaderView: UIView?,
        appearance: PaymentSheet.Appearance,
        currency: String?,
        amount: Int?,
        incentive: PaymentMethodIncentive?,
        delegate: VerticalPaymentMethodListViewControllerDelegate
    ) {
        self.appearance = appearance
        self.currency = currency
        self.incentive = incentive
        self.delegate = delegate
        self.overrideHeaderView = overrideHeaderView
        self.savedPaymentMethod = savedPaymentMethod
        self.initialSelection = initialSelection
        self.savedPaymentMethodAccessoryType = savedPaymentMethodAccessoryType
        self.shouldShowApplePay = shouldShowApplePay
        self.shouldShowLink = shouldShowLink
        self.paymentMethodTypes = paymentMethodTypes

        super.init(nibName: nil, bundle: nil)
        self.renderContent()
    }

    private func refreshContent() {
        stackView.arrangedSubviews.forEach { subview in
            subview.removeFromSuperview()
        }

        renderContent()
    }

    private func renderContent() {
        // Add the header - either the passed in `header` or "Select payment method"
        let header = overrideHeaderView ?? PaymentSheetUI.makeHeaderLabel(title: .Localized.select_payment_method, appearance: appearance)
        stackView.addArrangedSubview(header)
        stackView.setCustomSpacing(24, after: header)

        // Create stack view views after super.init so that we can reference `self`
        var views = [UIView]()
        // Saved payment method:
        if let savedPaymentMethod {
            let selection = RowButtonType.saved(paymentMethod: savedPaymentMethod)
            let accessoryButton: RowButton.RightAccessoryButton? = {
                if let savedPaymentMethodAccessoryType {
                    return RowButton.RightAccessoryButton(accessoryType: savedPaymentMethodAccessoryType, appearance: appearance, didTap: didTapAccessoryButton)
                } else {
                    return nil
                }
            }()

            let savedPaymentMethodButton = RowButton.makeForSavedPaymentMethod(paymentMethod: savedPaymentMethod, appearance: appearance, accessoryView: accessoryButton) { [weak self] in
                self?.didTap(rowButton: $0, selection: selection)
            }
            if initialSelection == selection {
                savedPaymentMethodButton.isSelected = true
                currentSelection = selection
            }
            views += [
                Self.makeSectionLabel(text: .Localized.saved, appearance: appearance),
                savedPaymentMethodButton,
                .makeSpacerView(height: 12),
                Self.makeSectionLabel(text: .Localized.new_payment_method, appearance: appearance),
            ]
        }

        // Build Apple Pay and Link rows
        let applePay: RowButton? = {
            guard shouldShowApplePay else { return nil }
            let selection = RowButtonType.applePay
            let rowButton = RowButton.makeForApplePay(appearance: appearance) { [weak self] in
                self?.didTap(rowButton: $0, selection: .applePay)
            }
            if initialSelection == selection {
                rowButton.isSelected = true
                currentSelection = selection
            }
            return rowButton
        }()
        let link: RowButton? = {
            guard shouldShowLink else { return nil }
            let selection = RowButtonType.link
            let rowButton = RowButton.makeForLink(appearance: appearance) { [weak self] in
                self?.didTap(rowButton: $0, selection: .link)
            }
            if initialSelection == selection {
                rowButton.isSelected = true
                currentSelection = selection
            }
            return rowButton
        }()

        // Payment methods
        var indexAfterCards: Int?
        let paymentMethodTypes = paymentMethodTypes
        for paymentMethodType in paymentMethodTypes {
            let selection = RowButtonType.new(paymentMethodType: paymentMethodType)
            let rowButton = RowButton.makeForPaymentMethodType(
                paymentMethodType: paymentMethodType,
                currency: currency,
                hasSavedCard: savedPaymentMethod?.type == .card, // TODO(RUN_MOBILESDK-3708)
                promoText: incentive?.takeIfAppliesTo(paymentMethodType)?.displayText,
                appearance: appearance,
                // Enable press animation if tapping this transitions the screen to a form instead of becoming selected
                shouldAnimateOnPress: delegate?.shouldSelectPaymentMethod(selection) == false
            ) { [weak self] in
                self?.didTap(rowButton: $0, selection: selection)
            }
            views.append(rowButton)
            if paymentMethodType == .stripe(.card), let index = views.firstIndex(of: rowButton) {
                indexAfterCards = index + 1
            }
            if initialSelection == selection {
                rowButton.isSelected = true
                currentSelection = selection
            }
        }

        // Insert Apple Pay/Link after card or, if cards aren't present, first
        views.insert(contentsOf: [applePay, link].compactMap({ $0 }), at: indexAfterCards ?? 0)

        for view in views {
            stackView.addArrangedSubview(view)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        stackView.axis = .vertical
        stackView.spacing = 12.0
        view = stackView
        view.backgroundColor = appearance.colors.background
    }

    // MARK: - Helpers

    func didTap(rowButton: RowButton, selection: RowButtonType) {
        guard let delegate else { return }
        let shouldSelect = delegate.shouldSelectPaymentMethod(selection)
        if shouldSelect {
            // Deselect previous row
            rowButtons.forEach {
                $0.isSelected = false
            }
            // Select new row
            rowButton.isSelected = shouldSelect
            currentSelection = selection
        }
        delegate.didTapPaymentMethod(selection)
        return
    }

    @objc func didTapAccessoryButton() {
        delegate?.didTapSavedPaymentMethodAccessoryButton()
    }

    func setIncentive(_ incentive: PaymentMethodIncentive?) {
        guard self.incentive != incentive else {
            return
        }

        self.incentive = incentive
        self.refreshContent()
    }

    static func makeSectionLabel(text: String, appearance: PaymentSheet.Appearance) -> UILabel {
        let label = UILabel()
        label.font = appearance.scaledFont(for: appearance.font.base.regular, style: .subheadline, maximumPointSize: 25)
        label.textColor = appearance.colors.text
        label.adjustsFontForContentSizeCategory = true
        label.text = text
        return label
    }
}

// MARK: - VerticalPaymentMethodListViewControllerDelegate
protocol VerticalPaymentMethodListViewControllerDelegate: AnyObject {
    /// Called when a row is tapped, before `didTapPaymentMethod` is called.
    /// - Returns: Whether or not the payment method row button should appear selected.
    func shouldSelectPaymentMethod(_ selection: RowButtonType) -> Bool

    /// Called after a row is tapped and after `shouldSelectPaymentMethod` is called
    func didTapPaymentMethod(_ selection: RowButtonType)

    /// Called when the accessory button on the saved payment method row is tapped
    func didTapSavedPaymentMethodAccessoryButton()
}
