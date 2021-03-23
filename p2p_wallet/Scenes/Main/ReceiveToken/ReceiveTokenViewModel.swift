//
//  ReceiveTokenViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import UIKit
import RxSwift
import RxCocoa

enum ReceiveTokenNavigatableScene {
    case chooseWallet
    case explorer(url: String)
    case share(pubkey: String)
}

class ReceiveTokenViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    let repository: WalletsRepository
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<ReceiveTokenNavigatableScene>()
    let wallet = BehaviorRelay<Wallet?>(value: nil)
    let alert = PublishSubject<String>()
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(walletsRepository: WalletsRepository, pubkey: String? = nil) {
        self.repository = walletsRepository
        self.wallet.accept(repository.getWallets().first(where: {$0.pubkey == pubkey}) ?? repository.getWallets().first)
        bind()
    }
    
    private func bind() {
        // bind wallet
        repository.stateObservable()
            .filter { state in
                switch state {
                case .loaded:
                    return true
                default:
                    return false
                }
            }
            .map { [weak self] _ -> Wallet? in
                if let currentWallet = self?.wallet.value {
                    return self?.repository.getWallets().first(where: {$0.pubkey == currentWallet.pubkey})
                }
                return self?.repository.getWallets().first
            }
            .bind(to: wallet)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    @objc func selectWallet() {
        navigationSubject.onNext(.chooseWallet)
    }
    
    @objc func showMintInExplorer() {
        guard let mint = wallet.value?.mintAddress else {return}
        let url = "https://explorer.solana.com/address/\(mint)"
        navigationSubject.onNext(.explorer(url: url))
    }
    
    @objc func share() {
        guard let pubkey = wallet.value?.pubkey else {return}
        navigationSubject.onNext(.share(pubkey: pubkey))
    }
}