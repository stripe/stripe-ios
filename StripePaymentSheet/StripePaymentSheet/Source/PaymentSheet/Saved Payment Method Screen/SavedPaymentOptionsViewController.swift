//
//  SavedPaymentOptionsViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/24/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

protocol SavedPaymentOptionsViewControllerDelegate: AnyObject {
    func didUpdate(_ viewController: SavedPaymentOptionsViewController)
    func didUpdateSelection(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection)
    func didSelectRemove(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection)
    func didSelectUpdate(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection,
        updateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod
}

/// For internal SDK use only
@objc(STP_Internal_SavedPaymentOptionsViewController)
class SavedPaymentOptionsViewController: UIViewController {
    enum Error: Swift.Error {
        case collectionViewDidSelectItemAtAdd
        case unableToDequeueReusableCell
        case paymentOptionCellDidSelectEditOnNonSavedItem
        case paymentOptionCellDidSelectRemoveOnNonSavedItem
        case removePaymentMethodOnNonSavedItem
    }
    // MARK: - Types
    // TODO (cleanup) Replace this with didSelectX delegate methods. Turn this into a private ViewModel class
    /**
     Represents the payment method the user has selected
     */
    enum Selection {
        case applePay
        case link
        case saved(paymentMethod: STPPaymentMethod)
        case add

        static func ==(lhs: Selection, rhs: CustomerPaymentOption?) -> Bool {
            switch lhs {
            case .link:
                return rhs == .link
            case .applePay:
                return rhs == .applePay
            case .saved(let paymentMethod):
                return paymentMethod.stripeId == rhs?.value
            case .add:
                return false
            }
        }

        var isCoBrandedCard: Bool {
            switch self {
            case .applePay, .link, .add:
                return false
            case .saved(paymentMethod: let paymentMethod):
                return paymentMethod.isCoBrandedCard
            }
        }

        var savedPaymentMethod: STPPaymentMethod? {
            switch self {
            case .applePay, .link, .add:
                return nil
            case .saved(paymentMethod: let paymentMethod):
                return paymentMethod
            }
        }
    }

    struct Configuration {
        let customerID: String?
        let showApplePay: Bool
        let showLink: Bool
        let removeSavedPaymentMethodMessage: String?
        let merchantDisplayName: String
        let isCVCRecollectionEnabled: Bool
        let isTestMode: Bool
        let allowsRemovalOfLastSavedPaymentMethod: Bool
        let allowsRemovalOfPaymentMethods: Bool
    }

    // MARK: - Internal Properties

    /// Whether or not you can edit save payment methods by removing or updating them.
    var canEditPaymentMethods: Bool {
        switch savedPaymentMethods.count {
        case 0:
            return false
        case 1:
            // If there's exactly one PM, customer can only edit if configuration allows removal or if that single PM allows for the card brand choice to be updated.
            return (configuration.allowsRemovalOfPaymentMethods && configuration.allowsRemovalOfLastSavedPaymentMethod) || viewModels.contains(where: {
                $0.isCoBrandedCard && cbcEligible
            })
        default:
            return configuration.allowsRemovalOfPaymentMethods || viewModels.contains(where: {
                $0.isCoBrandedCard && cbcEligible
            })
        }
    }

    var isRemovingPaymentMethods: Bool {
        get {
            return collectionView.isRemovingPaymentMethods
        }
        set {
            collectionView.isRemovingPaymentMethods = newValue
            UIView.transition(with: collectionView,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: {
                self.collectionView.reloadData()
            })
            if !collectionView.isRemovingPaymentMethods {
                // re-select
                collectionView.selectItem(
                    at: selectedIndexPath,
                    animated: false,
                    scrollPosition: []
                )
            }
        }
    }
    var bottomNoticeAttributedString: NSAttributedString? {
        if case .saved(let paymentMethod, _) = selectedPaymentOption {
            if paymentMethod.usBankAccount != nil {
                return USBankAccountPaymentMethodElement.attributedMandateTextSavedPaymentMethod(theme: appearance.asElementsTheme)
            }
        }
        return nil
    }

