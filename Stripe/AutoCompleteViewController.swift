//
//  AutoCompleteViewController.swift
//  StripeiOS
//
//  Created by Nick Porter on 6/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol AutoCompleteViewControllerDelegate: AnyObject {
    
    /// Called when the `AutoCompleteViewController` has dismissed
    /// - Parameter address: If `address` is non-nil it has been selected by the user, otherwise nil when no selection was made
    func didDismiss(with address: PaymentSheet.Address?)
}

@objc(STP_Internal_AutoCompleteViewController)
class AutoCompleteViewController: UIViewController {
    let configuration: PaymentSheet.Configuration
    let addressSpecProvider: AddressSpecProvider
    
    weak var delegate: AutoCompleteViewControllerDelegate?
    
    private let cellReuseIdentifier = "autoCompleteCell"
    
    // MARK: - Views
    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(
            isTestMode: configuration.apiClient.isTestmode,
            appearance: configuration.appearance
        )
        navBar.delegate = self
        return navBar
    }()
    private lazy var headerLabel: UILabel = {
        let header = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        header.text = .Localized.shipping_address
        return header
    }()
    lazy var formView: UIView = {
        return formElement.view
    }()
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        return tableView
    }()
    lazy var manualEntryButton: UIButton = {
        let button = UIButton.makeManualEntryButton(appearance: configuration.appearance)
        button.addTarget(self, action: #selector(manualEntryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Elements
    lazy var autoCompleteLine: TextFieldElement = {
        let autoCompleteLine = TextFieldElement.Address.makeAutoCompleteLine()
        autoCompleteLine.delegate = self
        return autoCompleteLine
    }()
    lazy var lineSection: SectionElement = {
        return SectionElement(elements: [autoCompleteLine])
    }()
    lazy var formElement: FormElement = {
        let form = FormElement(elements: [lineSection])
        form.delegate = self
        return form
    }()
    
    // MARK: - Initializers
    required init(
        configuration: PaymentSheet.Configuration,
        addressSpecProvider: AddressSpecProvider = .shared
    ) {
        self.configuration = configuration
        self.addressSpecProvider = addressSpecProvider
        super.init(nibName: nil, bundle: nil)
        
        // Set the current elements theme
        ElementsUITheme.current = configuration.appearance.asElementsTheme
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background
        autoCompleteLine.inputAccessoryView = manualEntryButton
        
        let stackView = UIStackView(arrangedSubviews: [headerLabel, formView, tableView])
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
            tableView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.75)
        ])
    }

    // MARK: Overrides
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoCompleteLine.beginEditing()
    }
    
    // MARK: Private functions
    @objc private func manualEntryButtonTapped() {
        self.dismiss(animated: true)
        // Populate address with partial for line 1
        let address = PaymentSheet.Address(city: nil, country: nil, line1: autoCompleteLine.text, line2: nil, postalCode: nil, state: nil)
        delegate?.didDismiss(with: address)
    }
}

// MARK: - SheetNavigationBarDelegate
extension AutoCompleteViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        self.dismiss(animated: true)
        delegate?.didDismiss(with: nil)
    }
    
    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        self.dismiss(animated: true)
        delegate?.didDismiss(with: nil)
    }
}

// MARK: - BottomSheetContentViewController
extension AutoCompleteViewController: BottomSheetContentViewController {
    var requiresFullScreen: Bool {
        return true
    }
    
    func didTapOrSwipeToDismiss() {
        self.dismiss(animated: true)
        delegate?.didDismiss(with: nil)
    }
}

// MARK: ElementDelegate
extension AutoCompleteViewController: ElementDelegate {
    func didUpdate(element: Element) {
        // TODO(porter) Kick off API request
        print("didUpdate with search text \(String(describing: autoCompleteLine.text))")
    }
    
    func continueToNextField(element: Element) {
        // no-op
    }
}

// MARK: TableView
extension AutoCompleteViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        cell.textLabel?.text = "test"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Did select row \(indexPath.row)")
    }
    
}
