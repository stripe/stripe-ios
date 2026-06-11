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
    /// Vertical offset for the view controller content. Negative values move content up, positive values move content down.
    let verticalOffset: CGFloat
    /// Session token for grouping autocomplete and place details calls.
    let sessionToken: String = UUID().uuidString

    private let indendationWidth: CGFloat = 5
    private lazy var addressSearchCompleter: MKLocalSearchCompleter = {
       let searchCompleter = MKLocalSearchCompleter()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
        return searchCompleter
    }()

    private var fetchTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    private var lastFetchedQuery: String = ""
    var currentSource: String?
    private var autocompleteStartTime: Date?
    private var mapKitQueryStartTime: Date?

    weak var delegate: AutoCompleteViewControllerDelegate?

    private let cellReuseIdentifier = "autoCompleteCell"
    var results: [AddressSearchResult] = [] {
        didSet {
            separatorView.isHidden = results.isEmpty
            tableView.reloadData()
            let showGoogleAttribution = !results.isEmpty && currentSource?.lowercased() == "google"
            tableView.tableFooterView = showGoogleAttribution ? googleAttributionFooterView : nil
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
        stackView.directionalLayoutMargins = configuration.appearance.topFormInsets
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical

        return stackView
    }()
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        #if !os(visionOS)
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
    lazy var googleAttributionFooterView: UIView = {
        let image = Image.google_maps_mark.makeImage()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(imageView)

        var constraints = [
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: tableView.layoutMargins.left + indendationWidth),
            imageView.heightAnchor.constraint(equalToConstant: 16),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: image.size.width / image.size.height),
            imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
        ]
        NSLayoutConstraint.activate(constraints)
        return container
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

    /// The country code selected in the address form's country dropdown, used to narrow autocomplete results.
    let selectedCountry: String?

    // MARK: - Initializers
    required init(
        configuration: AddressViewController.Configuration,
        initialLine1Text: String?,
        selectedCountry: String?,
        addressSpecProvider: AddressSpecProvider = .shared,
        verticalOffset: CGFloat = 0
    ) {
        self.configuration = configuration
        self.initialLine1Text = initialLine1Text
        self.selectedCountry = selectedCountry
        self.addressSpecProvider = addressSpecProvider
        self.verticalOffset = verticalOffset
        super.init(nibName: nil, bundle: nil)
        if let initialLine1Text = initialLine1Text, !initialLine1Text.isEmpty {
            if configuration.useAutocompleteEndpoints {
                fetchAPIResults(query: initialLine1Text)
            } else {
                mapKitQueryStartTime = Date()
                self.addressSearchCompleter.queryFragment = initialLine1Text
            }
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

        let buttonContainer = UIView()
        buttonContainer.addAndPinSubview(manualEntryButton, insets: NSDirectionalEdgeInsets(top: 0, leading: configuration.appearance.formInsets.leading, bottom: 8, trailing: configuration.appearance.formInsets.trailing))
        buttonContainer.addSubview(manualEntryButton)
        manualEntryButton.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [formStackView, errorLabel, separatorView, tableView])
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical
        stackView.setCustomSpacing(24, after: formStackView) // hardcoded from figma value
        stackView.setCustomSpacing(0, after: separatorView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        view.addSubview(buttonContainer)

        buttonContainer.translatesAutoresizingMaskIntoConstraints = false

        stackViewBottomConstraint = stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            stackViewBottomConstraint,

            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: verticalOffset),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.33),

            buttonContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            buttonContainer.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),

            manualEntryButton.heightAnchor.constraint(equalToConstant: manualEntryButton.frame.size.height),
        ])

        // Set up proper content inset for table view after layout
        view.layoutIfNeeded()
        updateTableViewInsets()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableViewInsets()
    }

    private func updateTableViewInsets() {
        // Add bottom content inset to tableview to account for floating button
        let buttonHeight = manualEntryButton.frame.height + 16
        tableView.contentInset.bottom = buttonHeight
        tableView.verticalScrollIndicatorInsets.bottom = buttonHeight
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
        autocompleteStartTime = Date()
        STPAnalyticsClient.sharedClient.logAddressAutocompleteStart(apiClient: configuration.apiClient)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Private functions

    /// Sets source and results together so `results.didSet` always sees the correct source.
    private func setResults(_ newResults: [AddressSearchResult], source: String?, requestLatency: TimeInterval? = nil) {
        currentSource = source
        results = newResults
        if let source {
            STPAnalyticsClient.sharedClient.logAddressAutocompleteSuggestions(
                characterCount: autoCompleteLine.text.count,
                sessionToken: sessionToken,
                source: source,
                duration: elapsedTimeSinceAutocompleteStart,
                latency: requestLatency,
                apiClient: configuration.apiClient
            )
        }
    }

    private var elapsedTimeSinceAutocompleteStart: TimeInterval {
        guard let startTime = autocompleteStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }

    @objc private func manualEntryButtonTapped() {
        // Populate address with partial for line 1
        delegate?.didSelectManualEntry(autoCompleteLine.text)
    }
}

