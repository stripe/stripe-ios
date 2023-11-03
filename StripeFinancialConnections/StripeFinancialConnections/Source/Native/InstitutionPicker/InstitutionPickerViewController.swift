//
//  InstitutionPickerViewController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/7/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol InstitutionPickerViewControllerDelegate: AnyObject {
    func institutionPickerViewController(
        _ viewController: InstitutionPickerViewController,
        didSelect institution: FinancialConnectionsInstitution
    )
    func institutionPickerViewControllerDidSelectManuallyAddYourAccount(
        _ viewController: InstitutionPickerViewController
    )
    func institutionPickerViewControllerDidSearch(
        _ viewController: InstitutionPickerViewController
    )
}

class InstitutionPickerViewController: UIViewController {

    // MARK: - Properties

    private let dataSource: InstitutionDataSource
    weak var delegate: InstitutionPickerViewControllerDelegate?

    private lazy var loadingView: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .large)
        activityIndicator.color = .textDisabled
        activityIndicator.backgroundColor = .customBackgroundColor
        return activityIndicator
    }()
    private lazy var searchBar: InstitutionSearchBar = {
        let searchBar = InstitutionSearchBar()
        searchBar.delegate = self
        return searchBar
    }()
    private lazy var contentContainerView: UIView = {
        let contentContainerView = UIView()
        contentContainerView.backgroundColor = .clear
        return contentContainerView
    }()
    private lazy var featuredInstitutionGridView: FeaturedInstitutionGridView = {
        let featuredInstitutionGridView = FeaturedInstitutionGridView()
        featuredInstitutionGridView.delegate = self
        return featuredInstitutionGridView
    }()
    private lazy var institutionSearchTableView: InstitutionSearchTableView = {
        let institutionSearchTableView = InstitutionSearchTableView(
            frame: view.bounds,
            allowManualEntry: dataSource.manifest.allowManualEntry
        )
        institutionSearchTableView.delegate = self
        return institutionSearchTableView
    }()

    // MARK: - Debouncing Support

    private var fetchInstitutionsDispatchWorkItem: DispatchWorkItem?
    private var lastInstitutionSearchFetchDate = Date()

    // MARK: - Init

    init(dataSource: InstitutionDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()

        showLoadingView(true)
        fetchFeaturedInstitutions { [weak self] in
            self?.showLoadingView(false)
        }
    }

    private func setupView() {
        view.backgroundColor = UIColor.customBackgroundColor

        view.addAndPinSubview(loadingView)
        view.addAndPinSubviewToSafeArea(
            createMainView(
                searchBar: (dataSource.manifest.institutionSearchDisabled == true) ? nil : searchBar,
                contentContainerView: contentContainerView
            )
        )
        contentContainerView.addAndPinSubview(featuredInstitutionGridView)
        contentContainerView.addAndPinSubview(institutionSearchTableView)

        toggleContentContainerViewVisbility()

        let dismissSearchBarTapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapOutsideOfSearchBar)
        )
        dismissSearchBarTapGestureRecognizer.delegate = self
        view.addGestureRecognizer(dismissSearchBarTapGestureRecognizer)
    }

    private func toggleContentContainerViewVisbility() {
        let isUserCurrentlySearching = !searchBar.text.isEmpty
        featuredInstitutionGridView.isHidden = isUserCurrentlySearching
        institutionSearchTableView.isHidden = !featuredInstitutionGridView.isHidden
    }

    @IBAction private func didTapOutsideOfSearchBar() {
        searchBar.resignFirstResponder()
    }

    private func didSelectInstitution(_ institution: FinancialConnectionsInstitution) {
        searchBar.resignFirstResponder()
        // clear search results
        searchBar.text = ""
        institutionSearchTableView.loadInstitutions([])
        toggleContentContainerViewVisbility()
        delegate?.institutionPickerViewController(self, didSelect: institution)
    }

    private func showLoadingView(_ show: Bool) {
        loadingView.isHidden = !show
        if show {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
        view.bringSubviewToFront(loadingView)  // defensive programming to avoid loadingView being hiddden
    }
}

