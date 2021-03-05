//
//  HomeViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import Foundation
import UIKit

protocol HomeScenesFactory {
    func makeWalletDetailVC(wallet: Wallet) -> WalletDetailVC
    func makeReceiveTokenViewController() -> ReceiveTokenVC
    func makeSendTokenViewController(activeWallet: Wallet?, destinationAddress: String?) -> WLModalWrapperVC
    func makeSwapTokenViewController(fromWallet wallet: Wallet?) -> SwapTokenViewController
    func makeMyProductsVC() -> MyProductsVC
    func makeProfileVC() -> ProfileVC
    func makeTokenSettingsViewController(pubkey: String) -> TokenSettingsViewController
}

class HomeViewController: BaseVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }
    
    // MARK: - Properties
    let viewModel: HomeViewModel
    let scenesFactory: HomeScenesFactory
    
    // MARK: - Initializer
    init(viewModel: HomeViewModel, scenesFactory: HomeScenesFactory)
    {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func loadView() {
        view = HomeRootView(viewModel: viewModel)
    }
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: HomeNavigatableScene) {
        switch scene {
        case .receiveToken:
            let vc = self.scenesFactory.makeReceiveTokenViewController()
            self.present(vc, animated: true, completion: nil)
        case .scanQr:
            break
        case .sendToken(let address):
            let vc = self.scenesFactory
                .makeSendTokenViewController(activeWallet: nil, destinationAddress: address)
            self.present(vc, animated: true, completion: nil)
        case .swapToken:
            let vc = self.scenesFactory.makeSwapTokenViewController(fromWallet: nil)
            self.present(vc, animated: true, completion: nil)
        case .allProducts:
            let vc = self.scenesFactory.makeMyProductsVC()
            self.present(vc, animated: true, completion: nil)
        case .profile:
            let profileVC = self.scenesFactory.makeProfileVC()
            self.present(profileVC, animated: true, completion: nil)
        case .walletDetail(let wallet):
            let vc = scenesFactory.makeWalletDetailVC(wallet: wallet)
            present(vc, animated: true, completion: nil)
        case .walletSettings(let wallet):
            guard let pubkey = wallet.pubkey else {return}
            let vc = self.scenesFactory.makeTokenSettingsViewController(pubkey: pubkey)
            self.present(vc, animated: true, completion: nil)
        }
    }
}