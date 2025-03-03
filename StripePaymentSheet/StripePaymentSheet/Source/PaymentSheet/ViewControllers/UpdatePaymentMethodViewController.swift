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
                   paymentMethod: STPPaymentMethod) async throws
    func shouldCloseSheet(_: UpdatePaymentMethodViewController)
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

    weak var delegate: UpdatePaymentMethodViewControllerDelegate?

    var updateParams: UpdatePaymentMethodOptions? {
        let confirmParams = IntentConfirmParams(type: PaymentSheet.PaymentMethodType.stripe(.card))

        if let params = paymentMethodForm.updateParams(params: confirmParams),
           let cardParams = params.paymentMethodParams.card,
           let originalPaymentMethodCard = configuration.paymentMethod.card,
           hasChangedFields(original: originalPaymentMethodCard, updated: cardParams) {
            return .card(paymentMethodCardParams: cardParams)
        }
        return nil
    }

    var setAsDefaultValue: Bool? {
        guard hasChangedDefaultPaymentMethodCheckbox,
              let checkbox = setAsDefaultCheckbox else {
            return nil
        }
        return checkbox.isSelected
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
            stackView.setCustomSpacing(8, after: paymentMethodForm.view) // custom spacing from figma
        }
        if let setAsDefaultCheckbox = setAsDefaultCheckbox, let lastSubview = stackView.arrangedSubviews.last {
            stackView.addArrangedSubview(setAsDefaultCheckbox.view)
            stackView.setCustomSpacing(20, after: lastSubview) // custom spacing from figma
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
                Task {
                    await self.update(updatePaymentMethodOptions: updatePaymentMethodOptions)
                }
            }
        })
        button.isHidden = !configuration.canEdit
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
        guard configuration.canSetAsDefaultPM,
              PaymentSheet.supportedDefaultPaymentMethods.contains(where: {
                  configuration.paymentMethod.type == $0
              }) else { return nil }
        let setAsDefaultCheckbox = CheckboxElement(theme: configuration.appearance.asElementsTheme, label: String.Localized.set_as_default_payment_method, isSelectedByDefault: configuration.isDefault) { [weak self] isSelected in
            self?.hasChangedDefaultPaymentMethodCheckbox = self?.configuration.isDefault != isSelected
            self?.updateButtonState()
        }
        setAsDefaultCheckbox.delegate = self
        return setAsDefaultCheckbox
    }()

    private lazy var footnoteLabel: UITextView? = {
        guard paymentMethodForm.validationState.isValid else {
            return nil
        }
        let label = ElementsUI.makeSmallFootnote(theme: configuration.appearance.asElementsTheme)
        label.text = configuration.footnote
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
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: configuration.hostedSurface.analyticEvent(for: .openEditScreen))
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
        view.isUserInteractionEnabled = false
        updateButton.update(state: .spinnerWithInteractionDisabled)

        var analyticsParams: [String: Any] = [:]

        if case .card(let paymentMethodCardParams) = updatePaymentMethodOptions {
            analyticsParams["selected_card_brand"] = paymentMethodCardParams.networks?.preferred
        }
        if let setAsDefaultValue {
            analyticsParams["set_as_default"] = setAsDefaultValue
        }
        do {
            try await delegate.didUpdate(viewController: self, paymentMethod: configuration.paymentMethod)
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: configuration.hostedSurface.analyticEvent(for: .updateCard),
                                                                 params: analyticsParams)
        } catch {
            updateButton.update(state: .enabled)
            latestError = error
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: configuration.hostedSurface.analyticEvent(for: .updateCardFailed),
                                                                 error: error,
                                                                 params: analyticsParams)
        }
        view.isUserInteractionEnabled = true
    }

    private func updateButtonState() {
        updateButton.update(state: updateParams != nil || hasChangedDefaultPaymentMethodCheckbox ? .enabled : .disabled)
    }

    func hasChangedFields(original: STPPaymentMethodCard, updated: STPPaymentMethodCardParams) -> Bool {
        let cardBrandChanged = configuration.canUpdateCardBrand && original.preferredDisplayBrand != updated.networks?.preferred?.toCardBrand
        return cardBrandChanged
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
        case card(paymentMethodCardParams: STPPaymentMethodCardParams)
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
