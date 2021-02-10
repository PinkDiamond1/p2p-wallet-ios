//
//  ReceiveTokenVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import Action

class ReceiveTokenVC: WLModalVC {
    // MARK: - Properties
    override var padding: UIEdgeInsets {UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)}
    let collectionViewSpacing: CGFloat = 16
    
    var dataSource: UICollectionViewDiffableDataSource<String, Wallet>!
    let wallets: [Wallet]
    
    // MARK: - Subviews
    lazy var collectionView: BaseCollectionView = {
        let collectionView = BaseCollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.configureForAutoLayout()
        collectionView.autoSetDimension(.height, toSize: 438)
        collectionView.registerCells([ReceiveTokenCell.self])
        collectionView.alwaysBounceVertical = false
        return collectionView
    }()
    public lazy var pageControl: UIPageControl = {
        let pc = UIPageControl(forAutoLayout: ())
//        pc.addTarget(self, action: #selector(pageControlDidChange), for: .valueChanged)
        pc.isUserInteractionEnabled = false
        pc.pageIndicatorTintColor = .a4a4a4
        pc.currentPageIndicatorTintColor = .textBlack
        return pc
    }()
    
    // MARK: - Initializers
    init(wallets: [Wallet]) {
        self.wallets = wallets
        super.init()
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layoutIfNeeded()
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    override func setUp() {
        super.setUp()
        containerView.backgroundColor = .background5
        stackView.addArrangedSubview(UILabel(text: L10n.sendToYourWallet, textSize: 17, weight: .medium, textAlignment: .center))
        stackView.addArrangedSubview(collectionView)
        stackView.addArrangedSubview(pageControl)
        
        dataSource = UICollectionViewDiffableDataSource<String, Wallet>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: Wallet) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ReceiveTokenCell.self), for: indexPath) as? ReceiveTokenCell
            cell?.setUp(wallet: item)
//            cell?.copyButton.rx.action = CocoaAction {
//                UIApplication.shared.copyToClipboard(item.pubkey)
//                return .just(())
//            }
            cell?.shareButton.rx.action = CocoaAction {
                let vc = UIActivityViewController(activityItems: [item.pubkey!], applicationActivities: nil)
                self.present(vc, animated: true, completion: nil)
                return .just(())
            }
            return cell ?? UICollectionViewCell()
        }
        
        // config snapshot
        var snapshot = NSDiffableDataSourceSnapshot<String, Wallet>()
        let section = ""
        snapshot.appendSections([section])
        snapshot.appendItems(wallets, toSection: section)
        self.dataSource.apply(snapshot)
        
        // config pagecontrol
        self.pageControl.numberOfPages = wallets.count
        self.pageControl.isHidden = wallets.count <= 1
    }
    
    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { (_: Int, env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            var width: NSCollectionLayoutDimension = .absolute(env.container.contentSize.width - self.collectionViewSpacing * 4)
            
            if UIDevice.current.userInterfaceIdiom == .pad ||
                UIDevice.current.orientation == .landscapeLeft ||
                UIDevice.current.orientation == .landscapeRight
            {
                width = .absolute(335)
            }
                
            if self.wallets.count == 1 {
                width = .absolute(env.container.contentSize.width - self.collectionViewSpacing * 2)
            }
            
            let groupSize = NSCollectionLayoutSize(widthDimension: width, heightDimension: .absolute(438))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            if self.wallets.count > 1 {
                section.interGroupSpacing = self.collectionViewSpacing
            }
            
            section.orthogonalScrollingBehavior = .groupPagingCentered
            section.visibleItemsInvalidationHandler = { [weak self] _, _, _ in
                if let visibleRows = self?.collectionView.indexPathsForVisibleItems.map({$0.row})
                {
                    var currentPage: Int = 0
                    
                    switch visibleRows.count {
                    case 1:
                        currentPage = visibleRows.first!
                    case 2:
                        if visibleRows.contains(0) {
                            // at the begining of the collectionView
                            currentPage = visibleRows.min()!
                        } else {
                            // at the end of the collectionView
                            currentPage = visibleRows.max()!
                        }
                    case 3:
                        let rowsSum = visibleRows.reduce(0, +)
                        currentPage = rowsSum / visibleRows.count
                    default:
                        break
                    }
                    self?.pageControl.currentPage = currentPage
                }
            }
            return section
        }
    }
    
//    @objc func pageControlDidChange() {
//        guard pageControl.currentPage < collectionView.numberOfItems(inSection: 0) else {return}
//        collectionView.scrollToItem(at: IndexPath(row: pageControl.currentPage, section: 0), at: .centeredHorizontally, animated: true)
//    }
}

extension ReceiveTokenVC: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return FlexibleHeightPresentationController(position: .bottom, presentedViewController: presented, presenting: presenting)
    }
}