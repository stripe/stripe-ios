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
    func didDismiss(viewController: UpdatePaymentMethodViewController)
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
        let stackView = UIStackView(arrangedSubviews: [cardInfoSection, saveButton, deleteButton, errorLabel])
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.setCustomSpacing(PaymentSheetUI.defaultPadding + 12, after: cardInfoSection) // custom spacing from figma
        stackView.setCustomSpacing(PaymentSheetUI.defaultPadding - 4, after: saveButton) // custom spacing from figma
        return stackView
    }()

    private lazy var headerLabel: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: appearance)
        label.text = .Localized.manage_card
        return label
    }()

    private lazy var saveButton: ConfirmButton = {
        let button = ConfirmButton(state: .disabled, callToAction: .custom(title: .Localized.save), appearance: appearance, didTap: {  [weak self] in
            Task {
                await self?.updateCard()
            }
        })
        button.isHidden = !canEditCard
        return button
    }()

    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        button.setTitleColor(appearance.colors.danger, for: .normal)
        button.layer.borderColor = appearance.colors.danger.cgColor
        button.layer.borderWidth = appearance.primaryButton.borderWidth
        button.layer.cornerRadius = appearance.cornerRadius
        button.setTitle(.Localized.remove_card, for: .normal)
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
    private lazy var headerLabelElement: StaticElement = {
        return StaticElement(view: headerLabel)
    }()
    
    private lazy var cardNumberElement: TextFieldElement = {
        return TextFieldElement.LastFourConfiguration(lastFour: paymentMethod.card?.last4 ?? "").makeElement(theme: appearance.asElementsTheme)
        
    }()

    private lazy var expiryDateElement: TextFieldElement = {
        let formattedMonth = "\(String(format: "%02d", paymentMethod.card?.expMonth ?? 1))"
        let formattedYear = "\(String(format: "%02d", (paymentMethod.card?.expYear ?? Calendar.current.component(.year, from: Date()) + 1) % 100))"
        let formattedExpDate = "\(formattedMonth)\(formattedYear)"
        return TextFieldElement.ExpiryDateConfiguration(defaultValue: formattedExpDate, isEditable: false).makeElement(theme: appearance.asElementsTheme)
        
    }()

    private lazy var cvcElement: TextFieldElement = {
        let cvcConfiguration = TextFieldElement.CVCConfiguration(defaultValue: "123", cardBrandProvider:  { [weak self] in
            self?.paymentMethod.card?.brand ?? .unknown
        }, isEditable: false)
        let censoredCVC = cvcConfiguration.censor()
        let cvcTextField = cvcConfiguration.makeElement(theme: appearance.asElementsTheme)
        cvcTextField.setText(censoredCVC)
        return cvcTextField
        
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

    private lazy var cardBrandDropDown: DropdownFieldElement = {
        let cardBrands = paymentMethod.card?.networks?.available.map({ STPCard.brand(from: $0) }).filter { cardBrandFilter.isAccepted(cardBrand: $0) } ?? []
        let cardBrandDropDown = DropdownFieldElement.makeCardBrandDropdownWithLabel(cardBrands: Set<STPCardBrand>(cardBrands),
                                                                           theme: appearance.asElementsTheme,
                                                                                    includePlaceholder: false) { [weak self] in
                                                                                guard let self = self else { return }
                                                                                let selectedCardBrand = self.cardBrandDropDown.selectedItem.rawData.toCardBrand ?? .unknown
                                                                                let params = ["selected_card_brand": STPCardBrandUtilities.apiValue(from: selectedCardBrand), "cbc_event_source": "edit"]
                                                                                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: self.hostedSurface.analyticEvent(for: .openCardBrandDropdown),
                                                                                    params: params)
                                                                            } didTapClose: { [weak self] in
                                                                                guard let self = self else { return }
                                                                                let selectedCardBrand = self.cardBrandDropDown.selectedItem.rawData.toCardBrand ?? .unknown
                                                                                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: self.hostedSurface.analyticEvent(for: .closeCardBrandDropDown),
                                                                                                                                     params: ["selected_card_brand": STPCardBrandUtilities.apiValue(from: selectedCardBrand)])
                                                                            }

        // pre-select current card brand
        if let currentCardBrand = paymentMethod.card?.preferredDisplayBrand,
           let indexToSelect = cardBrandDropDown.items.firstIndex(where: { $0.rawData == STPCardBrandUtilities.apiValue(from: currentCardBrand) }) {
            cardBrandDropDown.select(index: indexToSelect, shouldAutoAdvance: false)
        }
        cardBrandDropDown.view.isHidden = !canEditCard
        return cardBrandDropDown
    }()
    
    private lazy var cardInfoSection: UIStackView = {
        let cardDetails = UIStackView(arrangedSubviews: [cardSection.view, notEditableDetailsLabel])
        cardDetails.axis = .vertical
        cardDetails.setCustomSpacing(8, after: cardSection.view)
        let stackView = UIStackView(arrangedSubviews: [headerLabel, cardDetails, cardBrandDropDown.view])
        stackView.axis = .vertical
        stackView.setCustomSpacing(PaymentSheetUI.defaultPadding, after: headerLabel) // custom spacing from figma
        stackView.setCustomSpacing(PaymentSheetUI.defaultPadding, after: cardDetails) // custom spacing from figma
        cardBrandDropDown.delegate = self
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
        delegate?.didDismiss(viewController: self)
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

    private func updateCard() async {
        guard let selectedBrand = cardBrandDropDown.selectedItem.rawData.toCardBrand, let delegate = delegate else { return }

        view.isUserInteractionEnabled = false
        saveButton.update(state: .spinnerWithInteractionDisabled)

        // Create the update card params
        let cardParams = STPPaymentMethodCardParams()
        cardParams.networks = .init(preferred: STPCardBrandUtilities.apiValue(from: selectedBrand))
        let updateParams = STPPaymentMethodUpdateParams(card: cardParams, billingDetails: nil)

        // Make the API request to update the payment method
        do {
            try await delegate.didUpdate(viewController: self, paymentMethod: paymentMethod, updateParams: updateParams)
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: hostedSurface.analyticEvent(for: .updateCardBrand),
                                                                 params: ["selected_card_brand": STPCardBrandUtilities.apiValue(from: selectedBrand)])
        } catch {
            saveButton.update(state: .enabled)
            latestError = error
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: hostedSurface.analyticEvent(for: .updateCardBrandFailed),
                                                                 error: error,
                                                                 params: ["selected_card_brand": STPCardBrandUtilities.apiValue(from: selectedBrand)])
        }
        view.isUserInteractionEnabled = true
    }

}

// MARK: BottomSheetContentViewController
extension UpdatePaymentMethodViewController: BottomSheetContentViewController {

    var allowsDragToDismiss: Bool {
        return view.isUserInteractionEnabled
    }

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
        let selectedBrand = cardBrandDropDown.selectedItem.rawData.toCardBrand
        let currentCardBrand = paymentMethod.card?.preferredDisplayBrand ?? .unknown
        let shouldBeEnabled = selectedBrand != currentCardBrand && selectedBrand != .unknown
        saveButton.update(state: shouldBeEnabled ? .enabled : .disabled)
    }
}
