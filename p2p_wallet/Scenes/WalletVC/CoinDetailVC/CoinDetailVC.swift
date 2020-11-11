//
//  CoinDetailVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import DiffableDataSources

class CoinDetailVC: CollectionVC<CoinDetailVC.Section, String, PriceCell> {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .normal()
    }
    
    // MARK: - Nested type
    enum Section: String, CaseIterable {
        case activities
        
        var localizedString: String {
            switch self {
            case .activities:
                return L10n.activities
            }
        }
    }
    
    // MARK: - Initializer
    init() {
        super.init(viewModel: ListViewModel<String>())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        title = "Coin name"
        
        // initial snapshot
        var snapshot = DiffableDataSourceSnapshot<Section, String>()
        var items = [String]()
        for i in 0..<5 {
            items.append("\(i)")
        }
        let section = Section.activities
        snapshot.appendSections([section])
        snapshot.appendItems(items, toSection: section)
        
        dataSource.apply(snapshot)
    }
    
    override func registerCellAndSupplementaryViews() {
        super.registerCellAndSupplementaryViews()
        collectionView.register(CoinDetailSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "CoinDetailSectionHeaderView")
    }
    
    override func createLayoutForSection(_ sectionIndex: Int, environment env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let section = super.createLayoutForSection(sectionIndex, environment: env)
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(20))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section?.boundarySupplementaryItems = [sectionHeader]
        return section
    }
    
    override func configureSupplementaryView(collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "CoinDetailSectionHeaderView",
            for: indexPath) as? CoinDetailSectionHeaderView
        view?.headerLabel.text = Section.activities.localizedString
        return view
    }
}