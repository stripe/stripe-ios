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
    func isCVCRecollectionEnabled() -> Bool
    func didUpdateSelection(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection)
    func didSelectRemove(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection)
}

/// For internal SDK use only
@objc(STP_Internal_SavedPaymentOptionsViewController)
class SavedPaymentOptionsViewController: UIViewController {
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
    }

    struct Configuration {
        let customerID: String?
        let showApplePay: Bool
        let showLink: Bool
        let removeSavedPaymentMethodMessage: String?
    }

    var hasRemovablePaymentMethods: Bool {
        return (
            configuration.customerID != nil &&
            !savedPaymentMethods.isEmpty
        )
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

    // MARK: - Internal Properties
    let configuration: Configuration
    private let intent: Intent
    private let paymentSheetConfiguration: PaymentSheet.Configuration

    var selectedPaymentOption: PaymentOption? {
        guard let index = selectedViewModelIndex else {
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
           case let .saved(paymentMethod) = viewModels[index] {
            let result = delegate?.isCVCRecollectionEnabled() ?? false &&
              paymentMethod.type == .card
            return result
        }
        return false
    }
    var selectedPaymentOptionIntentConfirmParams: IntentConfirmParams? {
        guard let index = selectedViewModelIndex,
           case let .saved(paymentMethod) = viewModels[index],
            delegate?.isCVCRecollectionEnabled() ?? false,
              paymentMethod.type == .card else {
            return nil
        }

        let params = IntentConfirmParams(type: paymentMethod.paymentSheetPaymentMethodType())
        if let updatedParams = cvcFormElement.updateParams(params: params) {
            return updatedParams
        }
        return nil
    }

    var savedPaymentMethods: [STPPaymentMethod] {
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

    func cvcRecollectionElement() -> CVCRecollectionElement? {
        if let cvc = cvcFormElement.getAllSubElements().first(where: { ($0 as? CVCRecollectionElement) != nil}) as? CVCRecollectionElement {
            return cvc
        }
        return nil
    }

    // MARK: - Views
    private lazy var cvcFormElementView: UIView = {
        return cvcFormElement.view
    }()

    private lazy var collectionView: SavedPaymentMethodCollectionView = {
        let collectionView = SavedPaymentMethodCollectionView(appearance: appearance)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
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
        delegate: SavedPaymentOptionsViewControllerDelegate? = nil
    ) {
        self.savedPaymentMethods = savedPaymentMethods
        self.configuration = configuration
        self.paymentSheetConfiguration = paymentSheetConfiguration
        self.intent = intent
        self.appearance = appearance
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
        let stackView = UIStackView(arrangedSubviews: [
            collectionView, cvcRecollectionContainerView,
        ])
        stackView.bringSubviewToFront(collectionView)
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        updateUI()
    }

    // MARK: - Private methods
    private func updateUI() {
        let defaultPaymentMethod = CustomerPaymentOption.defaultPaymentMethod(for: configuration.customerID)

        // Move default to front
        var savedPaymentMethods = self.savedPaymentMethods
        if let defaultPMIndex = savedPaymentMethods.firstIndex(where: {
            $0.stripeId == defaultPaymentMethod?.value
        }) {
            let defaultPM = savedPaymentMethods.remove(at: defaultPMIndex)
            savedPaymentMethods.insert(defaultPM, at: 0)
        }

        // Transform saved PaymentMethods into ViewModels
        let savedPMViewModels = savedPaymentMethods.compactMap { paymentMethod in
            return Selection.saved(paymentMethod: paymentMethod)
        }

        viewModels =
            [.add]
            + (configuration.showApplePay ? [.applePay] : [])
            + (configuration.showLink ? [.link] : [])
            + savedPMViewModels

        // Select default
        selectedViewModelIndex = viewModels.firstIndex(where: { $0 == defaultPaymentMethod })
            ?? 1

        collectionView.reloadData()
        collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: [])
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: false)

        updateFormElement()
        updateBrand()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first else {
            return
        }
        // For some reason, the selected cell loses its selected appearance
        collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .bottom)
    }

    func unselectPaymentMethod() {
        guard let selectedIndexPath = selectedIndexPath else {
            return
        }
        selectedViewModelIndex = nil
        collectionView.deselectItem(at: selectedIndexPath, animated: true)
        collectionView.reloadItems(at: [selectedIndexPath])
    }

    func selectLink() {
        guard configuration.showLink else {
            return
        }

        CustomerPaymentOption.setDefaultPaymentMethod(.link, forCustomer: configuration.customerID)
        selectedViewModelIndex = viewModels.firstIndex(where: { $0 == .link })
        collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .centeredHorizontally)
    }

    private func updateBrand() {
        guard let selectedViewModelIndex = selectedViewModelIndex else {
            return
        }
        let viewModel = viewModels[selectedViewModelIndex]

        guard case .saved(let paymentMethod) = viewModel else {
            return
        }
        if let cvcRecollectionElement = self.cvcRecollectionElement(),
           let brand = paymentMethod.card?.brand {
            cvcRecollectionElement.didUpdateCardBrand(updatedCardBrand: brand)
        }
    }

    private func updateFormElement() {
        cvcFormElement = makeElement()
        swapFormElementUIIfNeeded()
        sendEventToSubviews(.viewDidAppear, from: view)
    }

    private func makeElement() -> PaymentMethodElement {
        guard case .saved(let paymentMethod, _) = self.selectedPaymentOption,
              paymentMethod.type == .card else {
            return FormElement(autoSectioningElements: [])
        }

        let formElement = PaymentSheetFormFactory(
            intent: intent,
            configuration: .paymentSheet(paymentSheetConfiguration),
            paymentMethod: .card,
            previousCustomerInput: nil)
        let cvcCollectionElement = formElement.makeCardCVCCollection()
        cvcCollectionElement.delegate = self
        return cvcCollectionElement
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
            assertionFailure()
            return UICollectionViewCell()
        }
        cell.setViewModel(viewModel)
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
            // Should have been handled in shouldSelectItemAt: before we got here!
            assertionFailure()
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
        updateFormElement()
        updateBrand()
        delegate?.didUpdateSelection(viewController: self, paymentMethodSelection: viewModel)
    }
}