    let configuration: Configuration
    private let intent: Intent
    private let paymentSheetConfiguration: PaymentSheet.Configuration

    var selectedPaymentOption: PaymentOption? {
        guard let index = selectedViewModelIndex, viewModels.indices.contains(index) else {
            return nil
        }

        switch viewModels[index] {
        case .add:
            return nil
        case .applePay:
            return .applePay
        case .link:
            return .link(option: .wallet)
        case let .saved(paymentMethod):
            return .saved(paymentMethod: paymentMethod, confirmParams: selectedPaymentOptionIntentConfirmParams)
        }
    }
    var selectedPaymentOptionIntentConfirmParamsRequired: Bool {
        if let index = selectedViewModelIndex,
           index < viewModels.count,
           case let .saved(paymentMethod) = viewModels[index] {
            let result = self.configuration.isCVCRecollectionEnabled && paymentMethod.type == .card
            return result
        }
        return false
    }
    var selectedPaymentOptionIntentConfirmParams: IntentConfirmParams? {
        guard let index = selectedViewModelIndex,
              index < viewModels.count,
           case let .saved(paymentMethod) = viewModels[index],
              self.configuration.isCVCRecollectionEnabled,
              paymentMethod.type == .card else {
            return nil
        }
        let params = IntentConfirmParams(type: .stripe(paymentMethod.type))
        if let updatedParams = cvcFormElement.updateParams(params: params) {
            return updatedParams
        }
        return nil
    }
    private(set) var savedPaymentMethods: [STPPaymentMethod] {
        didSet {
            updateUI()
        }
    }
    /// Whether or not there are any payment options we can show
    /// i.e. Are there any cells besides the Add cell?
    var hasPaymentOptions: Bool {
        return viewModels.contains {
            if case .add = $0 {
                return false
            }
            return true
        }
    }
    weak var delegate: SavedPaymentOptionsViewControllerDelegate?
    var appearance = PaymentSheet.Appearance.default

    // MARK: - Private Properties
    private var selectedViewModelIndex: Int?
    private var viewModels: [Selection] = []
    private let cbcEligible: Bool

    private var selectedIndexPath: IndexPath? {
        guard
            let index = selectedViewModelIndex,
            index < viewModels.count,
            selectedPaymentOption != nil
        else {
            return nil
        }

        return IndexPath(item: index, section: 0)
    }
    private lazy var cvcFormElement: PaymentMethodElement = {
        return makeElement()
    }()

    private func makeElement() -> PaymentMethodElement {
        guard let index = selectedViewModelIndex,
              index < viewModels.count,
           case let .saved(paymentMethod) = viewModels[index],
              paymentMethod.type == .card else {
            return FormElement(autoSectioningElements: [])
        }

        let formElement = PaymentSheetFormFactory(
            intent: intent,
            configuration: .paymentSheet(paymentSheetConfiguration),
            paymentMethod: .stripe(.card),
            previousCustomerInput: nil)
        let cvcCollectionElement = formElement.makeCardCVCCollection(paymentMethod: paymentMethod,
                                                                     mode: .inputOnly,
                                                                     appearance: appearance)
        cvcCollectionElement.delegate = self
        return cvcCollectionElement
    }

    /// Whether or not there are any payment options we can show
    /// i.e. Are there any cells besides the Add cell? If so, we should move Link to the new PM sheet
    var hasOptionsExcludingAdd: Bool {
        return viewModels.contains {
            switch $0 {
            case .add:
                return false
            default:
                return true
            }
        }
    }

    // MARK: - Views
    private lazy var collectionView: SavedPaymentMethodCollectionView = {
        let collectionView = SavedPaymentMethodCollectionView(appearance: appearance)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [collectionView, cvcRecollectionContainerView, sepaMandateView])
        stackView.axis = .vertical
        stackView.toggleArrangedSubview(cvcRecollectionContainerView, shouldShow: false, animated: false)
        return stackView
    }()

