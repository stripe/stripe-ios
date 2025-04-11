//
//  UpdatePaymentMethodViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 10/27/23.
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
                   paymentMethod: STPPaymentMethod) async -> UpdatePaymentMethodResult
    func shouldCloseSheet(_: UpdatePaymentMethodViewController)
}

enum UpdatePaymentMethodResult {
    case success
    case failure([Error])
}

enum SetAsDefaultCheckboxState {
    case selected
    case deselected
    case hidden
}

/// For internal SDK use only
@objc(STP_Internal_UpdatePaymentMethodViewController)
final class UpdatePaymentMethodViewController: UIViewController {
    private let removeSavedPaymentMethodMessage: String?
    private let isTestMode: Bool

    private var hasChangedDefaultPaymentMethodCheckbox: Bool = false

    private var lastCardBrandLogSelectedEventSent: String?

    private let configuration: UpdatePaymentMethodViewController.Configuration

    private var latestError: Error? {
        didSet {
            errorLabel.text = latestError?.localizedDescription
            errorLabel.isHidden = latestError == nil
        }
    }

    private var setAsDefaultCheckboxState: SetAsDefaultCheckboxState {
        guard hasChangedDefaultPaymentMethodCheckbox,
              let checkbox = setAsDefaultCheckbox else {
            return .hidden
        }
        return checkbox.isSelected ? .selected : .deselected
    }

    weak var delegate: UpdatePaymentMethodViewControllerDelegate?

    var updateParams: UpdatePaymentMethodOptions? {
        let confirmParams = IntentConfirmParams(type: PaymentSheet.PaymentMethodType.stripe(configuration.paymentMethod.type))

        if let params = paymentMethodForm.updateParams(params: confirmParams),
           params.paymentMethodParams.type == .card,
           let cardParams = params.paymentMethodParams.card,
           hasChangedCard(originalPaymentMethod: configuration.paymentMethod, updatedPaymentMethodParams: params.paymentMethodParams) {
            return .card(paymentMethodCardParams: cardParams, billingDetails: params.paymentMethodParams.billingDetails)
        }
        return nil
    }

    var shouldSetAsDefault: Bool {
        return setAsDefaultCheckboxState == .selected
    }

