//
//  AutoCompleteViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 6/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import MapKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol AutoCompleteViewControllerDelegate: AnyObject {

    /// Called when the user has selected an address from the auto complete suggestions
    /// - Parameter address: The address selected from the search results
    func didSelectAddress(_ address: PaymentSheet.Address?)
    func didSelectManualEntry(_ line1: String)
}

@objc(STP_Internal_AutoCompleteViewController)
class AutoCompleteViewController: UIViewController {
    let configuration: AddressViewController.Configuration
    let initialLine1Text: String?
    let addressSpecProvider: AddressSpecProvider
    private lazy var addressSearchCompleter: MKLocalSearchCompleter = {
       let searchCompleter = MKLocalSearchCompleter()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
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
    private var theme: ElementsAppearance {
        return configuration.appearance.asElementsTheme
    }

    // MARK: - Views
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
        #if !canImport(CompositorServices)
        tableView.keyboardDismissMode = .onDrag
        #endif
        tableView.backgroundColor = configuration.appearance.colors.background
        tableView.separatorColor = configuration.appearance.colors.componentDivider
        tableView.tableFooterView = UIView()
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
        let label = ElementsUI.makeErrorLabel(theme: theme)
        label.isHidden = true
        return label
    }()

    // MARK: - Elements
    lazy var autoCompleteLine: TextFieldElement = {
        let autoCompleteLine = TextFieldElement.Address.makeAutoCompleteLine(defaultValue: initialLine1Text, theme: theme)
        autoCompleteLine.delegate = self
        return autoCompleteLine
    }()
    lazy var lineSection: SectionElement = {
        return SectionElement(elements: [autoCompleteLine], theme: theme)
    }()
    lazy var formElement: FormElement = {
        let form = FormElement(elements: [lineSection], theme: theme)
        form.delegate = self
        return form
    }()

    // MARK: - Initializers
    required init(
        configuration: AddressViewController.Configuration,
        initialLine1Text: String?,
        addressSpecProvider: AddressSpecProvider = .shared
    ) {
        self.configuration = configuration
        self.initialLine1Text = initialLine1Text
        self.addressSpecProvider = addressSpecProvider
        super.init(nibName: nil, bundle: nil)
        if let initialLine1Text = initialLine1Text {
            self.addressSearchCompleter.queryFragment = initialLine1Text
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overrides
    var stackViewBottomConstraint: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background

        let stackView = UIStackView(arrangedSubviews: [formStackView, errorLabel, separatorView, tableView, manualEntryButton])
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical
        stackView.setCustomSpacing(24, after: formStackView) // hardcoded from figma value
        stackView.setCustomSpacing(0, after: separatorView)
        stackView.setCustomSpacing(0, after: tableView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        stackViewBottomConstraint = stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            stackViewBottomConstraint,

            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.33),
            manualEntryButton.heightAnchor.constraint(equalToConstant: manualEntryButton.frame.size.height),
        ])

    }

    private func registerForKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func adjustForKeyboard(notification: Notification) {
        guard
            let keyboardScreenEndFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else {
            return
        }

        view.layoutIfNeeded() // Ensures the view is laid out before animating
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        let keyboardInViewHeight = view.safeAreaLayoutGuide.layoutFrame.intersection(keyboardViewEndFrame).height
        if notification.name == UIResponder.keyboardWillHideNotification {
            stackViewBottomConstraint.constant = 0
        } else {
            stackViewBottomConstraint.constant = -keyboardInViewHeight
        }

        // Animate the container above the keyboard
        view.setNeedsLayout()
        UIView.animateAlongsideKeyboard(notification) {
            self.view.layoutIfNeeded()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications()
        autoCompleteLine.beginEditing()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Private functions
    @objc private func manualEntryButtonTapped() {
        // Populate address with partial for line 1
        delegate?.didSelectManualEntry(autoCompleteLine.text)
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
        results[indexPath.row].asAddress { [weak self] address in
            DispatchQueue.main.async {
                self?.delegate?.didSelectAddress(address)
            }
        }
    }

}
