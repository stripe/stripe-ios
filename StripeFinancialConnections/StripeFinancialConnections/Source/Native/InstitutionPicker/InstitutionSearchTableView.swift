//
//  InstitutionSearchTableView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/20/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
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
    private lazy var loadingView: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = .textSecondary // set color because we only support light mode
        activityIndicator.backgroundColor = .customBackgroundColor
        activityIndicator.isHidden = true
        activityIndicator.setContentHuggingPriority(.defaultLow, for: .vertical)
        activityIndicator.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return activityIndicator
    }()
    
    init() {
        let tableView = UITableView()
        tableView.backgroundColor = .customBackgroundColor
        tableView.separatorInset = .zero
        tableView.separatorStyle = .none
        tableView.rowHeight = 54
        tableView.contentInset = UIEdgeInsets(
            // add extra inset at the top/bottom to show the cell-selected-state separators
            top: 1.0 / UIScreen.main.nativeScale,
            left: 0,
            bottom: 1.0 / UIScreen.main.nativeScale,
            right: 0
        )
        tableView.keyboardDismissMode = .onDrag
        let cellIdentifier = "\(InstitutionSearchTableViewCell.self)"
        self.dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, institution in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? InstitutionSearchTableViewCell else {
                fatalError("Unable to dequeue cell \(InstitutionSearchTableViewCell.self) with cell identifier \(cellIdentifier)")
            }
            cell.customize(with: institution)
            return cell
        }
        super.init(frame: .zero)
        tableView.register(InstitutionSearchTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.delegate = self
        addAndPinSubview(tableView)
        addAndPinSubview(loadingView)
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
    
    func showLoadingView(_ show: Bool) {
        loadingView.isHidden = !show
        if show {
            loadingView.stp_startAnimatingAndShow()
        } else {
            loadingView.stp_stopAnimatingAndHide()
        }
        bringSubviewToFront(loadingView) // defensive programming to avoid loadingView being hiddden
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
