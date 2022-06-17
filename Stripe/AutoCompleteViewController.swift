//
//  AutoCompleteViewController.swift
//  StripeiOS
//
//  Created by Nick Porter on 6/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
import MapKit
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
    private lazy var addressSearchCompleter: MKLocalSearchCompleter = {
       let searchCompleter = MKLocalSearchCompleter()
        searchCompleter.delegate = self
        if #available(iOS 13.0, *) {
            searchCompleter.resultTypes = .address
        }
        return searchCompleter
    }()
    
    weak var delegate: AutoCompleteViewControllerDelegate?
    
    private let cellReuseIdentifier = "autoCompleteCell"
    var results: [AddressSearchResult] = [] {
        didSet {
            separatorView.isHidden = results.isEmpty
            tableView.reloadData()
            latestError = nil // reset latest error whenever we get new results
        }
    }
    
    private var latestError: Error? {
        didSet {
            errorLabel.text = latestError?.localizedDescription
            errorLabel.isHidden = latestError == nil
        }
    }
    
    // MARK: - Views
    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(
            isTestMode: configuration.apiClient.isTestmode,
            appearance: configuration.appearance
        )
        navBar.setStyle(.back)
        navBar.delegate = self
        return navBar
    }()
    lazy var formView: UIView = {
        return formElement.view
    }()
    lazy var formStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [formView])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        
        return stackView
    }()
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = configuration.appearance.colors.background
        tableView.separatorColor = configuration.appearance.colors.componentDivider
        tableView.tableFooterView = UIView()
        // TODO(porter) Left align cell labels with left of address search bar
        return tableView
    }()
    lazy var manualEntryButton: UIButton = {
        let button = UIButton.makeManualEntryButton(appearance: configuration.appearance)
        button.addTarget(self, action: #selector(manualEntryButtonTapped), for: .touchUpInside)
        return button
    }()
    lazy var separatorView: UIView = {
       let view = UIView()
        view.backgroundColor = configuration.appearance.colors.componentDivider
        view.isHidden = true
        return view
    }()
    lazy var errorLabel: UILabel = {
        let label = ElementsUI.makeErrorLabel()
        label.isHidden = true
        return label
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
        
        let stackView = UIStackView(arrangedSubviews: [formStackView, errorLabel, separatorView, tableView, manualEntryButton])
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical
        stackView.setCustomSpacing(24, after: formStackView) // hardcoded from figma value
        stackView.setCustomSpacing(0, after: separatorView)
        stackView.setCustomSpacing(0, after: tableView)
        
        [stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.33),
            manualEntryButton.heightAnchor.constraint(equalToConstant: manualEntryButton.frame.size.height)
        ])
    }
     
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
        addressSearchCompleter.queryFragment = autoCompleteLine.text
    }
    
    func continueToNextField(element: Element) {
        // no-op
    }
}

// MARK: MKLocalSearchCompleterDelegate
extension AutoCompleteViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.results = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        let nsError = error as NSError
        
        // Making a query with an empty string causes a server error and doesn't update search results
        if completer.queryFragment.isEmpty && nsError.code == MKError.serverFailure.rawValue {
            results.removeAll()
            return
        }
        
        self.latestError = error
    }
}

// MARK: TableView
extension AutoCompleteViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) ??
             UITableViewCell(style: .subtitle, reuseIdentifier: cellReuseIdentifier)
        cell.backgroundColor = configuration.appearance.colors.background

        let result = results[indexPath.row]
        cell.textLabel?.attributedText = result.title.highlightSearchString(highlightRanges: result.titleHighlightRanges,
                                                                            textStyle: .subheadline,
                                                                            appearance: configuration.appearance,
                                                                             isSubtitle: false)

        cell.detailTextLabel?.attributedText = result.subtitle.highlightSearchString(highlightRanges: result.subtitleHighlightRanges,
                                                                            textStyle: .footnote,
                                                                            appearance: configuration.appearance,
                                                                            isSubtitle: true)
        cell.indentationWidth = 5 // hardcoded value to align with searchbar textfield

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        results[indexPath.row].asAddress { address in
            DispatchQueue.main.async {
                self.dismiss(animated: true)
                self.delegate?.didDismiss(with: address)
            }
        }
    }
    
}