    private lazy var sepaMandateView: UIView = {
        let mandateText = String(format: String.Localized.sepa_mandate_text, configuration.merchantDisplayName)
        let view = UIView()
        let mandateView = SimpleMandateTextView(mandateText: mandateText, theme: appearance.asElementsTheme)
        let margins = NSDirectionalEdgeInsets.insets(
            top: 8,
            leading: PaymentSheetUI.defaultMargins.leading,
            bottom: 0,
            trailing: PaymentSheetUI.defaultMargins.trailing
        )
        view.addAndPinSubview(mandateView, directionalLayoutMargins: margins)
        return view
    }()

    private lazy var cvcFormElementView: UIView = {
        return cvcFormElement.view
    }()

    private lazy var cvcRecollectionContainerView: DynamicHeightContainerView = {
        let view = DynamicHeightContainerView(pinnedDirection: .top)
        view.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        view.addPinnedSubview(cvcFormElementView)
        view.updateHeight()
        return view
    }()

    // MARK: - Inits
    required init(
        savedPaymentMethods: [STPPaymentMethod],
        configuration: Configuration,
        paymentSheetConfiguration: PaymentSheet.Configuration,
        intent: Intent,
        appearance: PaymentSheet.Appearance,
        cbcEligible: Bool = false,
        delegate: SavedPaymentOptionsViewControllerDelegate? = nil
    ) {
        self.savedPaymentMethods = savedPaymentMethods
        self.configuration = configuration
        self.paymentSheetConfiguration = paymentSheetConfiguration
        self.intent = intent
        self.appearance = appearance
        self.cbcEligible = cbcEligible
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addAndPinSubview(stackView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first else {
            return
        }
        // For some reason, the selected cell loses its selected appearance
        collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .bottom)
    }

