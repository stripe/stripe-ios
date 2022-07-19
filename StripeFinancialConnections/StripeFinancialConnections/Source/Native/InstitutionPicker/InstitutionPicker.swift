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
    private let searchBar = UISearchBar()
    private let dataSource: InstitutionDataSource
    
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
      
        view.addAndPinSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)
        searchBar.delegate = self
        performQuery()
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
      func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
          queryItem?.cancel()
          queryItem = DispatchWorkItem(block: { [weak self] in
              guard let self = self else { return }
              self.performQuery()
          })
          DispatchQueue.main.asyncAfter(deadline: .now() + Constants.queryDelay, execute: queryItem!)
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
        
        // TODO(kgaidis): refactor to use
//        let featuredInstitutionGridView = FeaturedInstitutionGridView(institutions: institutions)
//        featuredInstitutionGridView.delegate = self
//        view.addAndPinSubview(
//            featuredInstitutionGridView,
//            directionalLayoutMargins: NSDirectionalEdgeInsets(
//                top: 24,
//                leading: 24,
//                bottom: 24,
//                trailing: 24
//            )
//        )
    }
    
    func loadDataSourceData(institutions: [FinancialConnectionsInstitution]) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        self.institutions = institutions
        tableView.reloadData()
    }
}

// MARK: - <FeaturedInstitutionGridViewDelegate>

@available(iOSApplicationExtension 13.0, *)
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
