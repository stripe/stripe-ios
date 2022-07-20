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

protocol InstitutionPickerDelegate: AnyObject {
    func institutionPicker(_ picker: InstitutionPicker, didSelect institution: FinancialConnectionsInstitution)
}

class InstitutionPicker: UIViewController {
    
    // MARK: - Properties
    
    private let tableView = UITableView(frame: .zero)
    private let dataSource: InstitutionDataSource
    
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
    
    weak var delegate: InstitutionPickerDelegate?
    
    // MARK: - Diffable Datasource

    enum Section: CaseIterable {
        case main
    }

    @available(iOS 13.0, *)
    private lazy var diffableDataSource: UITableViewDiffableDataSource<Section, FinancialConnectionsInstitution>? = UITableViewDiffableDataSource(tableView: self.tableView) { tableView, indexPath, itemIdentifier in
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier) else {
            fatalError("TableView expected to have cells")
        }
        
        cell.textLabel?.text = itemIdentifier.name
        return cell
    }
    
    // Only used for iOS12 fallback where we don't ahve the diffable datasource
    private lazy var institutions: [FinancialConnectionsInstitution]? = nil
    
    // MARK: - Debouncing Support

    private var queryItem: DispatchWorkItem?
    private var currentDataVersion: Int = 0
    
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
        view.backgroundColor = UIColor.customBackgroundColor
        
        let headerLabel = UILabel()
        headerLabel.text = STPLocalizedString("Select your bank", "The title of the 'Institution Picker' screen where users get to select an institution (ex. a bank like Bank of America).")
        headerLabel.textColor = .textPrimary
        headerLabel.font = .stripeFont(forTextStyle: .subtitle)
        view.addSubview(headerLabel)
        
        setSearchBarBorder(isHighlighted: false)
        view.addSubview(searchBar)
        let dismissSearchBarTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOutsideOfSearchBar))
        dismissSearchBarTapGestureRecognizer.delegate = self
        view.addGestureRecognizer(dismissSearchBarTapGestureRecognizer)
        
        view.addSubview(contentContainerView)
        
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        let horizontalPadding: CGFloat = 24.0
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            
            searchBar.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: horizontalPadding),
            
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            
            contentContainerView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            contentContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: horizontalPadding),
        ])
        
//        view.addAndPinSubview(tableView)
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)
        
        performQuery()
    }
    
    private func setSearchBarBorder(isHighlighted: Bool) {
        let searchBarBorderColor: UIColor
        if isHighlighted {
            searchBarBorderColor = .textBrand
        } else {
            searchBarBorderColor = .borderNeutral
        }
        searchBar.layer.borderColor = searchBarBorderColor.cgColor
    }
    
    @IBAction private func didTapOutsideOfSearchBar() {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UITableViewDelegate

extension InstitutionPicker: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return searchBar
    }
}

// MARK: - UITableViewDataSource

extension InstitutionPicker: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return institutions?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)

        cell.textLabel?.text = institutions![indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let institution = institutionAt(indexPath: indexPath) {
            delegate?.institutionPicker(self, didSelect: institution)
        }
    }
}

// MARK: - UISearchBarDelegate

extension InstitutionPicker: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        setSearchBarBorder(isHighlighted: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        setSearchBarBorder(isHighlighted: false)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        queryItem?.cancel()
        queryItem = DispatchWorkItem(block: { [weak self] in
            guard let self = self else { return }
            self.performQuery()
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.queryDelay, execute: queryItem!)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension InstitutionPicker: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchPoint = touch.location(in: view)
        return !searchBar.frame.contains(touchPoint) && !contentContainerView.frame.contains(touchPoint)
    }
}

// MARK: - Helpers

private extension InstitutionPicker {
    
    func institutionAt(indexPath: IndexPath) -> FinancialConnectionsInstitution? {
        if #available(iOS 13.0, *) {
            return diffableDataSource?.itemIdentifier(for: indexPath)
        } else {
            return self.institutions?[indexPath.row]
        }
    }
    
    func performQuery() {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
        
        let version = self.currentDataVersion + 1
        
        dataSource
            .search(query: searchBar.text)
            .observe(on: DispatchQueue.main) { [weak self] result in
                guard let self = self else { return }
                switch(result) {
                case .failure(let error):
                    print(error)
                    // TODO(vardges): handle this
                case .success(let institutions):
                    self.loadData(institutions: institutions, version: version)
                }
        }
    }
    
    
    func loadData(institutions: [FinancialConnectionsInstitution], version: Int) {
        guard version > currentDataVersion else { return }
        
        currentDataVersion = version
        if #available(iOS 13.0, *) {
            loadDiffableData(institutions: institutions)
        } else {
            loadDataSourceData(institutions: institutions)
        }
    }
    
    @available(iOS 13.0, *)
    func loadDiffableData(institutions: [FinancialConnectionsInstitution]) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        var snapshot = NSDiffableDataSourceSnapshot<Section, FinancialConnectionsInstitution>()
        snapshot.appendSections([Section.main])
        snapshot.appendItems(institutions, toSection: Section.main)
        diffableDataSource?.apply(snapshot, animatingDifferences: true, completion: nil)
        
        let featuredInstitutionGridView = FeaturedInstitutionGridView(institutions: institutions)
        featuredInstitutionGridView.delegate = self
        contentContainerView.addAndPinSubview(featuredInstitutionGridView)
    }
    
    func loadDataSourceData(institutions: [FinancialConnectionsInstitution]) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        self.institutions = institutions
        tableView.reloadData()
    }
}

// MARK: - <FeaturedInstitutionGridViewDelegate>

@available(iOS 13.0, *)
extension InstitutionPicker: FeaturedInstitutionGridViewDelegate {
    
    func featuredInstitutionGridView(
        _ view: FeaturedInstitutionGridView,
        didSelectInstitution institution: FinancialConnectionsInstitution
    ) {
        delegate?.institutionPicker(self, didSelect: institution)
    }
}

// MARK: - Constants

extension InstitutionPicker {
    enum Constants {
      static let queryDelay = TimeInterval(0.2)
      static let cellIdentifier = "InstitutionCell"
  }
}