// MARK: - PaymentOptionCellDelegate
/// :nodoc:
extension SavedPaymentOptionsViewController: PaymentOptionCellDelegate {
    func paymentOptionCellDidSelectRemove(
        _ paymentOptionCell: SavedPaymentMethodCollectionView.PaymentOptionCell
    ) {
        guard let indexPath = collectionView.indexPath(for: paymentOptionCell),
              case .saved(let paymentMethod) = viewModels[indexPath.row]
        else {
            assertionFailure()
            return
        }
        let viewModel = viewModels[indexPath.row]
        let alert = UIAlertAction(
            title: String.Localized.remove, style: .destructive
        ) { (_) in
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
        let cancel = UIAlertAction(
            title: String.Localized.cancel,
            style: .cancel, handler: nil
        )

        let alertController = UIAlertController(
            title: paymentMethod.removalMessage.title,
            message: configuration.removeSavedPaymentMethodMessage ?? paymentMethod.removalMessage.message,
            preferredStyle: .alert
        )

        alertController.addAction(cancel)
        alertController.addAction(alert)
        present(alertController, animated: true, completion: nil)
    }
}

extension STPPaymentMethod {
    var removalMessage: (title: String, message: String) {
        switch type {
        case .card:
            let brandString = STPCardBrandUtilities.stringFrom(card?.brand ?? .unknown) ?? ""
            let last4 = card?.last4 ?? ""
            let formattedMessage = STPLocalizedString(
                "Remove %1$@ ending in %2$@",
                "Content for alert popup prompting to confirm removing a saved card. Remove {card brand} ending in {last 4} e.g. 'Remove VISA ending in 4242'"
            )
            return (
                title: STPLocalizedString(
                    "Remove Card",
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
            assertionFailure()
            return (title: "", message: "")
        }
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