    func didFinishAnimatingHeight() {
        // Wait 150ms after the view is presented to emphasize to users to enter their CVC
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(150))) {
            if self.isViewLoaded {
                self.toggleCVCElement()
            }
        }
    }

    // MARK: - Private methods

    private func updateUI() {
        (self.selectedViewModelIndex, self.viewModels) = Self.makeViewModels(
            savedPaymentMethods: savedPaymentMethods,
            customerID: configuration.customerID,
            showApplePay: configuration.showApplePay,
            showLink: configuration.showLink
        )

        collectionView.reloadData()
        collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: [])
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: false)
        updateMandateView()
        if isViewLoaded {
            updateFormElement()
        }
    }

    private func updateMandateView() {
        let shouldHideSEPA: Bool = {
            if let selectedViewModelIndex, let viewModel = viewModels.stp_boundSafeObject(at: selectedViewModelIndex),
               case .saved(paymentMethod: let paymentMethod) = viewModel, paymentMethod.type == .SEPADebit {
                // Only show SEPA if there's a selected PM and it's type is SEPADebit.
                return false
            }
            return true
        }()
        if sepaMandateView.isHidden != shouldHideSEPA {
            stackView.toggleArrangedSubview(sepaMandateView, shouldShow: !shouldHideSEPA, animated: isViewLoaded)
        }
    }

    private func updateFormElement() {
        cvcFormElement = makeElement()
        swapFormElementUIIfNeeded()
        toggleCVCElement()
    }
    private func toggleCVCElement() {
        let shouldHideCVCRecollection = !selectedPaymentOptionIntentConfirmParamsRequired
        if cvcRecollectionContainerView.isHidden != shouldHideCVCRecollection {
            stackView.toggleArrangedSubview(cvcRecollectionContainerView, shouldShow: !shouldHideCVCRecollection, animated: isViewLoaded)
        }
    }

    private func swapFormElementUIIfNeeded() {

        if cvcFormElement.view !== cvcFormElementView {
            let oldView = cvcFormElementView
            let newView = cvcFormElement.view
            self.cvcFormElementView = newView

            cvcRecollectionContainerView.addPinnedSubview(newView)
            cvcRecollectionContainerView.layoutIfNeeded()
            newView.alpha = 0

            animateHeightChange {
                self.cvcRecollectionContainerView.updateHeight()
                oldView.alpha = 0
                newView.alpha = 1
            } completion: { _ in
                if oldView !== self.cvcFormElementView {
                    oldView.removeFromSuperview()
                }
            }
        }
    }

    private func unselectPaymentMethod() {
        guard let selectedIndexPath = selectedIndexPath else {
            return
        }
        selectedViewModelIndex = nil
        collectionView.deselectItem(at: selectedIndexPath, animated: true)
        collectionView.reloadItems(at: [selectedIndexPath])
    }

    // MARK: - Helpers

    /// Creates the list of viewmodels to display in the "saved payment methods" carousel e.g. `["+ Add", "Apple Pay", "Link", "Visa 4242"]`
    /// - Returns defaultSelectedIndex: The index of the view model that is the default e.g. in the above list, if "Visa 4242" is the default, the index is 3.
    static func makeViewModels(savedPaymentMethods: [STPPaymentMethod], customerID: String?, showApplePay: Bool, showLink: Bool) -> (defaultSelectedIndex: Int, viewModels: [Selection]) {

        var savedPaymentMethods = savedPaymentMethods
        // Get the default
        let defaultPaymentMethod = CustomerPaymentOption.defaultPaymentMethod(for: customerID)

        // Move default to front
        if let defaultPMIndex = savedPaymentMethods.firstIndex(where: {
            $0.stripeId == defaultPaymentMethod?.value
        }) {
            let defaultPM = savedPaymentMethods.remove(at: defaultPMIndex)
            savedPaymentMethods.insert(defaultPM, at: 0)
        }

        // Transform saved PaymentMethods into view models
        let savedPMViewModels = savedPaymentMethods.compactMap { paymentMethod in
            return Selection.saved(paymentMethod: paymentMethod)
        }

        // Only add Link if other PMs exist
        let showLinkInSPMs = showLink && (showApplePay || !savedPMViewModels.isEmpty)

        let viewModels = [.add]
            + (showApplePay ? [.applePay] : [])
            + (showLinkInSPMs ? [.link] : [])
            + savedPMViewModels

        // Terrible hack, we should refactor the selection logic
        // If the first payment method is Link, we *don't* want to select it by default.
        // Instead, we should set the default index to the option next to Link (either the last saved PM or nothing)
        let firstPaymentMethodIsLink = !showApplePay && showLink
        let defaultIndex = firstPaymentMethodIsLink ? 2 : 1

        let defaultSelectedIndex = viewModels.firstIndex(where: { $0 == defaultPaymentMethod }) ?? defaultIndex
        return (defaultSelectedIndex, viewModels)
    }
}

// MARK: - UICollectionView
/// :nodoc:
extension SavedPaymentOptionsViewController: UICollectionViewDataSource, UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        return viewModels.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        let viewModel = viewModels[indexPath.item]
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SavedPaymentMethodCollectionView.PaymentOptionCell
                    .reuseIdentifier, for: indexPath)
                as? SavedPaymentMethodCollectionView.PaymentOptionCell
        else {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.unableToDequeueReusableCell)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
            return UICollectionViewCell()
        }
        cell.setViewModel(viewModel, cbcEligible: cbcEligible, allowsPaymentMethodRemoval: self.configuration.allowsRemovalOfPaymentMethods)
        cell.delegate = self
        cell.isRemovingPaymentMethods = self.collectionView.isRemovingPaymentMethods
        cell.appearance = appearance

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath)
        -> Bool
    {
        guard !self.collectionView.isRemovingPaymentMethods else {
            return false
        }
        let viewModel = viewModels[indexPath.item]
        if case .add = viewModel {
            delegate?.didUpdateSelection(viewController: self, paymentMethodSelection: viewModel)
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedViewModelIndex = indexPath.item
        let viewModel = viewModels[indexPath.item]

        switch viewModel {
        case .add:
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.collectionViewDidSelectItemAtAdd)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
        case .applePay:
            CustomerPaymentOption.setDefaultPaymentMethod(.applePay, forCustomer: configuration.customerID)
        case .link:
            CustomerPaymentOption.setDefaultPaymentMethod(.link, forCustomer: configuration.customerID)
        case .saved(let paymentMethod):
            CustomerPaymentOption.setDefaultPaymentMethod(
                .stripeId(paymentMethod.stripeId),
                forCustomer: configuration.customerID
            )
        }
        updateMandateView()
        cvcFormElement.clearTextFields()
        updateFormElement()
        delegate?.didUpdateSelection(viewController: self, paymentMethodSelection: viewModel)
    }
}

