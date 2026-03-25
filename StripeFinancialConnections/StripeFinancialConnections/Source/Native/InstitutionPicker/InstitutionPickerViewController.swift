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
    func institutionPickerViewController(
        _ viewController: InstitutionPickerViewController,
        didFinishSelecting institution: FinancialConnectionsInstitution,
        authSession: FinancialConnectionsAuthSession
    )
    func institutionPickerViewController(
        _ viewController: InstitutionPickerViewController,
        didFinishSelecting institution: FinancialConnectionsInstitution,
        payload: FinancialConnectionsSelectInstitution
    )
    func institutionPickerViewControllerDidSelectManuallyAddYourAccount(
        _ viewController: InstitutionPickerViewController
    )
    func institutionPickerViewControllerDidSearch(
        _ viewController: InstitutionPickerViewController
    )
    func institutionPickerViewController(
        _ viewController: InstitutionPickerViewController,
        didReceiveError error: Error
    )
}

class InstitutionPickerViewController: UIViewController {

    private static let headerAndSearchBarSpacing: CGFloat = 24

    // MARK: - Properties

    private let dataSource: InstitutionDataSource
    weak var delegate: InstitutionPickerViewControllerDelegate?

    private var shadowLayer: CALayer?

    private lazy var headerView: UIView = {
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreateHeaderTitleLabel(),
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 16,
            leading: Constants.Layout.defaultHorizontalMargin,
            bottom: Self.headerAndSearchBarSpacing,
            trailing: Constants.Layout.defaultHorizontalMargin
        )
        verticalStackView.backgroundColor = FinancialConnectionsAppearance.Colors.background
        return verticalStackView
    }()
    private lazy var searchBarContainerView: UIView = {
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                searchBar,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0, // the `headerView` has bottom padding
            leading: Constants.Layout.defaultHorizontalMargin,
            bottom: 16,
            trailing: Constants.Layout.defaultHorizontalMargin
        )
        verticalStackView.backgroundColor = FinancialConnectionsAppearance.Colors.background
        // the "shadow" fixes an issue where the "search bar sticky header"
        // has a visible 1 pixel gap. the shadow is not actually a shadow,
        // but rather a "top border"
        verticalStackView.layer.shadowOpacity = 1.0
        verticalStackView.layer.shadowColor = verticalStackView.backgroundColor?.cgColor
        verticalStackView.layer.shadowRadius = 0
        verticalStackView.layer.shadowOffset = CGSize(
            width: 0,
            // the `height` is greater than 1 px because this also fixes
            // an issue where the sticky header animates to final position
            // (this is default iOS/UITableView behavior), and the animation
            // is slow, which can cause the institution cells to temporarily
            // appear IF the user scrolls up very quickly
            height: -Self.headerAndSearchBarSpacing
        )
        self.shadowLayer = verticalStackView.layer
        return verticalStackView
    }()
    private lazy var searchBar: InstitutionSearchBar = {
        let searchBar = InstitutionSearchBar(appearance: dataSource.manifest.appearance)
        searchBar.delegate = self
        return searchBar
    }()
    private lazy var institutionTableView: InstitutionTableView = {
        let institutionTableView = InstitutionTableView(
            frame: view.bounds,
            allowManualEntry: dataSource.manifest.allowManualEntry,
            institutionSearchDisabled: dataSource.manifest.institutionSearchDisabled,
            appearance: dataSource.manifest.appearance
        )
        institutionTableView.delegate = self
        return institutionTableView
    }()
    private var isUserCurrentlySearching: Bool {
        return !searchBar.text.isEmpty
    }

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
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background

        view.addAndPinSubview(institutionTableView)
        institutionTableView.setTableHeaderView(headerView)
        if !dataSource.manifest.institutionSearchDisabled {
            institutionTableView.searchBarContainerView = searchBarContainerView
        }

        let dismissSearchBarTapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapOutsideOfSearchBar)
        )
        dismissSearchBarTapGestureRecognizer.cancelsTouchesInView = false
        dismissSearchBarTapGestureRecognizer.delegate = self
        view.addGestureRecognizer(dismissSearchBarTapGestureRecognizer)
    }

    @IBAction private func didTapOutsideOfSearchBar() {
        searchBar.resignFirstResponder()
    }

    private func didSelectInstitution(_ institution: FinancialConnectionsInstitution) {
        FeedbackGeneratorAdapter.selectionChanged()
        delegate?.institutionPickerViewController(self, didSelect: institution)

        searchBar.resignFirstResponder()

        let showLoadingView: (Bool) -> Void = { [weak self] show in
            guard let self else { return }
            self.view.isUserInteractionEnabled = !show // prevent accidental taps
            self.institutionTableView.showLoadingView(show, forInstitution: institution)
        }

        showLoadingView(true)
        institutionTableView.showOverlayView(
            true,
            exceptForInstitution: institution
        )

        // If consent is already acquired, create an auth session.
        // Otherwise, select the institution and update the manifest.
        if dataSource.manifest.consentAcquired {
            createAuthSession(institution) {
                showLoadingView(false)
            }
        } else {
            selectInstitution(institution) {
                showLoadingView(false)
            }
        }
    }

    private func createAuthSession(
        _ institution: FinancialConnectionsInstitution,
        completion: @escaping () -> Void
    ) {
        dataSource.createAuthSession(institutionId: institution.id)
            .observe { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let authSession):
                    self.delegate?.institutionPickerViewController(
                        self,
                        didFinishSelecting: institution,
                        authSession: authSession
                    )

                    if authSession.isOauthNonOptional {
                        // oauth presents a sheet where we do not hide
                        // the overlay until the sheet is dismissed
                        self.observePartnerAuthDismissToHideOverlay()
                    } else {
                        self.hideOverlayView()
                    }
                case .failure(let error):
                    self.delegate?.institutionPickerViewController(
                        self,
                        didReceiveError: error
                    )
                }
                completion()
            }
    }

    private func selectInstitution(
        _ institution: FinancialConnectionsInstitution,
        completion: @escaping () -> Void
    ) {
        dataSource.selectInstitution(institutionId: institution.id)
            .observe { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let selectInstitutionPayload):
                    self.delegate?.institutionPickerViewController(
                        self,
                        didFinishSelecting: institution,
                        payload: selectInstitutionPayload
                    )
                    self.hideOverlayView()
                case .failure(let error):
                    self.delegate?.institutionPickerViewController(
                        self,
                        didReceiveError: error
                    )
                }
                completion()
            }
    }

    private func showLoadingView(_ show: Bool) {
        institutionTableView.showLoadingView(show)
    }

    private var partnerAuthDismissObserver: Any?
    private func observePartnerAuthDismissToHideOverlay() {
        partnerAuthDismissObserver = NotificationCenter.default.addObserver(
            forName: .sheetViewControllerWillDismiss,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let self else { return }
            guard notification.object is PartnerAuthViewController else {
                return
            }
            self.hideOverlayView()
            self.partnerAuthDismissObserver = nil
        }
    }

    private func hideOverlayView() {
        institutionTableView.showOverlayView(false)
    }

    private func scrollToTopOfSearchBar() {
        let searchBarContainerFrame = CGRect(
            x: 0,
            y: headerView.frame.maxY,
            width: institutionTableView.tableView.bounds.width,
            height: searchBarContainerView.frame.height
        )
        institutionTableView.tableView.scrollRectToVisible(
            searchBarContainerFrame,
            animated: true
        )
    }

    // CGColor's need to be manually updated when the system theme changes.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        shadowLayer?.shadowColor = FinancialConnectionsAppearance.Colors.background.cgColor
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

                    self.institutionTableView.load(
                        institutions: institutions,
                        isUserSearching: false
                    )
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
        institutionTableView.showError(false, isUserSearching: true)

        guard !searchQuery.isEmpty else {
            showLoadingView(false)
            // clear data because search query is empty
            institutionTableView.load(
                institutions: dataSource.featuredInstitutions,
                isUserSearching: false
            )
            return
        }

        showLoadingView(true)
        scrollToTopOfSearchBar()
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
                        if self.isUserCurrentlySearching {
                            // only load the institutions IF the user has text in search box
                            self.institutionTableView.load(
                                institutions: institutionList.data,
                                isUserSearching: true,
                                showManualEntry: institutionList.showManualEntry
                            )
                        } else {
                            self.institutionTableView.load(
                                institutions: self.dataSource.featuredInstitutions,
                                isUserSearching: false,
                                showManualEntry: institutionList.showManualEntry
                            )
                        }
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
                        self.institutionTableView.load(
                            institutions: [],
                            isUserSearching: false
                        )
                        self.institutionTableView.showError(true, isUserSearching: false)

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
                    self.showLoadingView(false)
                }
        })
        self.fetchInstitutionsDispatchWorkItem = newFetchInstitutionsDispatchWorkItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + TimeInterval(0.2),
            execute: newFetchInstitutionsDispatchWorkItem
        )
    }
}

