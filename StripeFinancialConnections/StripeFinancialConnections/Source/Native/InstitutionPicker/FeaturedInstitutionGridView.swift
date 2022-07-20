//
//  FeaturedInstitutionGridViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/19/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

@available(iOS 13.0, *)
protocol FeaturedInstitutionGridViewDelegate: AnyObject {
    func featuredInstitutionGridView(_ view: FeaturedInstitutionGridView, didSelectInstitution institution: FinancialConnectionsInstitution)
}

private enum Section {
    case main
}

@available(iOS 13.0, *)
class FeaturedInstitutionGridView: UIView {

    private let flowLayout: UICollectionViewFlowLayout
    // necessary to retain a reference to `dataSource`
    private let dataSource: UICollectionViewDiffableDataSource<Section, FinancialConnectionsInstitution>
    weak var delegate: FeaturedInstitutionGridViewDelegate?
    
    init(institutions: [FinancialConnectionsInstitution]) {
        let flowLayout = UICollectionViewFlowLayout()
        self.flowLayout = flowLayout
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        let cellIdentifier = "\(FeaturedInstitutionGridCell.self)"
        collectionView.register(FeaturedInstitutionGridCell.self, forCellWithReuseIdentifier: cellIdentifier)
        
        let dataSource = UICollectionViewDiffableDataSource<Section, FinancialConnectionsInstitution>(collectionView: collectionView) { collectionView, indexPath, institution in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? FeaturedInstitutionGridCell else {
                fatalError("Couldn't find cell with reuseIdentifier \(cellIdentifier)")
            }
            cell.customize(with: institution)
            return cell
        }
        self.dataSource = dataSource
        
        super.init(frame: .zero)
        
        collectionView.delegate = self
        addAndPinSubview(collectionView)
        
        loadInstitutions(institutions)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadInstitutions(_ institutions: [FinancialConnectionsInstitution]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, FinancialConnectionsInstitution>()
        snapshot.appendSections([.main])
        snapshot.appendItems(institutions, toSection: .main)
        dataSource.apply(snapshot)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let itemSpacing: CGFloat = 8
        flowLayout.minimumLineSpacing = itemSpacing
        flowLayout.minimumInteritemSpacing = itemSpacing
        flowLayout.itemSize = CGSize(
            width: (bounds.width - itemSpacing) / 2,
            height: 70
        )
    }
}

// MARK: - <UICollectionViewDelegate>

@available(iOS 13.0, *)
extension FeaturedInstitutionGridView: UICollectionViewDelegate {
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        if let institution = dataSource.itemIdentifier(for: indexPath) {
            delegate?.featuredInstitutionGridView(self, didSelectInstitution: institution)
        }
    }
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
private struct FeaturedInstitutionGridViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> FeaturedInstitutionGridView {
        FeaturedInstitutionGridView(
            institutions: (1...10).map { i in
                FinancialConnectionsInstitution(id: "\(i)", name: "\(i)", url: nil)
            }
        )
    }
    
    func updateUIView(_ uiView: FeaturedInstitutionGridView, context: Context) {}
}

struct FeaturedInstitutionGridView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        VStack {
            FeaturedInstitutionGridViewUIViewRepresentable()
        }
        .frame(width: 320)
        .frame(maxHeight: .infinity)
    }
}

#endif