// MARK: - PaymentOptionCellDelegate
/// :nodoc:
extension SavedPaymentOptionsViewController: PaymentOptionCellDelegate {
    func paymentOptionCellDidSelectEdit(_ paymentOptionCell: SavedPaymentMethodCollectionView.PaymentOptionCell) {
        guard let indexPath = collectionView.indexPath(for: paymentOptionCell),
              case .saved(let paymentMethod) = viewModels[indexPath.row]
        else {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.paymentOptionCellDidSelectEditOnNonSavedItem)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
            return
        }

        let editVc = UpdateCardViewController(paymentMethod: paymentMethod,
                                              removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage,
                                              appearance: appearance,
                                              hostedSurface: .paymentSheet,
                                              canRemoveCard: configuration.allowsRemovalOfPaymentMethods && (savedPaymentMethods.count > 1 || configuration.allowsRemovalOfLastSavedPaymentMethod),
                                              isTestMode: configuration.isTestMode)
        editVc.delegate = self
        self.bottomSheetController?.pushContentViewController(editVc)
    }

    func paymentOptionCellDidSelectRemove(
        _ paymentOptionCell: SavedPaymentMethodCollectionView.PaymentOptionCell
    ) {
        guard let indexPath = collectionView.indexPath(for: paymentOptionCell),
              case .saved(let paymentMethod) = viewModels[indexPath.row]
        else {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.paymentOptionCellDidSelectRemoveOnNonSavedItem,
                                              additionalNonPIIParams: [
                                                "indexPathRow": collectionView.indexPath(for: paymentOptionCell)?.row ?? "nil",
                                                "viewModels": viewModels.map { $0.analyticsValue.rawValue },
                                              ]
            )
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
            return
        }

        let alertController = UIAlertController.makeRemoveAlertController(paymentMethod: paymentMethod,
                                                                          removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage) { [weak self] in
            guard let self = self else { return }
            self.removePaymentMethod(paymentMethod)
        }

        present(alertController, animated: true, completion: nil)
    }

    private func removePaymentMethod(_ paymentMethod: STPPaymentMethod) {
        guard let row = viewModels.firstIndex(where: { $0.savedPaymentMethod?.stripeId == paymentMethod.stripeId })
        else {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.removePaymentMethodOnNonSavedItem)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
            return
        }
        let indexPath = IndexPath(row: row, section: 0)
        let viewModel = viewModels[indexPath.row]
        self.viewModels.remove(at: indexPath.row)
        // the deletion needs to be in a performBatchUpdates so we make sure it is completed
        // before potentially leaving edit mode (which triggers a reload that may collide with
        // this deletion)
        self.collectionView.performBatchUpdates {
            self.collectionView.deleteItems(at: [indexPath])
        } completion: { _ in
            self.savedPaymentMethods.removeAll(where: {
                $0.stripeId == paymentMethod.stripeId
            })

            if let index = self.selectedViewModelIndex {
                if indexPath.row == index {
                    self.selectedViewModelIndex = min(1, self.viewModels.count - 1)
                } else if indexPath.row < index {
                    self.selectedViewModelIndex = index - 1
                }
            }

            self.delegate?.didSelectRemove(
                viewController: self,
                paymentMethodSelection: viewModel
            )
        }
    }
}

