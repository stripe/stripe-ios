//
//  UpdatePaymentMethodViewController.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/5/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

@MainActor
protocol UpdatePaymentMethodViewControllerDelegate: AnyObject {
    func didRemove(viewController: UpdatePaymentMethodViewController, paymentMethod: STPPaymentMethod)
    func didUpdate(viewController: UpdatePaymentMethodViewController,
                   paymentMethod: STPPaymentMethod,
                   updateParams: STPPaymentMethodUpdateParams) async throws
    func didDismiss()
}

/// For internal SDK use only
@objc(STP_Internal_UpdatePaymentMethodViewController)
final class UpdatePaymentMethodViewController: UIViewController {
    private let appearance: PaymentSheet.Appearance
    private let paymentMethod: STPPaymentMethod
    private let removeSavedPaymentMethodMessage: String?
    private let isTestMode: Bool
    private let hostedSurface: HostedSurface
    private let canEditCard: Bool
    private let canRemoveCard: Bool
    private let cardBrandFilter: CardBrandFilter

    private var latestError: Error? {
        didSet {
            errorLabel.text = latestError?.localizedDescription
            errorLabel.isHidden = latestError == nil
        }
    }

    weak var delegate: UpdatePaymentMethodViewControllerDelegate?

    // MARK: Navigation bar
    internal lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: isTestMode,
                                        appearance: appearance)
        navBar.delegate = self
        navBar.setStyle(navigationBarStyle())
        return navBar
    }()

    // MARK: Views
    lazy var formStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [cardInfoSection, deleteButton, errorLabel])
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.setCustomSpacing(PaymentSheetUI.defaultPadding + 12, after: cardInfoSection) // custom spacing from figma
        return stackView
    }()

    private lazy var headerLabel: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: appearance)
        label.text = .Localized.manage_card
        return label
    }()

    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        button.setTitleColor(appearance.colors.danger, for: .normal)
        button.layer.borderColor = appearance.colors.danger.cgColor
        button.layer.borderWidth = appearance.primaryButton.borderWidth
        button.layer.cornerRadius = appearance.cornerRadius
        button.setTitle(.Localized.remove, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = appearance.scaledFont(for: appearance.font.base.medium, style: .callout, maximumPointSize: 25)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: #selector(removeCard), for: .touchUpInside)
        button.isHidden = !canRemoveCard
        return button
    }()

    private lazy var notEditableDetailsLabel: UITextView = {
        let label = ElementsUI.makeSmallFootnote(theme: appearance.asElementsTheme)
        label.text = .Localized.card_details_cannot_be_changed
        return label
    }()

    private lazy var errorLabel: UILabel = {
        let label = ElementsUI.makeErrorLabel(theme: appearance.asElementsTheme)
        label.isHidden = true
        return label
    }()

    // MARK: Elements

    private lazy var cardNumberElement: TextFieldElement = {
        let cardNumberElement = TextFieldElement.LastFourConfiguration(lastFour: paymentMethod.card?.last4 ?? "").makeElement(theme: appearance.asElementsTheme, setDisabledBackgroundColor: true)
        return cardNumberElement

    }()

    private lazy var expiryDateElement: TextFieldElement = {
        let formattedMonth = "\(String(format: "%02d", paymentMethod.card?.expMonth ?? 0))"
        let formattedYear = "\(String(format: "%02d", paymentMethod.card?.expYear ?? 0))"
        let formattedExpDate = "\(formattedMonth)\(formattedYear)"
        let expiryDateElement = TextFieldElement.ExpiryDateConfiguration(defaultValue: formattedExpDate, isEditable: false).makeElement(theme: appearance.asElementsTheme, setDisabledBackgroundColor: true)
        return expiryDateElement

    }()

    private lazy var cvcElement: TextFieldElement = {
        let cvcConfiguration = TextFieldElement.CVCConfiguration(defaultValue: "123", cardBrandProvider:  { [weak self] in
            self?.paymentMethod.card?.brand ?? .unknown
        }, isEditable: false)
        let censoredCVC = cvcConfiguration.censor()
        let cvcElement = cvcConfiguration.makeElement(theme: appearance.asElementsTheme, setDisabledBackgroundColor: true)
        cvcElement.setText(censoredCVC)
        return cvcElement

    }()

    private lazy var cardSection: SectionElement = {
        let allSubElements: [Element?] = [
            cardNumberElement,
            SectionElement.MultiElementRow([expiryDateElement, cvcElement])
        ]

        let section = SectionElement(elements: allSubElements.compactMap { $0 }, theme: appearance.asElementsTheme)
        section.delegate = self
        return section
    }()

    private lazy var cardInfoSection: UIStackView = {
        let cardDetails = UIStackView(arrangedSubviews: [cardSection.view, notEditableDetailsLabel])
        cardDetails.axis = .vertical
        cardDetails.setCustomSpacing(8, after: cardSection.view) // custom spacing from figma
        let stackView = UIStackView(arrangedSubviews: [headerLabel, cardDetails])
        stackView.axis = .vertical
        stackView.setCustomSpacing(PaymentSheetUI.defaultPadding, after: headerLabel) // custom spacing from figma
        stackView.setCustomSpacing(PaymentSheetUI.defaultPadding, after: cardDetails) // custom spacing from figma
        return stackView
    }()

    // MARK: Overrides
    init(paymentMethod: STPPaymentMethod,
         removeSavedPaymentMethodMessage: String?,
         appearance: PaymentSheet.Appearance,
         hostedSurface: HostedSurface,
         canEditCard: Bool,
         canRemoveCard: Bool,
         isTestMode: Bool,
         cardBrandFilter: CardBrandFilter = .default) {
        self.paymentMethod = paymentMethod
        self.removeSavedPaymentMethodMessage = removeSavedPaymentMethodMessage
        self.appearance = appearance
        self.hostedSurface = hostedSurface
        self.isTestMode = isTestMode
        self.canEditCard = canEditCard
        self.canRemoveCard = canRemoveCard
        self.cardBrandFilter = cardBrandFilter

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // disable swipe to dismiss
        isModalInPresentation = true
        self.view.backgroundColor = appearance.colors.background
        view.addAndPinSubview(formStackView, insets: PaymentSheetUI.defaultSheetMargins)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: hostedSurface.analyticEvent(for: .openCardBrandEditScreen))
    }

    // MARK: Private helpers
    private func dismiss() {
        guard let bottomVc = parent as? BottomSheetViewController else { return }
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: hostedSurface.analyticEvent(for: .closeEditScreen))
        _ = bottomVc.popContentViewController()
        delegate?.didDismiss()
    }

    private func navigationBarStyle() -> SheetNavigationBar.Style {
        if let bottomSheet = self.bottomSheetController,
           bottomSheet.contentStack.count > 1 {
            return .back(showAdditionalButton: false)
        } else {
            return .close(showAdditionalButton: false)
        }
    }

    @objc private func removeCard() {
        let alertController = UIAlertController.makeRemoveAlertController(paymentMethod: paymentMethod,
                                                                          removeSavedPaymentMethodMessage: removeSavedPaymentMethodMessage) { [weak self] in
            guard let self = self else { return }
            self.delegate?.didRemove(viewController: self, paymentMethod: self.paymentMethod)
        }

        present(alertController, animated: true, completion: nil)
    }

}

// MARK: BottomSheetContentViewController
extension UpdatePaymentMethodViewController: BottomSheetContentViewController {

    func didTapOrSwipeToDismiss() {
        guard view.isUserInteractionEnabled else {
            return
        }

        dismiss()
    }

    var requiresFullScreen: Bool {
        return false
    }
}

// MARK: SheetNavigationBarDelegate
extension UpdatePaymentMethodViewController: SheetNavigationBarDelegate {

    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        dismiss()
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        dismiss()
    }

}

// MARK: ElementDelegate
extension UpdatePaymentMethodViewController: ElementDelegate {
    func continueToNextField(element: Element) {
        // no-op
    }

    func didUpdate(element: Element) {
        latestError = nil // clear error on new input
    }
}
