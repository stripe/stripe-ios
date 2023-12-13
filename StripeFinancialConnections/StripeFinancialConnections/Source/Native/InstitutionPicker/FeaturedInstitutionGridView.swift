//
//  FeaturedInstitutionGridViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/19/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

protocol FeaturedInstitutionGridViewDelegate: AnyObject {
    func featuredInstitutionGridView(
        _ view: FeaturedInstitutionGridView,
        didSelectInstitution institution: FinancialConnectionsInstitution
    )
}

private enum Section {
    case main
}

class FeaturedInstitutionGridView: UIView {

    private let horizontalPadding: CGFloat = 24.0
    private let flowLayout: UICollectionViewFlowLayout
    // necessary to retain a reference to `dataSource`
    private let dataSource: UICollectionViewDiffableDataSource<Section, FinancialConnectionsInstitution>
    weak var delegate: FeaturedInstitutionGridViewDelegate?

    init() {
        let flowLayout = UICollectionViewFlowLayout()
        self.flowLayout = flowLayout

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(
            top: 0,
            left: horizontalPadding,
            bottom: 16,
            right: horizontalPadding
        )
        #if !canImport(CompositorServices)
        collectionView.keyboardDismissMode = .onDrag
        #endif
        let cellIdentifier = "\(FeaturedInstitutionGridCell.self)"
        collectionView.register(FeaturedInstitutionGridCell.self, forCellWithReuseIdentifier: cellIdentifier)

        let dataSource = UICollectionViewDiffableDataSource<Section, FinancialConnectionsInstitution>(
            collectionView: collectionView
        ) { collectionView, indexPath, institution in
            guard
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
                    as? FeaturedInstitutionGridCell
            else {
                fatalError("Couldn't find cell with reuseIdentifier \(cellIdentifier)")
            }
            cell.customize(with: institution)
            cell.accessibilityLabel = institution.name  // used for UI tests
            return cell
        }
        self.dataSource = dataSource

        super.init(frame: .zero)

        collectionView.delegate = self
        addAndPinSubview(collectionView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadInstitutions(_ institutions: [FinancialConnectionsInstitution]) {
        assertMainQueue()

        var snapshot = NSDiffableDataSourceSnapshot<Section, FinancialConnectionsInstitution>()
        snapshot.appendSections([.main])
        snapshot.appendItems(institutions, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let itemSpacing: CGFloat = 8
        flowLayout.minimumLineSpacing = itemSpacing
        flowLayout.minimumInteritemSpacing = itemSpacing
        flowLayout.itemSize = CGSize(
            width: (bounds.width - itemSpacing - (2 * horizontalPadding)) / 2,
            height: 80
        )
    }
}

// MARK: - <UICollectionViewDelegate>

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

private struct FeaturedInstitutionGridViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> FeaturedInstitutionGridView {
        FeaturedInstitutionGridView()
    }

    func updateUIView(_ uiView: FeaturedInstitutionGridView, context: Context) {
        let institutions = (1...10).map { i in
            FinancialConnectionsInstitution(
                id: "\(i)",
                name: "\(i)",
                url: nil,
                icon: nil,
                logo: nil
            )
        }
        uiView.loadInstitutions(institutions)
    }
}

struct FeaturedInstitutionGridView_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            FeaturedInstitutionGridViewUIViewRepresentable()
        }
        .frame(width: 320)
        .frame(maxHeight: .infinity)
    }
}

#endif