// MARK: - UpdateCardViewControllerDelegate
extension SavedPaymentOptionsViewController: UpdateCardViewControllerDelegate {
    func didRemove(viewController: UpdateCardViewController, paymentMethod: STPPaymentMethod) {
        removePaymentMethod(paymentMethod)
        _ = viewController.bottomSheetController?.popContentViewController()
    }

    func didUpdate(viewController: UpdateCardViewController,
                   paymentMethod: STPPaymentMethod,
                   updateParams: STPPaymentMethodUpdateParams) async throws {
        guard let row = viewModels.firstIndex(where: { $0.savedPaymentMethod?.stripeId == paymentMethod.stripeId }),
              let delegate = delegate
        else {
            stpAssertionFailure()
            throw PaymentSheetError.unknown(debugDescription: NSError.stp_unexpectedErrorMessage())
        }

        let viewModel = viewModels[row]
        let updatedPaymentMethod = try await delegate.didSelectUpdate(viewController: self,
                                                    paymentMethodSelection: viewModel,
                                                    updateParams: updateParams)

        let updatedViewModel: Selection = .saved(paymentMethod: updatedPaymentMethod)
        viewModels[row] = updatedViewModel
        collectionView.reloadData()
        _ = viewController.bottomSheetController?.popContentViewController()
    }
}

extension STPPaymentMethod {
    enum Error: Swift.Error {
        case removalMessageUndefined
    }
    var removalMessage: (title: String, message: String) {
        switch type {
        case .card:
            let brandString = STPCardBrandUtilities.stringFrom(card?.networks?.preferred?.toCardBrand ?? card?.brand ?? .unknown) ?? ""
            let last4 = card?.last4 ?? ""
            let formattedMessage = STPLocalizedString(
                "%1$@ •••• %2$@",
                "Content for alert popup prompting to confirm removing a saved card. {card brand} •••• {last 4} e.g. 'Visa •••• 3155'"
            )
            return (
                title: STPLocalizedString(
                    "Remove card?",
                    "Title for confirmation alert to remove a card"
                ),
                message: String(format: formattedMessage, brandString, last4)
            )
        case .SEPADebit:
            let last4 = sepaDebit?.last4 ?? ""
            let formattedMessage = String.Localized.removeBankAccountEndingIn
            return (
                title: String.Localized.removeBankAccount,
                message: String(format: formattedMessage, last4)
            )
        case .USBankAccount:
            let last4 = usBankAccount?.last4 ?? ""
            let formattedMessage = String.Localized.removeBankAccountEndingIn
            return (
                title: String.Localized.removeBankAccount,
                message: String(format: formattedMessage, last4)
            )
        default:
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.removalMessageUndefined,
                                              additionalNonPIIParams: ["payment_method_type": type.identifier])
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
            return (title: "", message: "")
        }
    }
}

// MARK: UIAlertController extension

extension UIAlertController {
    static func makeRemoveAlertController(paymentMethod: STPPaymentMethod,
                                          removeSavedPaymentMethodMessage: String?,
                                          completion: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertAction(
            title: String.Localized.remove, style: .destructive
        ) { (_) in
            completion()
        }
        let cancel = UIAlertAction(
            title: String.Localized.cancel,
            style: .cancel, handler: nil
        )

        let alertController = UIAlertController(
            title: paymentMethod.removalMessage.title,
            message: removeSavedPaymentMethodMessage ?? paymentMethod.removalMessage.message,
            preferredStyle: .alert
        )

        alertController.addAction(cancel)
        alertController.addAction(alert)

        return alertController
    }
}

extension SavedPaymentOptionsViewController: ElementDelegate {
    func continueToNextField(element: Element) {
        delegate?.didUpdate(self)
    }

    func didUpdate(element: Element) {
        delegate?.didUpdate(self)
        animateHeightChange()
    }
}

extension STPPaymentMethod {
    var isCoBrandedCard: Bool {
        guard let availableNetworks = card?.networks?.available else { return false }
        return availableNetworks.count > 1
    }
}