// MARK: - Data

extension InstitutionPickerViewController {

    private func fetchFeaturedInstitutions(completionHandler: @escaping () -> Void) {
        assertMainQueue()
        let fetchStartDate = Date()
        dataSource
            .fetchFeaturedInstitutions()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let institutions):
                    self.dataSource
                        .analyticsClient
                        .log(
                            eventName: "search.feature_institutions_loaded",
                            parameters: [
                                "institutions": institutions.map({ $0.id }),
                                "result_count": institutions.count,
                                "duration": Date().timeIntervalSince(fetchStartDate).milliseconds,
                            ],
                            pane: .institutionPicker
                        )
                    self.featuredInstitutionGridView.loadInstitutions(institutions)
                    self.dataSource
                        .analyticsClient
                        .logPaneLoaded(pane: .institutionPicker)
                case .failure(let error):
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "FeaturedInstitutionsError",
                            pane: .institutionPicker
                        )
                }
                completionHandler()
            }
    }

    private func fetchInstitutions(searchQuery: String) {
        fetchInstitutionsDispatchWorkItem?.cancel()
        institutionSearchTableView.showError(false)

        guard !searchQuery.isEmpty else {
            searchBar.updateSearchingIndicator(false)
            // clear data because search query is empty
            institutionSearchTableView.loadInstitutions([])
            return
        }

        searchBar.updateSearchingIndicator(true)
        let newFetchInstitutionsDispatchWorkItem = DispatchWorkItem(block: { [weak self] in
            guard let self = self else { return }

            let lastInstitutionSearchFetchDate = Date()
            self.lastInstitutionSearchFetchDate = lastInstitutionSearchFetchDate
            self.dataSource
                .fetchInstitutions(searchQuery: searchQuery)
                .observe(on: DispatchQueue.main) { [weak self] result in
                    guard let self = self else { return }
                    guard lastInstitutionSearchFetchDate == self.lastInstitutionSearchFetchDate else {
                        // ignore any search result that came before
                        // the lastest search attempt
                        return
                    }
                    switch result {
                    case .success(let institutionList):
                        self.institutionSearchTableView.loadInstitutions(
                            institutionList.data,
                            showManualEntry: institutionList.showManualEntry
                        )
                        self.dataSource
                            .analyticsClient
                            .log(
                                eventName: "search.succeeded",
                                parameters: [
                                    "query": searchQuery,
                                    "duration": Date().timeIntervalSince(lastInstitutionSearchFetchDate).milliseconds,
                                    "result_count": institutionList.data.count,
                                ],
                                pane: .institutionPicker
                            )
                        self.delegate?.institutionPickerViewControllerDidSearch(self)
                    case .failure(let error):
                        self.institutionSearchTableView.loadInstitutions([])
                        self.institutionSearchTableView.showError(true)

                        if
                            let error = error as? StripeError,
                            case .apiError(let apiError) = error,
                            apiError.type == .invalidRequestError,
                            apiError.param == "client_secret",
                            (apiError.message ?? "").contains("expired")
                        {
                            // Do not log for this case.
                            //
                            // This code fixes a a weird logging edge-case:
                            // 1. Type an invalid keyword ("abcde") in the search that iOS
                            //    will auto-correct
                            // 2. While keyboard is still presented press to enter manual entry
                            // 3. If merchant has manual entry handoff, we will call
                            //    complete API but another search call will execute
                            //    due to iOS auto-correct, which will fail because
                            //    session is completed.
                        } else {
                            self.dataSource
                                .analyticsClient
                                .logUnexpectedError(
                                    error,
                                    errorName: "SearchInstitutionsError",
                                    pane: .institutionPicker
                                )
                        }
                    }
                    self.searchBar.updateSearchingIndicator(false)
                }
        })
        self.fetchInstitutionsDispatchWorkItem = newFetchInstitutionsDispatchWorkItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Constants.queryDelay,
            execute: newFetchInstitutionsDispatchWorkItem
        )
    }
}

