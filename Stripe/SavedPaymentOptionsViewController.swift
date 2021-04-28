//
//  SavedPaymentOptionsViewController.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 8/24/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

protocol SavedPaymentOptionsViewControllerDelegate: AnyObject {
    func didUpdateSelection(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection)
    func didSelectRemove(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection)
}

class SavedPaymentOptionsViewController: UIViewController {
    // MARK: - Types
    /**
     Represents the payment method the user has selected
     */
    // TODO (cleanup) Replace this with didSelectX delegate methods. Turn this into a private ViewModel class
    enum Selection {
        case applePay
        case saved(paymentMethod: STPPaymentMethod)
        case add
    }

    var hasRemovablePaymentMethods: Bool {
        guard customerID != nil else {
            return false
        }
        return savedPaymentMethods.contains { (paymentMethod) -> Bool in
            paymentMethod.isDetachableInPaymentSheet
        }
    }

    var isRemovingPaymentMethods: Bool {
        get {
            return collectionView.isRemovingPaymentMethods
        }
        set {
            collectionView.isRemovingPaymentMethods = newValue
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
            if !collectionView.isRemovingPaymentMethods, selectedViewModelIndex < viewModels.count,
                selectedPaymentOption != nil
            {
                // re-select
                collectionView.selectItem(
                    at: IndexPath(item: selectedViewModelIndex, section: 0), animated: false,
                    scrollPosition: .bottom)
            }
        }
    }

    // MARK: - Internal Properties
    let customerID: String?
    let isApplePayEnabled: Bool
    var selectedPaymentOption: PaymentOption? {
        switch viewModels[selectedViewModelIndex] {
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

    // MARK: - Private Properties
    private var selectedViewModelIndex: Int = 0
    private var viewModels: [Selection] = []

    // MARK: - Views
    private lazy var collectionView: SavedPaymentMethodCollectionView = {
        let collectionView = SavedPaymentMethodCollectionView()
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    // MARK: - Inits
    required init(
        savedPaymentMethods: [STPPaymentMethod], customerID: String?, isApplePayEnabled: Bool,
        delegate: SavedPaymentOptionsViewControllerDelegate? = nil
    ) {
        self.savedPaymentMethods = savedPaymentMethods
        self.customerID = customerID
        self.isApplePayEnabled = isApplePayEnabled
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
        updateUI()
    }

    // MARK: - Private methods
    private func updateUI() {
        let defaultPaymentMethodID = DefaultPaymentMethodStore.retrieveDefaultPaymentMethodID(
            for: customerID ?? "")
        // Move default to front
        var savedPaymentMethods = self.savedPaymentMethods
        if let defaultPMIndex = savedPaymentMethods.firstIndex(where: {
            $0.stripeId == defaultPaymentMethodID
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
            + (isApplePayEnabled ? [.applePay] : [])
            + savedPMViewModels

        // Select default
        selectedViewModelIndex =
            viewModels.firstIndex(where: {
                if case let .saved(paymentMethod) = $0 {
                    return paymentMethod.stripeId == defaultPaymentMethodID
                }
                return false
            }) ?? 1

        collectionView.reloadData()
        collectionView.selectItem(
            at: IndexPath(item: selectedViewModelIndex, section: 0), animated: false,
            scrollPosition: [])
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first else {
            return
        }
        // For some reason, the selected cell loses its selected appearance
        collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .bottom)
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
        let viewModel = viewModels[selectedViewModelIndex]

        if let customerID = customerID {
            // We have a customer - update their default payment method immediately upon selection
            switch viewModel {
            case .add:
                // Should have been handled in shouldSelectItemAt: before we got here!
                assertionFailure()
                break
            case .applePay:
                // Apple Pay is the default if it's available; so just set the default to nil. Revisit upon OTPMs!
                DefaultPaymentMethodStore.saveDefault(paymentMethodID: nil, forCustomer: customerID)
            case .saved(let paymentMethod):
                DefaultPaymentMethodStore.saveDefault(
                    paymentMethodID: paymentMethod.stripeId, forCustomer: customerID)
            }
        }
        delegate?.didUpdateSelection(viewController: self, paymentMethodSelection: viewModel)
    }
}

// MARK: - PaymentOptionCellDelegate
/// :nodoc:
extension SavedPaymentOptionsViewController: PaymentOptionCellDelegate {
    func paymentOptionCellDidSelectRemove(
        _ paymentOptionCell: SavedPaymentMethodCollectionView.PaymentOptionCell
    ) {
        guard let index = collectionView.indexPath(for: paymentOptionCell),
            let viewModel = viewModels.stp_boundSafeObject(at: index.row)
                as? SavedPaymentOptionsViewController.Selection
        else {
            return
        }
        if case .saved(let paymentMethod) = viewModel,
            paymentMethod.isDetachableInPaymentSheet,
            let cardBrand = paymentMethod.card?.brand,
            let brandString = STPCardBrandUtilities.stringFrom(cardBrand)
        {
            let alert = UIAlertAction(
                title: STPLocalizedString(
                    "Remove", "Button title for confirmation alert to remove a saved payment method"
                ), style: .destructive
            ) { (_) in
                self.viewModels.remove(at: index.row)
                // the deletion needs to be in a performBatchUpdates so we make sure it is completed
                // before potentially leaving edit mode (which triggers a reload that may collide with
                // this deletion)
                self.collectionView.performBatchUpdates {
                    self.collectionView.deleteItems(at: [index])
                } completion: { (_) in
                    self.savedPaymentMethods.removeAll(where: {
                        $0.stripeId == paymentMethod.stripeId
                    })
                    if index.row == self.selectedViewModelIndex {
                        self.selectedViewModelIndex = min(1, self.viewModels.count - 1)
                    } else if index.row < self.selectedViewModelIndex {
                        self.selectedViewModelIndex -= 1
                    }
                    self.delegate?.didSelectRemove(
                        viewController: self, paymentMethodSelection: viewModel)
                }
            }
            let cancel = UIAlertAction(
                title: STPLocalizedString("Cancel", "Button title to cancel action in an alert"),
                style: .cancel, handler: nil)

            let label = paymentMethod.card?.last4 ?? ""
            let formattedMessage = STPLocalizedString(
                "Remove %1$@ ending in %2$@",
                "Content for alert popup prompting to confirm removing a saved card. Remove {card brand} ending in {last 4} e.g. 'Remove VISA ending in 4242'")
            let alertController = UIAlertController(
                title: STPLocalizedString(
                    "Remove Card", "Title for confirmation alert to remove a card"),
                message: String(format: formattedMessage, brandString, label),
                preferredStyle: .alert
            )
    
            alertController.addAction(cancel)
            alertController.addAction(alert)
            present(alertController, animated: true, completion: nil)
        }
    }
}

extension STPPaymentMethod {
    var isDetachableInPaymentSheet: Bool {
        return type == .card
    }
}
