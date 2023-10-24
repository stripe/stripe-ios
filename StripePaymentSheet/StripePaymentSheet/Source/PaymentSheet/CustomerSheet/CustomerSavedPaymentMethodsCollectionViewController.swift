//
//  CustomerSavedPaymentMethodsCollectionViewController.swift
//  StripePaymentSheet
//

import Foundation
import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

protocol CustomerSavedPaymentMethodsCollectionViewControllerDelegate: AnyObject {
    func didUpdateSelection(
        viewController: CustomerSavedPaymentMethodsCollectionViewController,
        paymentMethodSelection: CustomerSavedPaymentMethodsCollectionViewController.Selection)
    func didSelectRemove(
        viewController: CustomerSavedPaymentMethodsCollectionViewController,
        paymentMethodSelection: CustomerSavedPaymentMethodsCollectionViewController.Selection,
        originalPaymentMethodSelection: CustomerPaymentOption?)
}
/*
 This class is largely a copy of SavedPaymentOptionsViewController, however a couple of exceptions
  - Removes link as an option
  - Does not save the selected payment method to the local device settings
  - Fetches customerId using the underlying backing STPCustomerContext
 */

/// For internal SDK use only
@objc(STP_Internal_SavedPaymentMethodsCollectionViewController)
class CustomerSavedPaymentMethodsCollectionViewController: UIViewController {
    // MARK: - Types
    // TODO (cleanup) Replace this with didSelectX delegate methods. Turn this into a private ViewModel class
    /**
     Represents the payment method the user has selected
     */
    enum Selection {
        case applePay
        case saved(paymentMethod: STPPaymentMethod)
        case add

        static func ==(lhs: Selection, rhs: CustomerPaymentOption?) -> Bool {
            switch lhs {
            case .applePay:
                return rhs == .applePay
            case .saved(let paymentMethod):
                return paymentMethod.stripeId == rhs?.value
            case .add:
                return false
            }
        }
        func toSavedPaymentOptionsViewControllerSelection() -> SavedPaymentOptionsViewController.Selection {
            switch self {
            case .applePay:
                return .applePay
            case .add:
                return .add
            case .saved(let paymentMethod):
                return .saved(paymentMethod: paymentMethod)
            }
        }
    }

    struct Configuration {
        let showApplePay: Bool
    }

