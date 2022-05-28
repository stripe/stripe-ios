//
//  ShippingAddressViewController.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol ShippingAddressViewControllerDelegate: AnyObject {
    func shouldClose(_ viewController: ShippingAddressViewController)
}

class ShippingAddressViewController: UIViewController {
    let configuration: PaymentSheet.Configuration
    weak var delegate: ShippingAddressViewControllerDelegate?
    /// Always a valid address or nil.
    var shippingAddressDetails: PaymentSheet.ShippingAddressDetails? {
        let a = addressSection
        if a.isValidAddress {
            let address = PaymentSheet.Address(
                city: a.city?.text,
                country: a.selectedCountryCode,
                line1: a.line1?.text,
                line2: a.line2?.text,
                postalCode: a.postalCode?.text,
                state: a.state?.text
            )
            return .init(name: nil, phone: nil, address: address)
        } else {
            return nil
        }
    }
    
    // MARK: - Views
    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(
            isTestMode: configuration.apiClient.isTestmode,
            appearance: configuration.appearance
        )
        navBar.delegate = self
        return navBar
    }()
    lazy var button: ConfirmButton = {
        let button = ConfirmButton(style: .stripe, callToAction: .custom(title: "Continue"), appearance: configuration.appearance) { [weak self] in
            self?.didContinue()
        }
        return button
    }()
    private lazy var headerLabel: UILabel = {
        let header = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        header.text = "Shipping address"
        return header
    }()
    lazy var addressSection: AddressSectionElement = {
        let addressSpecProvider = AddressSpecProvider.shared
        let address = AddressSectionElement(
            title: "",
            addressSpecProvider: addressSpecProvider,
            defaults: nil,
            collectionMode: .all
        )
        address.delegate = self
        return address
    }()
    
    // MARK: - Initializers
    required init(
        configuration: PaymentSheet.Configuration,
        delegate: ShippingAddressViewControllerDelegate
    ) {
        self.configuration = configuration
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        
        // TODO: DRY this
        // Set the current elements theme
        ElementsUITheme.current = configuration.appearance.asElementsTheme
        self.view.backgroundColor = configuration.appearance.colors.background
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        let addressSectionView = addressSection.view
        
        let stackView = UIStackView(arrangedSubviews: [headerLabel, addressSectionView, button])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical

        [stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor, constant: -PaymentSheetUI.defaultSheetMargins.bottom),
        ])
        
        // Disable here?
        button.update(state: .disabled)
    }
}

extension ShippingAddressViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        delegate?.shouldClose(self)
    }
    
    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // TODO
        delegate?.shouldClose(self)
    }
}

extension ShippingAddressViewController: BottomSheetContentViewController {
    var isDismissable: Bool {
        // TODO Remove this property from the protocol, it's unused
        true
    }
    
    var requiresFullScreen: Bool {
        // TODO why use a BottomSheetVC if you are full screen instead of presenting modally?
        false
    }
    
    func didTapOrSwipeToDismiss() {
        delegate?.shouldClose(self)
    }
}

extension ShippingAddressViewController: ElementDelegate {
    func didUpdate(element: Element) {
        let enabled = addressSection.isValidAddress
        button.update(state: enabled ? .enabled : .disabled, animated: true)
    }
    
    func continueToNextField(element: Element) {
        // TODO
    }
    
}

extension ShippingAddressViewController {
    func didContinue() {
        delegate?.shouldClose(self)
    }
}