// MARK: - InstitutioNSearchBarDelegate

extension InstitutionPickerViewController: InstitutionSearchBarDelegate {

    func institutionSearchBar(_ searchBar: InstitutionSearchBar, didChangeText text: String) {
        toggleContentContainerViewVisbility()
        fetchInstitutions(searchQuery: text)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension InstitutionPickerViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchPoint = touch.location(in: view)
        return !searchBar.frame.contains(touchPoint) && !contentContainerView.frame.contains(touchPoint)
    }
}

// MARK: - FeaturedInstitutionGridViewDelegate

extension InstitutionPickerViewController: FeaturedInstitutionGridViewDelegate {

    func featuredInstitutionGridView(
        _ view: FeaturedInstitutionGridView,
        didSelectInstitution institution: FinancialConnectionsInstitution
    ) {
        dataSource.analyticsClient.log(
            eventName: "search.featured_institution_selected",
            parameters: [
                "institution_id": institution.id,
            ],
            pane: .institutionPicker
        )
        didSelectInstitution(institution)
    }
}

// MARK: - InstitutionSearchTableViewDelegate

extension InstitutionPickerViewController: InstitutionSearchTableViewDelegate {

    func institutionSearchTableView(
        _ tableView: InstitutionSearchTableView,
        didSelectInstitution institution: FinancialConnectionsInstitution
    ) {
        dataSource.analyticsClient.log(
            eventName: "search.search_result_selected",
            parameters: [
                "institution_id": institution.id,
            ],
            pane: .institutionPicker
        )
        didSelectInstitution(institution)
    }

    func institutionSearchTableView(
        _ tableView: InstitutionSearchTableView,
        didSelectManuallyAddYourAccountWithInstitutions institutions: [FinancialConnectionsInstitution]
    ) {
        dataSource
            .analyticsClient
            .log(
                eventName: "click.manual_entry",
                parameters: [
                    "institution_ids": institutions.map({ $0.id }),
                ],
                pane: .institutionPicker
            )
        delegate?.institutionPickerViewControllerDidSelectManuallyAddYourAccount(self)
    }

    func institutionSearchTableView(
        _ tableView: InstitutionSearchTableView,
        didScrollInstitutions institutions: [FinancialConnectionsInstitution]
    ) {
        dataSource
            .analyticsClient
            .log(
                eventName: "search.scroll",
                parameters: [
                    "institution_ids": institutions.map({ $0.id }),
                ],
                pane: .institutionPicker
            )
    }
}

// MARK: - Constants

extension InstitutionPickerViewController {
    enum Constants {
        static let queryDelay = TimeInterval(0.2)
    }
}

// MARK: - Helpers

private func createMainView(
    searchBar: UIView?,
    contentContainerView: UIView
) -> UIView {
    let verticalStackView = UIStackView(
        arrangedSubviews: [
            createHeaderView(
                searchBar: searchBar
            ),
            contentContainerView,
        ]
    )
    verticalStackView.axis = .vertical
    verticalStackView.spacing = (searchBar == nil) ? 24 : 16
    return verticalStackView
}

private func createHeaderView(
    searchBar: UIView?
) -> UIView {
    let verticalStackView = UIStackView(
        arrangedSubviews: [
            createHeaderTitleLabel(),
        ]
    )
    if let searchBar = searchBar {
        verticalStackView.addArrangedSubview(searchBar)
    }
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 24
    verticalStackView.isLayoutMarginsRelativeArrangement = true
    verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 8,
        leading: 24,
        bottom: 0,
        trailing: 24
    )
    return verticalStackView
}

private func createHeaderTitleLabel() -> UIView {
    let headerTitleLabel = AttributedLabel(
        font: .heading(.large),
        textColor: .textPrimary
    )
    headerTitleLabel.setText(
        STPLocalizedString(
            "Select your bank",
            "The title of the 'Institution Picker' screen where users get to select an institution (ex. a bank like Bank of America)."
        )
    )
    return headerTitleLabel
}