    var hasRemovablePaymentMethods: Bool {
        return (
            !savedPaymentMethods.isEmpty || !unsyncedSavedPaymentMethods.isEmpty
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
            } else {
                // Revert to the originally selected index
                if originalSelectedViewModelIndex == nil {
                    selectedViewModelIndex = nil
                } else {
                    selectedViewModelIndex = originalSelectedViewModelIndex
                }
            }
        }
    }
    var bottomNoticeAttributedString: NSAttributedString? {
        if case .saved(let paymentMethod) = selectedPaymentOption {
            if paymentMethod.usBankAccount != nil {
                return USBankAccountPaymentMethodElement.attributedMandateTextSavedPaymentMethod(theme: appearance.asElementsTheme)
            }
        }
        return nil
    }

    // MARK: - Internal Properties
    let configuration: Configuration
    let savedPaymentMethodsConfiguration: CustomerSheet.Configuration
    let customerAdapter: CustomerAdapter

    var selectedPaymentOption: PaymentOption? {
        guard let index = selectedViewModelIndex else {
            return nil
        }

        switch viewModels[index] {
        case .add:
            return nil
        case .applePay:
            return .applePay
        case let .saved(paymentMethod):
            return .saved(paymentMethod: paymentMethod)
        }
    }
    var savedPaymentMethods: [STPPaymentMethod] {
        didSet {
            updateUI(selectedSavedPaymentOption: originalSelectedSavedPaymentMethod)
        }
    }
    var unsyncedSavedPaymentMethods: [STPPaymentMethod] {
        didSet {
            if let firstPaymentMethod = self.unsyncedSavedPaymentMethods.first {
                let paymentOption = CustomerPaymentOption(value: firstPaymentMethod.stripeId)
                updateUI(selectedSavedPaymentOption: paymentOption)
            } else {
                updateUI(selectedSavedPaymentOption: originalSelectedSavedPaymentMethod)
            }
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
    weak var delegate: CustomerSavedPaymentMethodsCollectionViewControllerDelegate?
    let originalSelectedSavedPaymentMethod: CustomerPaymentOption?
    var originalSelectedViewModelIndex: Int? {
        guard let originalSelectedSavedPaymentMethod = originalSelectedSavedPaymentMethod else {
            return nil
        }
        return self.viewModels.firstIndex(where: { $0 == originalSelectedSavedPaymentMethod })
    }
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

    // MARK: - Views
    private lazy var collectionView: SavedPaymentMethodCollectionView = {
        let collectionView = SavedPaymentMethodCollectionView(appearance: appearance)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    // MARK: - Inits
    required init(
        savedPaymentMethods: [STPPaymentMethod],
        selectedPaymentMethodOption: CustomerPaymentOption?,
        savedPaymentMethodsConfiguration: CustomerSheet.Configuration,
        customerAdapter: CustomerAdapter,
        configuration: Configuration,
        appearance: PaymentSheet.Appearance,
        delegate: CustomerSavedPaymentMethodsCollectionViewControllerDelegate? = nil
    ) {
        self.savedPaymentMethods = savedPaymentMethods
        self.originalSelectedSavedPaymentMethod = selectedPaymentMethodOption
        self.savedPaymentMethodsConfiguration = savedPaymentMethodsConfiguration
        self.configuration = configuration
        self.customerAdapter = customerAdapter
        self.appearance = appearance
        self.delegate = delegate
        self.unsyncedSavedPaymentMethods = []
        super.init(nibName: nil, bundle: nil)
        updateUI(selectedSavedPaymentOption: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public func didAddSavedPaymentMethod(paymentMethod: STPPaymentMethod) {
        let unsyncedSavedPaymentMethodsCopy = unsyncedSavedPaymentMethods
        self.unsyncedSavedPaymentMethods = [paymentMethod] + unsyncedSavedPaymentMethodsCopy
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        [collectionView].forEach({
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        })

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // In the add payment flow, selectedViewModelIndex is set, and then
        // the view is loaded. Checking selectedViewModelIndex is needed to avoid
        // override selecting the newly added payment method.
        if selectedViewModelIndex == nil {
            self.updateUI(selectedSavedPaymentOption: self.originalSelectedSavedPaymentMethod)
        }
    }

    // MARK: - Private methods
    private func updateUI(selectedSavedPaymentOption: CustomerPaymentOption?) {
        // Move default to front
        var savedPaymentMethods = self.savedPaymentMethods
        if let defaultPMIndex = savedPaymentMethods.firstIndex(where: {
            $0.stripeId == selectedSavedPaymentOption?.value
        }) {
            let defaultPM = savedPaymentMethods.remove(at: defaultPMIndex)
            savedPaymentMethods.insert(defaultPM, at: 0)
        }

        // Transform saved PaymentMethods into ViewModels
        let savedPMViewModels = savedPaymentMethods.compactMap { paymentMethod in
            return Selection.saved(paymentMethod: paymentMethod)
        }
        let unsyncedSavedPMViewModels = self.unsyncedSavedPaymentMethods.compactMap { paymentMethod in
            return Selection.saved(paymentMethod: paymentMethod)
        }

        self.viewModels =
        [.add]
        + (self.configuration.showApplePay ? [.applePay] : [])
        + unsyncedSavedPMViewModels
        + savedPMViewModels

        // Select default
        self.selectedViewModelIndex = self.viewModels.firstIndex(where: { $0 == selectedSavedPaymentOption })

        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.collectionView.selectItem(at: self.selectedIndexPath, animated: false, scrollPosition: [])
            self.collectionView.scrollRectToVisible(CGRect.zero, animated: false)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        STPAnalyticsClient.sharedClient.logCSSelectPaymentMethodScreenPresented()

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
    func didSelectDifferentPaymentMethod() -> Bool {
        if let selectedViewModelIndex = self.selectedViewModelIndex {
            let selectedViewModel = self.viewModels[selectedViewModelIndex]
            if let originalSelectedSavedPaymentMethod = self.originalSelectedSavedPaymentMethod {
                return !(selectedViewModel == originalSelectedSavedPaymentMethod)
            } else {
                return true
            }
        } else {
            if originalSelectedViewModelIndex == nil {
                return false
            } else {
                return true
            }
        }
    }
}

// MARK: - UICollectionView
/// :nodoc:
extension CustomerSavedPaymentMethodsCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate,
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

        // TODO(porter) CBC check in CustomerSheet
        cell.setViewModel(viewModel.toSavedPaymentOptionsViewControllerSelection(), cbcEligible: false)
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

        delegate?.didUpdateSelection(viewController: self, paymentMethodSelection: viewModel)
    }
}

// MARK: - PaymentOptionCellDelegate
/// :nodoc:
extension CustomerSavedPaymentMethodsCollectionViewController: PaymentOptionCellDelegate {
    func paymentOptionCellDidSelectEdit(_ paymentOptionCell: SavedPaymentMethodCollectionView.PaymentOptionCell) {
        // TODO(porter) CustomerSheet CBC support
    }

    func paymentOptionCellDidSelectRemove(
        _ paymentOptionCell: SavedPaymentMethodCollectionView.PaymentOptionCell
    ) {
        guard let indexPath = collectionView.indexPath(for: paymentOptionCell),
              case .saved(let paymentMethod) = viewModels[indexPath.row]
        else {
            assertionFailure("Please file an issue with reproduction steps at https://github.com/stripe/stripe-ios")
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
                self.unsyncedSavedPaymentMethods.removeAll(where: {
                    $0.stripeId == paymentMethod.stripeId
                })

                if let index = self.selectedViewModelIndex {
                    if indexPath.row == index {
                        self.selectedViewModelIndex = nil
                    } else if indexPath.row < index {
                        self.selectedViewModelIndex = index - 1
                    }
                }

                self.delegate?.didSelectRemove(
                    viewController: self,
                    paymentMethodSelection: viewModel,
                    originalPaymentMethodSelection: self.originalSelectedSavedPaymentMethod
                )
            }
        }
        let cancel = UIAlertAction(
            title: String.Localized.cancel,
            style: .cancel, handler: nil
        )

        let alertController = UIAlertController(
            title: paymentMethod.removalMessage.title,
            message: self.savedPaymentMethodsConfiguration.removeSavedPaymentMethodMessage ?? paymentMethod.removalMessage.message,
            preferredStyle: .alert
        )

        alertController.addAction(cancel)
        alertController.addAction(alert)
        present(alertController, animated: true, completion: nil)
    }
}
