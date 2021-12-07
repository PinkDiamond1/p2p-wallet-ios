//
//  SendToken.ChooseRecipientAndNetwork.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation
import UIKit
import RxSwift

extension SendToken.ChooseRecipientAndNetwork {
    class ViewController: SendToken.BaseViewController {
        // MARK: - Dependencies
        private let viewModel: SendTokenChooseRecipientAndNetworkViewModelType
        
        // MARK: - Properties
        
        // MARK: - Subviews
        private lazy var pagesVC = WLSegmentedPagesVC(items: [
            .init(label: L10n.address, viewController: addressVC),
            .init(label: L10n.contact, viewController: contactVC)
        ])
        
        private lazy var addressVC = SelectAddress.ViewController(
            viewModel: viewModel.createSelectAddressViewModel()
        )
        
        private lazy var contactVC: ContactViewController = {
            let vc = ContactViewController(viewModel: viewModel)
            return vc
        }()
        
        // MARK: - Initializer
        init(viewModel: SendTokenChooseRecipientAndNetworkViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            // navigation bar
            let amount = viewModel.getSelectedAmount() ?? 0
            let symbol = viewModel.getSelectedWallet()?.token.symbol ?? ""
            let title = L10n.send(amount.toString(maximumFractionDigits: 9), symbol)
            navigationBar.titleLabel.text = title
            
            // container
            let containerView = UIView(forAutoLayout: ())
            view.addSubview(containerView)
            containerView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 8)
            containerView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
            
            add(child: pagesVC, to: containerView)
            
            // FIXME: - Remove later (contact is not ready)
            pagesVC.hideSegmentedControl()
            pagesVC.disableScrolling()
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {
                return
            }

            switch scene {
            }
        }
    }
}