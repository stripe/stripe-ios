//
//  InstitutionPicker.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/7/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
protocol InstitutionPickerDelegate: AnyObject {
    func institutionPicker(_ picker: InstitutionPicker, didSelect institution: FinancialConnectionsInstitution)
    func institutionPickerDidSelectManuallyAddYourAccount(_ picker: InstitutionPicker)
}

@available(iOSApplicationExtension, unavailable)
class InstitutionPicker: UIViewController {
    
    // MARK: - Properties
    
    private let dataSource: InstitutionDataSource
    
    private lazy var loadingView: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            let activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.color = .textSecondary // set color because we only support light mode
            activityIndicator.startAnimating()
            activityIndicator.backgroundColor = .customBackgroundColor
            return activityIndicator
        } else {
            assertionFailure()
            return UIActivityIndicatorView()
        }
    }()
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal // removes black borders
        if #available(iOS 13.0, *) {
            searchBar.searchTextField.textColor = .textSecondary
            // note that increasing the font also dramatically
            // increases the search box height
            searchBar.searchTextField.font = .stripeFont(forTextStyle: .body)
            // this removes the `searchTextField` background color.
            // for an unknown reason, setting the `backgroundColor` to
            // a white color is a no-op
            searchBar.searchTextField.borderStyle = .none
            // use `NSAttributedString` to be able to change the placeholder color
            searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
                string: "Search",
                attributes: [
                    .foregroundColor: UIColor.textDisabled,
                    .font: UIFont.stripeFont(forTextStyle: .body),
                ]
            )
            // change the search icon color..."maagnifyingglass" is SFSymbols
            let searchIcon = UIImage(systemName: "magnifyingglass")?.withTintColor(.textPrimary, renderingMode: .alwaysOriginal)
            searchBar.setImage(searchIcon, for: .search, state: .normal)
        }
        searchBar.layer.borderWidth = 1
        searchBar.layer.cornerRadius = 8
        searchBar.delegate = self
        return searchBar
    }()
    private lazy var contentContainerView: UIView = {
        let contentContainerView = UIView()
        contentContainerView.backgroundColor = .clear
        return contentContainerView
    }()
    
    @available(iOS 13.0, *)
    private lazy var featuredInstitutionGridView: FeaturedInstitutionGridView = {
        let featuredInstitutionGridView = FeaturedInstitutionGridView()
        featuredInstitutionGridView.delegate = self
        return featuredInstitutionGridView
    }()
    
    @available(iOS 13.0, *)
    private lazy var institutionSearchTableView: InstitutionSearchTableView = {
        let institutionSearchTableView = InstitutionSearchTableView(allowManualEntry: dataSource.manifest.allowManualEntry)
        institutionSearchTableView.delegate = self
        return institutionSearchTableView
    }()
    
    weak var delegate: InstitutionPickerDelegate?
    
    // Only used for iOS12 fallback where we don't ahve the diffable datasource
    private lazy var institutions: [FinancialConnectionsInstitution]? = nil
    
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
            CreateMainView(
                searchView: searchBar,//(dataSource.manifest.institutionSearchDisabled == true) ? nil : searchBar,
                contentContainerView: contentContainerView
            )
        )
        if #available(iOS 13.0, *) {
            contentContainerView.addAndPinSubview(featuredInstitutionGridView)
            contentContainerView.addAndPinSubview(institutionSearchTableView)
        }
        
        toggleContentContainerViewVisbility()
        setSearchBarBorderColor(isHighlighted: false)

        let dismissSearchBarTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOutsideOfSearchBar))
        dismissSearchBarTapGestureRecognizer.delegate = self
        view.addGestureRecognizer(dismissSearchBarTapGestureRecognizer)
    }
    
    private func setSearchBarBorderColor(isHighlighted: Bool) {
        let searchBarBorderColor: UIColor
        if isHighlighted {
            searchBarBorderColor = .textBrand
        } else {
            searchBarBorderColor = .borderNeutral
        }
        searchBar.layer.borderColor = searchBarBorderColor.cgColor
    }
    
    private func toggleContentContainerViewVisbility() {
        if #available(iOS 13.0, *) {
            let isUserCurrentlySearching = searchBar.text?.isEmpty ?? false
            featuredInstitutionGridView.isHidden = !isUserCurrentlySearching
            institutionSearchTableView.isHidden = !featuredInstitutionGridView.isHidden
        }
    }
    
    @IBAction private func didTapOutsideOfSearchBar() {
        searchBar.resignFirstResponder()
    }
    
    private func didSelectInstitution(_ institution: FinancialConnectionsInstitution) {
        searchBar.resignFirstResponder()
        if #available(iOS 13.0, *) {
            // clear search results
            searchBar.text = ""
            institutionSearchTableView.loadInstitutions([])
            toggleContentContainerViewVisbility()
        }
        delegate?.institutionPicker(self, didSelect: institution)
    }
    
    private func showLoadingView(_ show: Bool) {
        loadingView.isHidden = !show
        if show {
            loadingView.stp_startAnimatingAndShow()
        } else {
            loadingView.stp_stopAnimatingAndHide()
        }
        view.bringSubviewToFront(loadingView) // defensive programming to avoid loadingView being hiddden
    }
}

