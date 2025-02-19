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
                   paymentMethod: STPPaymentMethod,
                   updateParams: STPPaymentMethodUpdateParams) async throws
    func shouldCloseSheet(_: UpdatePaymentMethodViewController)
}

/// For internal SDK use only
@objc(STP_Internal_UpdatePaymentMethodViewController)
final class UpdatePaymentMethodViewController: UIViewController {
    private let removeSavedPaymentMethodMessage: String?
    private let isTestMode: Bool
    private let viewModel: UpdatePaymentMethodViewModel

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
                                        appearance: viewModel.appearance)
        navBar.delegate = self
        navBar.setStyle(navigationBarStyle())
        return navBar
    }()

    // MARK: Views
    lazy var formStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerLabel, paymentMethodForm])
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.spacing = 16 // custom spacing from figma
        if let footnoteLabel = footnoteLabel {
            stackView.addArrangedSubview(footnoteLabel)
            stackView.setCustomSpacing(8, after: paymentMethodForm) // custom spacing from figma
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
        let label = PaymentSheetUI.makeHeaderLabel(appearance: viewModel.appearance)
        label.text = viewModel.header
        return label
    }()

    private lazy var updateButton: ConfirmButton = {
        let button = ConfirmButton(state: .disabled, callToAction: .custom(title: .Localized.save), appearance: viewModel.appearance, didTap: {  [weak self] in
            guard let self = self else { return }
            if let updatePaymentMethodOptions = viewModel.updateParams(paymentMethodElement: formFactory.savedCardForm),
               case .card(let cardUpdateParams) = updatePaymentMethodOptions {
                Task {
                    await self.updateCard(paymentMethodCardParams: cardUpdateParams)
                }
            }
            if self.viewModel.hasChangedDefaultPaymentMethodCheckbox {
                // TODO: update default payment method in the back end
            }
        })
        button.isHidden = !viewModel.canEdit
        return button
    }()

    private lazy var removeButton: RemoveButton = {
        let button = RemoveButton(title: .Localized.remove, appearance: viewModel.appearance)
        button.addTarget(self, action: #selector(removePaymentMethod), for: .touchUpInside)
        button.isHidden = !viewModel.canRemove
        return button
    }()

    private lazy var formFactory: SavedPaymentMethodFormFactory = {
        let factory = SavedPaymentMethodFormFactory(viewModel: viewModel)
        factory.delegate = self
        return factory
    }()

    private lazy var paymentMethodForm: UIView = {
        return formFactory.makePaymentMethodForm()
    }()

    private lazy var setAsDefaultCheckbox: CheckboxElement? = {
        guard viewModel.canSetAsDefaultPM,
              PaymentSheet.supportedDefaultPaymentMethods.contains(where: {
            viewModel.paymentMethod.type == $0
        }) else { return nil }
        return CheckboxElement(theme: viewModel.appearance.asElementsTheme, label: String.Localized.set_as_default_payment_method, isSelectedByDefault: viewModel.isDefault) { [weak self] isSelected in
            self?.viewModel.hasChangedDefaultPaymentMethodCheckbox = self?.viewModel.isDefault != isSelected
            self?.updateButtonState()
        }
    }()

    private lazy var footnoteLabel: UITextView? = {
        if viewModel.errorState {
            return nil
        }
        let label = ElementsUI.makeSmallFootnote(theme: viewModel.appearance.asElementsTheme)
        label.text = viewModel.footnote
        return label
    }()

    private lazy var errorLabel: UILabel = {
        let label = ElementsUI.makeErrorLabel(theme: viewModel.appearance.asElementsTheme)
        label.isHidden = true
        return label
    }()

    // MARK: Overrides
    init(removeSavedPaymentMethodMessage: String?,
         isTestMode: Bool,
         viewModel: UpdatePaymentMethodViewModel) {
        self.removeSavedPaymentMethodMessage = removeSavedPaymentMethodMessage
        self.isTestMode = isTestMode
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // disable swipe to dismiss
        isModalInPresentation = true
        self.view.backgroundColor = viewModel.appearance.colors.background
        view.addAndPinSubview(formStackView, insets: PaymentSheetUI.defaultSheetMargins)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: viewModel.hostedSurface.analyticEvent(for: .openEditScreen))
    }

    // MARK: Private helpers
    private func dismiss() {
        guard let bottomVc = parent as? BottomSheetViewController else { return }
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: viewModel.hostedSurface.analyticEvent(for: .closeEditScreen))
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
        let alertController = UIAlertController.makeRemoveAlertController(paymentMethod: viewModel.paymentMethod,
                                                                          removeSavedPaymentMethodMessage: removeSavedPaymentMethodMessage) { [weak self] in
            guard let self = self else { return }
            self.delegate?.didRemove(viewController: self, paymentMethod: self.viewModel.paymentMethod)
        }

        present(alertController, animated: true, completion: nil)
    }

    private func updateCard(paymentMethodCardParams: STPPaymentMethodCardParams) async {
       guard let delegate = delegate else {
            return
        }
        view.isUserInteractionEnabled = false
        updateButton.update(state: .spinnerWithInteractionDisabled)

        // Create the update card params
        let updateParams = STPPaymentMethodUpdateParams(card: paymentMethodCardParams, billingDetails: nil)

        var analyticsParams: [String: Any] = [:]
        if let selectedBrand = paymentMethodCardParams.networks?.preferred {
            analyticsParams["selected_card_brand"] = selectedBrand
        }

        do {
            try await delegate.didUpdate(viewController: self, paymentMethod: viewModel.paymentMethod, updateParams: updateParams)
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: viewModel.hostedSurface.analyticEvent(for: .updateCard),
                                                                 params: analyticsParams)
        } catch {
            updateButton.update(state: .enabled)
            latestError = error
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: viewModel.hostedSurface.analyticEvent(for: .updateCardFailed),
                                                                 error: error,
                                                                 params: analyticsParams)
        }
        view.isUserInteractionEnabled = true
    }

    private func updateButtonState() {
        let params = viewModel.updateParams(paymentMethodElement: formFactory.savedCardForm)
        updateButton.update(state: params != nil || viewModel.hasChangedDefaultPaymentMethodCheckbox ? .enabled : .disabled)
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
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: viewModel.hostedSurface.analyticEvent(for: .closeEditScreen))
        _ = bottomVc.popContentViewController()
    }

}

// MARK: SavedPaymentMethodFormFactoryDelegate
extension UpdatePaymentMethodViewController: SavedPaymentMethodFormFactoryDelegate {
    func didUpdate(_: Element) {
        latestError = nil // clear error on new input
        switch viewModel.paymentMethod.type {
        case .card:
            updateButtonState()
        default:
            break
        }
    }
}