// MARK: - InstitutioNSearchBarDelegate

extension InstitutionPickerViewController: InstitutionSearchBarDelegate {

    func institutionSearchBar(_ searchBar: InstitutionSearchBar, didChangeText text: String) {
        fetchInstitutions(searchQuery: text)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension InstitutionPickerViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        let scrollView = institutionTableView.tableView
        let isTableViewScrolledToTop = scrollView.contentOffset.y <= -scrollView.contentInset.top
        guard isTableViewScrolledToTop else {
            // only consider `dismissSearchBarTapGestureRecognizer` when the
            // table view is scrolled to the top
            //
            // because the dismiss functionality is purely optional, and because frame
            // calculation gets complicated in a scroll view, this logic helps
            // to keep the calculations simple so we avoid unintentionally
            // blocking user interaction
            return false
        }
        let touchPoint = touch.location(in: view)
        return headerView.frame.contains(touchPoint) && !searchBar.frame.contains(touchPoint)
    }
}

// MARK: - InstitutionTableViewDelegate

extension InstitutionPickerViewController: InstitutionTableViewDelegate {

    func institutionTableView(
        _ tableView: InstitutionTableView,
        didSelectInstitution institution: FinancialConnectionsInstitution
    ) {
        if isUserCurrentlySearching {
            dataSource.analyticsClient.log(
                eventName: "search.search_result_selected",
                parameters: [
                    "institution_id": institution.id,
                ],
                pane: .institutionPicker
            )
        } else {
            dataSource.analyticsClient.log(
                eventName: "search.featured_institution_selected",
                parameters: [
                    "institution_id": institution.id,
                ],
                pane: .institutionPicker
            )
        }
        didSelectInstitution(institution)
    }

    func institutionTableViewDidSelectSearchForMoreBanks(_ tableView: InstitutionTableView) {
        scrollToTopOfSearchBar()
        searchBar.becomeFirstResponder()
    }

    func institutionTableView(
        _ tableView: InstitutionTableView,
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

    func institutionTableView(
        _ tableView: InstitutionTableView,
        didScrollInstitutions institutions: [FinancialConnectionsInstitution]
    ) {
        if isUserCurrentlySearching {
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
}

// MARK: - Helpers

private func CreateHeaderTitleLabel() -> UIView {
    let headerTitleLabel = AttributedLabel(
        font: .heading(.extraLarge),
        textColor: FinancialConnectionsAppearance.Colors.textDefault
    )
    headerTitleLabel.setText(
        STPLocalizedString(
            "Select bank",
            "The title of the 'Institution Picker' screen where users get to select an institution (ex. a bank like Bank of America)."
        )
    )
    return headerTitleLabel
}
