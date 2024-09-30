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
    private(set) var currentSelection: VerticalPaymentMethodListSelection?
    let stackView = UIStackView()
    let appearance: PaymentSheet.Appearance
    weak var delegate: VerticalPaymentMethodListViewControllerDelegate?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(
        initialSelection: VerticalPaymentMethodListSelection?,
        savedPaymentMethod: STPPaymentMethod?,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        shouldShowApplePay: Bool,
        shouldShowLink: Bool,
        savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?,
        overrideHeaderView: UIView?,
        appearance: PaymentSheet.Appearance,
        currency: String?,
        amount: Int?,
        delegate: VerticalPaymentMethodListViewControllerDelegate
    ) {
        self.currentSelection = initialSelection
        self.delegate = delegate
        self.appearance = appearance
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)

        // Add the header - either the passed in `header` or "Select payment method"
        let header = overrideHeaderView ?? PaymentSheetUI.makeHeaderLabel(title: .Localized.select_payment_method, appearance: appearance)
        stackView.addArrangedSubview(header)
        stackView.setCustomSpacing(24, after: header)

        // Create stack view views after super.init so that we can reference `self`
        var views = [UIView]()
        // Saved payment method:
        if let savedPaymentMethod {
            let selection = VerticalPaymentMethodListSelection.saved(paymentMethod: savedPaymentMethod)
            let accessoryButton: RowButton.RightAccessoryButton? = {
                if let savedPaymentMethodAccessoryType {
                    return RowButton.RightAccessoryButton(accessoryType: savedPaymentMethodAccessoryType, appearance: appearance, didTap: didTapAccessoryButton)
                } else {
                    return nil
                }
            }()

            let savedPaymentMethodButton = RowButton.makeForSavedPaymentMethod(paymentMethod: savedPaymentMethod, appearance: appearance, rightAccessoryView: accessoryButton) { [weak self] in
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
            let selection = VerticalPaymentMethodListSelection.applePay
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
            let selection = VerticalPaymentMethodListSelection.link
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
            let selection = VerticalPaymentMethodListSelection.new(paymentMethodType: paymentMethodType)
            let rowButton = RowButton.makeForPaymentMethodType(
                paymentMethodType: paymentMethodType,
                subtitle: Self.subtitleText(for: paymentMethodType),
                savedPaymentMethodType: savedPaymentMethod?.type,
                appearance: appearance,
                // Enable press animation if tapping this transitions the screen to a form instead of becoming selected
                shouldAnimateOnPress: !delegate.shouldSelectPaymentMethod(selection)
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

    func clearSelection() {
        currentSelection = nil
        for rowButton in rowButtons {
            rowButton.isSelected = false
        }
    }

    // MARK: - Helpers

    func didTap(rowButton: RowButton, selection: VerticalPaymentMethodListSelection) {
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

    static func makeSectionLabel(text: String, appearance: PaymentSheet.Appearance) -> UILabel {
        let label = UILabel()
        label.font = appearance.scaledFont(for: appearance.font.base.regular, style: .subheadline, maximumPointSize: 25)
        label.textColor = appearance.colors.text
        label.adjustsFontForContentSizeCategory = true
        label.text = text
        return label
    }

    static func subtitleText(for paymentMethodType: PaymentSheet.PaymentMethodType) -> String? {
        switch paymentMethodType {
        case .stripe(.klarna):
            return String.Localized.buy_now_or_pay_later_with_klarna
        case .stripe(.afterpayClearpay):
            if AfterpayPriceBreakdownView.shouldUseClearpayBrand(for: Locale.current) {
                return String.Localized.buy_now_or_pay_later_with_clearpay
            } else {
                return String.Localized.buy_now_or_pay_later_with_afterpay
            }
        case .stripe(.affirm):
            return String.Localized.pay_over_time_with_affirm
        default:
            return nil
        }
    }
}

// MARK: - VerticalPaymentMethodListViewControllerDelegate
protocol VerticalPaymentMethodListViewControllerDelegate: AnyObject {
    /// Called when a row is tapped, before `didTapPaymentMethod` is called.
    /// - Returns: Whether or not the payment method row button should appear selected.
    func shouldSelectPaymentMethod(_ selection: VerticalPaymentMethodListSelection) -> Bool

    /// Called after a row is tapped and after `shouldSelectPaymentMethod` is called
    func didTapPaymentMethod(_ selection: VerticalPaymentMethodListSelection)

    /// Called when the accessory button on the saved payment method row is tapped
    func didTapSavedPaymentMethodAccessoryButton()
}

// MARK: - VerticalPaymentMethodListSelection
enum VerticalPaymentMethodListSelection: Equatable {
    case new(paymentMethodType: PaymentSheet.PaymentMethodType)
    case saved(paymentMethod: STPPaymentMethod)
    case applePay
    case link

    static func == (lhs: VerticalPaymentMethodListSelection, rhs: VerticalPaymentMethodListSelection) -> Bool {
        switch (lhs, rhs) {
        case (.link, .link):
            return true
        case (.applePay, .applePay):
            return true
        case let (.new(lhsPMType), .new(rhsPMType)):
            return lhsPMType == rhsPMType
        case let (.saved(lhsPM), .saved(rhsPM)):
            return lhsPM.stripeId == rhsPM.stripeId
        default:
            return false
        }
    }

    var analyticsIdentifier: String {
        switch self {
        case .applePay:
            return "apple_pay"
        case .link:
            return "link"
        case .saved:
            return "saved"
        case .new(paymentMethodType: let type):
            return type.identifier
        }
    }
}
