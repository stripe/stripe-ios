//
//  InstitutionSearchTableView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/20/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

private enum Section {
    case main
}

@available(iOS 13.0, *)
protocol InstitutionSearchTableViewDelegate: AnyObject {
    func institutionSearchTableView(_ tableView: InstitutionSearchTableView, didSelectInstitution institution: FinancialConnectionsInstitution)
}

@available(iOS 13.0, *)
final class InstitutionSearchTableView: UIView {
    
    private let dataSource: UITableViewDiffableDataSource<Section, FinancialConnectionsInstitution>
    weak var delegate: InstitutionSearchTableViewDelegate? = nil
    
    init() {
        let tableView = UITableView()
        self.dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, institution in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier) else {
                fatalError("TableView expected to have cells")
            }
            cell.textLabel?.text = institution.name
            return cell
        }
        super.init(frame: .zero)
        addAndPinSubview(tableView)
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadInstitutions(_ institutions: [FinancialConnectionsInstitution]) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, FinancialConnectionsInstitution>()
        snapshot.appendSections([Section.main])
        snapshot.appendItems(institutions, toSection: Section.main)
        dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate

@available(iOS 13.0, *)
extension InstitutionSearchTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let institution = dataSource.itemIdentifier(for: indexPath) {
            delegate?.institutionSearchTableView(self, didSelectInstitution: institution)
        }
    }
}

// MARK: - Constants

@available(iOS 13.0, *)
extension InstitutionSearchTableView {
    private enum Constants {
      static let cellIdentifier = "InstitutionCell"
  }
}