    // MARK: Navigation bar
    internal lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: isTestMode,
                                        appearance: configuration.appearance)
        navBar.delegate = self
        navBar.setStyle(navigationBarStyle())
        return navBar
    }()

    // MARK: Views
    lazy var formStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerLabel, paymentMethodForm.view])
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.spacing = 16 // custom spacing from figma
        if let footnoteLabel = footnoteLabel {
            stackView.addArrangedSubview(footnoteLabel)
            stackView.setCustomSpacing(4, after: paymentMethodForm.view) // custom spacing from figma
        }
        if let setAsDefaultCheckbox = setAsDefaultCheckbox, let lastSubview = stackView.arrangedSubviews.last {
            stackView.addArrangedSubview(setAsDefaultCheckbox.view)
            stackView.setCustomSpacing(12, after: lastSubview) // custom spacing from figma
        }
        if let lastSubview = stackView.arrangedSubviews.last {
            stackView.setCustomSpacing(32, after: lastSubview) // custom spacing from figma
        }
        stackView.addArrangedSubview(updateButton)
        stackView.addArrangedSubview(removeButton)
        stackView.addArrangedSubview(errorLabel)
        return stackView
    }()

    private lazy var headerLabel: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        label.text = configuration.header
        return label
    }()

    private lazy var updateButton: ConfirmButton = {
        let button = ConfirmButton(state: .disabled, callToAction: .custom(title: .Localized.save), appearance: configuration.appearance, didTap: {  [weak self] in
            guard let self = self else { return }
            let updatePaymentMethodOptions = updateParams
            if updatePaymentMethodOptions != nil || hasChangedDefaultPaymentMethodCheckbox {
                self.view.endEditing(true)
                Task {
                    await self.update(updatePaymentMethodOptions: updatePaymentMethodOptions)
                }
            }
        })
        button.isHidden = !configuration.shouldShowSaveButton
        return button
    }()

    private lazy var removeButton: RemoveButton = {
        let button = RemoveButton(title: .Localized.remove, appearance: configuration.appearance)
        button.addTarget(self, action: #selector(removePaymentMethod), for: .touchUpInside)
        button.isHidden = !configuration.canRemove
        return button
    }()

    private lazy var formFactory: SavedPaymentMethodFormFactory = {
        return SavedPaymentMethodFormFactory()
    }()

    private lazy var paymentMethodForm: PaymentMethodElement = {
        let form = formFactory.makePaymentMethodForm(configuration: configuration)
        form.delegate = self
        return form
    }()

    private lazy var setAsDefaultCheckbox: CheckboxElement? = {
        guard configuration.shouldShowDefaultCheckbox else { return nil }
        let label = configuration.isDefault ? String.Localized.default_payment_method : String.Localized.set_as_default_payment_method
        let setAsDefaultCheckbox = CheckboxElement(theme: configuration.appearance.asElementsTheme, label: label, isSelectedByDefault: configuration.isDefault) { [weak self] isSelected in
            self?.hasChangedDefaultPaymentMethodCheckbox = self?.configuration.isDefault != isSelected
            self?.updateButtonState()
        }
        setAsDefaultCheckbox.checkboxButton.isEnabled = !configuration.isDefault
        setAsDefaultCheckbox.delegate = self
        return setAsDefaultCheckbox
    }()

    private lazy var footnoteLabel: UITextView? = {
        guard paymentMethodForm.validationState.isValid,
              let footnoteText = configuration.footnote else {
            return nil
        }
        let label = ElementsUI.makeSmallFootnote(theme: configuration.appearance.asElementsTheme)
        label.text = footnoteText
        return label
    }()

    private lazy var errorLabel: UILabel = {
        let label = ElementsUI.makeErrorLabel(theme: configuration.appearance.asElementsTheme)
        label.isHidden = true
        return label
    }()

    // MARK: Overrides
    init(removeSavedPaymentMethodMessage: String?,
         isTestMode: Bool,
         configuration: UpdatePaymentMethodViewController.Configuration) {
        self.removeSavedPaymentMethodMessage = removeSavedPaymentMethodMessage
        self.isTestMode = isTestMode
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // disable swipe to dismiss
        isModalInPresentation = true
        self.view.backgroundColor = configuration.appearance.colors.background
        view.addAndPinSubview(formStackView, insets: PaymentSheetUI.defaultSheetMargins)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: configuration.hostedSurface.analyticEvent(for: .openEditScreen), params: ["payment_method_type": configuration.paymentMethod.type.identifier])
    }

    // MARK: Private helpers
    private func dismiss() {
        guard let bottomVc = parent as? BottomSheetViewController else { return }
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: configuration.hostedSurface.analyticEvent(for: .closeEditScreen))
        _ = bottomVc.popContentViewController()
        delegate?.shouldCloseSheet(_: self)
    }

    private func navigationBarStyle() -> SheetNavigationBar.Style {
        if let bottomSheet = self.bottomSheetController,
           bottomSheet.contentStack.count > 1 {
            return .back(showAdditionalButton: false)
        } else {
            return .close(showAdditionalButton: false)
        }
    }

    @objc private func removePaymentMethod() {
        for element in self.paymentMethodForm.getAllUnwrappedSubElements() {
            if let textElement = element as? TextFieldElement {
                textElement.endEditing(true, continueToNextField: false)
            }
        }

        let alertController = UIAlertController.makeRemoveAlertController(paymentMethod: configuration.paymentMethod,
                                                                          removeSavedPaymentMethodMessage: removeSavedPaymentMethodMessage) { [weak self] in
            guard let self = self else { return }
            self.delegate?.didRemove(viewController: self, paymentMethod: self.configuration.paymentMethod)
        }

        present(alertController, animated: true, completion: nil)
    }

    private func update(updatePaymentMethodOptions: UpdatePaymentMethodOptions?) async {
        guard let delegate else {
            return
        }
        // Ensure endEditing(true) is called prior to setting isUserInteractionEnabled
        view.endEditing(true)
        view.isUserInteractionEnabled = false
        updateButton.update(state: .spinnerWithInteractionDisabled)

        let updatePaymentMethodResult = await delegate.didUpdate(viewController: self, paymentMethod: configuration.paymentMethod)
        switch updatePaymentMethodResult {
        case .success:
            if case .card(let paymentMethodCardParams, _) = updatePaymentMethodOptions {
                var params: [String: Any] = [:]
                if let selectedCardBrand = paymentMethodCardParams.networks?.preferred {
                    params["selected_card_brand"] = selectedCardBrand
                }
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: configuration.hostedSurface.analyticEvent(for: .updateCard),
                                                                     params: params)
            }
            if shouldSetAsDefault {
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: configuration.hostedSurface.analyticEvent(for: .setDefaultPaymentMethod),
                                                                     params: ["payment_method_type": configuration.paymentMethod.type.identifier])
            }
        case .failure(let errors):
            updateButton.update(state: .enabled)
            latestError = errors.count == 1 ? errors[0] : NSError.stp_genericErrorOccurredError()
            if errors.contains(where: { ($0 as NSError) == NSError.stp_cardBrandNotUpdatedError() }) {
                if case .card(let paymentMethodCardParams, _) = updatePaymentMethodOptions {
                    var params: [String: Any] = [:]
                    if let selectedCardBrand = paymentMethodCardParams.networks?.preferred {
                        params["selected_card_brand"] = selectedCardBrand
                    }
                    STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: configuration.hostedSurface.analyticEvent(for: .updateCardFailed),
                                                                         error: latestError,
                                                                         params: params)
                }
            }
            if errors.contains(where: { ($0 as NSError) == NSError.stp_defaultPaymentMethodNotUpdatedError() }) {
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: configuration.hostedSurface.analyticEvent(for: .setDefaultPaymentMethodFailed),
                                                                     error: latestError,
                                                                     params: ["payment_method_type": configuration.paymentMethod.type.identifier])
            }
        }
        view.isUserInteractionEnabled = true
    }

    private func updateButtonState() {
        updateButton.update(state: updateParams != nil || hasChangedDefaultPaymentMethodCheckbox ? .enabled : .disabled)
    }

    func hasChangedCard(originalPaymentMethod: STPPaymentMethod, updatedPaymentMethodParams: STPPaymentMethodParams) -> Bool {
        guard originalPaymentMethod.type == .card,
              let updatedPaymentMethodCardParams = updatedPaymentMethodParams.card else {
            stpAssertionFailure("Only payment method type 'card' is supported")
            return false
        }
        return hasChangedCardBrand(originalPaymentMethod: originalPaymentMethod, updatedPaymentMethodCardParams: updatedPaymentMethodCardParams)
        || hasChangedCardFields(originalPaymentMethod: originalPaymentMethod, updatedPaymentMethodCardParams: updatedPaymentMethodCardParams)
        || hasChangedBillingFields(originalPaymentMethod: originalPaymentMethod, updatedBillingDetailsParams: updatedPaymentMethodParams.billingDetails)
    }

    func hasOnlyChangedCardBrand(originalPaymentMethod: STPPaymentMethod, updatedPaymentMethodCardParams: STPPaymentMethodCardParams?, updatedBillingDetailsParams: STPPaymentMethodBillingDetails?) -> Bool {
        guard let updatedPaymentMethodCardParams = updatedPaymentMethodCardParams else {
            return false
        }
        return hasChangedCardBrand(originalPaymentMethod: originalPaymentMethod, updatedPaymentMethodCardParams: updatedPaymentMethodCardParams)
        && !hasChangedCardFields(originalPaymentMethod: originalPaymentMethod, updatedPaymentMethodCardParams: updatedPaymentMethodCardParams)
        && !hasChangedBillingFields(originalPaymentMethod: originalPaymentMethod, updatedBillingDetailsParams: updatedBillingDetailsParams)
    }

    private func hasChangedCardBrand(originalPaymentMethod: STPPaymentMethod, updatedPaymentMethodCardParams: STPPaymentMethodCardParams) -> Bool {
        guard originalPaymentMethod.type == .card,
              let originalCardPaymentMethod = originalPaymentMethod.card else {
            return false
        }
        return configuration.canUpdateCardBrand && originalCardPaymentMethod.preferredDisplayBrand != updatedPaymentMethodCardParams.networks?.preferred?.toCardBrand
    }

    private func hasChangedCardFields(originalPaymentMethod: STPPaymentMethod, updatedPaymentMethodCardParams: STPPaymentMethodCardParams) -> Bool {
        guard originalPaymentMethod.type == .card else {
            return false
        }
        return originalPaymentMethod.hasUpdatedCardParams(updatedPaymentMethodCardParams)
    }

    private func hasChangedBillingFields(originalPaymentMethod: STPPaymentMethod, updatedBillingDetailsParams: STPPaymentMethodBillingDetails?) -> Bool {
        guard originalPaymentMethod.type == .card else {
            return false
        }
        var billingParamsChanged: Bool = false
        if configuration.canUpdate {
            switch self.configuration.billingDetailsCollectionConfiguration.address {
            case .automatic:
                billingParamsChanged = originalPaymentMethod.hasUpdatedAutomaticBillingDetailsParams(updatedBillingDetailsParams)
            case .full:
                billingParamsChanged = originalPaymentMethod.hasUpdatedFullBillingDetailsParams(updatedBillingDetailsParams)
            case .never:
                billingParamsChanged = false
            }
        }
        return billingParamsChanged
    }

    func logCardBrandChangedIfNeeded() {
        let confirmParams = IntentConfirmParams(type: PaymentSheet.PaymentMethodType.stripe(.card))
        guard let params = paymentMethodForm.updateParams(params: confirmParams),
              let cardBrand = params.paymentMethodParams.card?.networks?.preferred?.toCardBrand else {
            return
        }
        let preferredNetworkAPIValue = STPCardBrandUtilities.apiValue(from: cardBrand)
        if self.lastCardBrandLogSelectedEventSent != preferredNetworkAPIValue {
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: configuration.hostedSurface.analyticEvent(for: .cardBrandSelected),
                                                                 params: ["selected_card_brand": preferredNetworkAPIValue,
                                                                          "cbc_event_source": "edit", ])
            self.lastCardBrandLogSelectedEventSent = preferredNetworkAPIValue
        }
    }
}

extension UpdatePaymentMethodViewController {
    enum UpdatePaymentMethodOptions {
        case card(paymentMethodCardParams: STPPaymentMethodCardParams, billingDetails: STPPaymentMethodBillingDetails?)
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

    func sheetNavigationBarDidClose(_: SheetNavigationBar) {
        dismiss()
    }

    func sheetNavigationBarDidBack(_: SheetNavigationBar) {
        guard let bottomVc = parent as? BottomSheetViewController else { return }
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: configuration.hostedSurface.analyticEvent(for: .closeEditScreen))
        _ = bottomVc.popContentViewController()
    }

}

extension UpdatePaymentMethodViewController: ElementDelegate {
    func continueToNextField(element: Element) {
        // no-op
    }

    func didUpdate(element: Element) {
        latestError = nil // clear error on new input
        switch configuration.paymentMethod.type {
        case .card:
            updateButtonState()
            logCardBrandChangedIfNeeded()
        default:
            break
        }
    }
}

extension STPPaymentMethodCard {
    var twoDigitYear: NSNumber? {
        if let year = Int(String(expYear).suffix(2)) {
            return NSNumber(value: year)
        }
        return nil
    }
}