// MARK: ElementDelegate
extension AutoCompleteViewController: ElementDelegate {
    func didUpdate(element: Element) {
        let query = autoCompleteLine.text
        if configuration.useAutocompleteEndpoints {
            guard query != lastFetchedQuery else { return }
            lastFetchedQuery = query
            guard query.count >= 2 else {
                debounceTask?.cancel()
                fetchTask?.cancel()
                setResults([], source: nil)
                return
            }
            debounceTask?.cancel()
            debounceTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard !Task.isCancelled else { return }
                fetchAPIResults(query: query)
            }
        } else if !query.isEmpty {
            mapKitQueryStartTime = Date()
            addressSearchCompleter.queryFragment = query
        }
    }

    func continueToNextField(element: Element) {
        // no-op
    }

    private func fetchAPIResults(query: String) {
        fetchTask?.cancel()
        fetchTask = Task { @MainActor in
            do {
                let countryCodes = selectedCountry.flatMap { $0.isEmpty ? nil : [$0] }
                let requestStart = Date()
                let response = try await configuration.apiClient.getAddressSuggestions(
                    searchText: query,
                    countryCodes: countryCodes,
                    sessionToken: sessionToken
                )
                guard !Task.isCancelled else { return }
                let latency = Date().timeIntervalSince(requestStart)
                self.setResults(response.suggestions, source: response.source, requestLatency: latency)
            } catch {
                guard !Task.isCancelled else { return }
                STPAnalyticsClient.sharedClient.logAddressAutocompleteError(
                    error: error,
                    sessionToken: self.sessionToken,
                    duration: self.elapsedTimeSinceAutocompleteStart,
                    apiClient: self.configuration.apiClient
                )
                // Fall back to MapKit on API failure
                self.mapKitQueryStartTime = Date()
                self.addressSearchCompleter.queryFragment = query
            }
        }
    }
}

// MARK: MKLocalSearchCompleterDelegate
extension AutoCompleteViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        var latency: TimeInterval?
        if let mapKitQueryStartTime {
            latency = Date().timeIntervalSince(mapKitQueryStartTime)
        }
        setResults(completer.results, source: "apple", requestLatency: latency)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        let nsError = error as NSError

        // Making a query with an empty string causes a server error and doesn't update search results
        if completer.queryFragment.isEmpty && nsError.code == MKError.serverFailure.rawValue {
            setResults([], source: "apple")
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
        cell.indentationWidth = indendationWidth // hardcoded value to align with searchbar textfield

        cell.contentView.directionalLayoutMargins = .insets(
            leading: configuration.appearance.formInsets.leading - indendationWidth, // adjust for the indentation
            trailing: configuration.appearance.formInsets.trailing)
        cell.contentView.preservesSuperviewLayoutMargins = false

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        debounceTask?.cancel()
        fetchTask?.cancel()

        let result = results[indexPath.row]
        let typedText = autoCompleteLine.text
        let characterCount = typedText.count
        let source = currentSource ?? ""
        let duration = elapsedTimeSinceAutocompleteStart

        if let suggestion = result as? AddressSuggestion {
            // If the suggestion returned with a full address, complete with that address
            if let address = suggestion.address {
                STPAnalyticsClient.sharedClient.logAddressAutocompleteComplete(
                    characterCount: characterCount,
                    sessionToken: sessionToken,
                    source: source,
                    duration: duration,
                    latency: nil,
                    apiClient: configuration.apiClient
                )
                delegate?.didSelectAddress(address)
            } else { // If the suggestion did not return with a full address, it must have a place id and source to fetch the address details
                guard let placeId = suggestion.placeId, let currentSource else {
                    delegate?.didSelectAddress(nil)
                    return
                }
                fetchTask = Task { @MainActor [weak self] in
                    guard let self else { return }
                    do {
                        let requestStart = Date()
                        let details = try await configuration.apiClient.getAddressDetails(
                            placeId: placeId,
                            source: currentSource,
                            displayTitle: suggestion.title,
                            sessionToken: sessionToken
                        )
                        let latency = Date().timeIntervalSince(requestStart)
                        STPAnalyticsClient.sharedClient.logAddressAutocompleteComplete(
                            characterCount: characterCount,
                            sessionToken: sessionToken,
                            source: source,
                            duration: duration,
                            latency: latency,
                            apiClient: configuration.apiClient
                        )
                        delegate?.didSelectAddress(details.address)
                    } catch {
                      STPAnalyticsClient.sharedClient.logAddressAutocompleteError(
                            error: error,
                            sessionToken: sessionToken,
                            duration: elapsedTimeSinceAutocompleteStart,
                            apiClient: configuration.apiClient
                        )
                        delegate?.didSelectAddress(nil)
                    }
                }
            }
        } else {
            result.asAddress { [weak self] address in
                DispatchQueue.main.async {
                    guard let self else { return }
                    STPAnalyticsClient.sharedClient.logAddressAutocompleteComplete(
                        characterCount: characterCount,
                        sessionToken: self.sessionToken,
                        source: source,
                        duration: duration,
                        latency: nil,
                        apiClient: self.configuration.apiClient
                    )
                    self.delegate?.didSelectAddress(address)
                }
            }
        }
    }

}