// MARK: - Data

@available(iOSApplicationExtension, unavailable)
extension InstitutionPicker {
    
    private func fetchFeaturedInstitutions(completionHandler: @escaping () -> Void) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
        
        dataSource
            .fetchFeaturedInstitutions()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch(result) {
                case .success(let institutions):
                    if #available(iOS 13.0, *) {
                        self.featuredInstitutionGridView.loadInstitutions(institutions)
                    }
                case .failure(_):
                    // TODO: add handling for failure (Stripe.js currently shows a terminal error)
                    break
                }
                completionHandler()
            }
    }
    
    private func fetchInstitutions(searchQuery: String) {
        fetchInstitutionsDispatchWorkItem?.cancel()
        if #available(iOS 13.0, *) {
            institutionSearchTableView.showError(false)
        }
        
        guard !searchQuery.isEmpty else {
            // clear data because search query is empty
            if #available(iOS 13.0, *) {
                institutionSearchTableView.loadInstitutions([])
            }
            return
        }

        if #available(iOS 13.0, *) {
            institutionSearchTableView.showLoadingView(true)
        }
        let newFetchInstitutionsDispatchWorkItem = DispatchWorkItem(block: { [weak self] in
            guard let self = self else { return }
            
            if #available(iOS 13.0, *) {
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
                        
                        switch(result) {
                        case .success(let institutions):
                            self.institutionSearchTableView.loadInstitutions(institutions)
                            if institutions.isEmpty {
                                self.institutionSearchTableView.showNoResultsNotice(query: searchQuery)
                            }
                        case .failure(_):
                            self.institutionSearchTableView.loadInstitutions([])
                            self.institutionSearchTableView.showError(true)
                        }
                        self.institutionSearchTableView.showLoadingView(false)
                    }
            }
        })
        
        // TODO(kgaidis): optimize search to only delay if needed...
        
        self.fetchInstitutionsDispatchWorkItem = newFetchInstitutionsDispatchWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.queryDelay, execute: newFetchInstitutionsDispatchWorkItem)
    }
}

// MARK: - UISearchBarDelegate

@available(iOSApplicationExtension, unavailable)
extension InstitutionPicker: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        setSearchBarBorderColor(isHighlighted: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        setSearchBarBorderColor(isHighlighted: false)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        toggleContentContainerViewVisbility()
        fetchInstitutions(searchQuery: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UIGestureRecognizerDelegate

@available(iOSApplicationExtension, unavailable)
extension InstitutionPicker: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchPoint = touch.location(in: view)
        return !searchBar.frame.contains(touchPoint) && !contentContainerView.frame.contains(touchPoint)
    }
}

// MARK: - FeaturedInstitutionGridViewDelegate

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
extension InstitutionPicker: FeaturedInstitutionGridViewDelegate {
    
    func featuredInstitutionGridView(
        _ view: FeaturedInstitutionGridView,
        didSelectInstitution institution: FinancialConnectionsInstitution
    ) {
        didSelectInstitution(institution)
    }
}

// MARK: - InstitutionSearchTableViewDelegate

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
extension InstitutionPicker: InstitutionSearchTableViewDelegate {
    
    func institutionSearchTableView(
        _ tableView: InstitutionSearchTableView,
        didSelectInstitution institution: FinancialConnectionsInstitution
    ) {
        didSelectInstitution(institution)
    }
    
    func institutionSearchTableViewDidSelectManuallyAddYourAccount(_ tableView: InstitutionSearchTableView) {
        delegate?.institutionPickerDidSelectManuallyAddYourAccount(self)
    }
}

// MARK: - Constants

@available(iOSApplicationExtension, unavailable)
extension InstitutionPicker {
    enum Constants {
      static let queryDelay = TimeInterval(0.2)
  }
}

// MARK: - Helpers

private func CreateMainView(
    searchView: UIView?,
    contentContainerView: UIView
) -> UIView {
    let verticalStackView = UIStackView(
        arrangedSubviews: [
            CreateHeaderView(
                searchView: searchView
            ),
            contentContainerView,
        ]
    )
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 16
    return verticalStackView
}

private func CreateHeaderView(
    searchView: UIView?
) -> UIView {
    let verticalStackView = UIStackView(
        arrangedSubviews: [
            CreateHeaderTitleLabel(),
        ]
    )
    if let searchView = searchView {
        verticalStackView.addArrangedSubview(searchView)
    }
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 24
    verticalStackView.isLayoutMarginsRelativeArrangement = true
    verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 16,
        leading: 24,
        bottom: 0,
        trailing: 24
    )
    return verticalStackView
}

private func CreateHeaderTitleLabel() -> UIView {
    let headerTitleLabel = UILabel()
    headerTitleLabel.text = STPLocalizedString("Select your bank", "The title of the 'Institution Picker' screen where users get to select an institution (ex. a bank like Bank of America).")
    headerTitleLabel.textColor = .textPrimary
    headerTitleLabel.font = .stripeFont(forTextStyle: .subtitle)
    return headerTitleLabel
}
