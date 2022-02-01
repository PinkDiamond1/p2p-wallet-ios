//
//  ReceiveToken.SceneModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ReceiveSceneModel: BESceneModel {
    var tokenTypeDriver: Driver<ReceiveToken.TokenType> { get }
    var hasAddressesInfoDriver: Driver<Bool> { get }
    var hasHintViewOnTopDriver: Driver<Bool> { get }
    var addressesInfoIsOpenedDriver: Driver<Bool> { get }
    var showHideAddressesInfoButtonTapSubject: PublishRelay<Void> { get }
    var addressesHintIsHiddenDriver: Driver<Bool> { get }
    var hideAddressesHintSubject: PublishRelay<Void> { get }
    var updateLayoutDriver: Driver<Void> { get }
    var receiveSolanaViewModel: ReceiveTokenSolanaViewModelType { get }
    var receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType { get }
    var shouldShowChainsSwitcher: Bool { get }
    var tokenWallet: Wallet? { get }
    var navigation: Driver<ReceiveToken.NavigatableScene?> { get }

    func switchToken(_ tokenType: ReceiveToken.TokenType)
    func copyToClipboard(address: String, logEvent: AnalyticsEvent)
    func showSelectionNetwork()
    func copyDirectAddress()
    func copyMintAddress()
}

extension ReceiveToken {
    class SceneModel: NSObject, ReceiveSceneModel {
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var notificationsService: NotificationsServiceType

        // MARK: - Properties
        private let disposeBag = DisposeBag()
        let receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        let receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType

        // MARK: - Subjects
        let showHideAddressesInfoButtonTapSubject = PublishRelay<Void>()
        let addressesHintIsHiddenSubject = BehaviorRelay<Bool>(value: false)
        let hideAddressesHintSubject = PublishRelay<Void>()
        private let navigationSubject = PublishRelay<NavigatableScene?>()
        private let tokenTypeSubject = BehaviorRelay<TokenType>(value: .solana)
        private let addressesInfoIsOpenedSubject = BehaviorRelay<Bool>(value: false)
        let tokenWallet: Wallet?
        let shouldShowChainsSwitcher: Bool
        private let screenCanHaveAddressesInfo: Bool
        private let screenCanHaveHint: Bool

        init(
            solanaPubkey: SolanaSDK.PublicKey,
            solanaTokenWallet: Wallet? = nil,
            isRenBTCWalletCreated: Bool,
            isOpeningFromToken: Bool = false
        ) {
            let isRenBTC = solanaTokenWallet?.token.isRenBTC ?? false
            let hasExplorerButton = !isOpeningFromToken
            self.tokenWallet = solanaTokenWallet
            self.screenCanHaveAddressesInfo = isOpeningFromToken && solanaTokenWallet != nil
            self.screenCanHaveHint = isOpeningFromToken
            self.shouldShowChainsSwitcher = isOpeningFromToken ? isRenBTC : solanaTokenWallet?.isNativeSOL ?? true
            receiveSolanaViewModel = ReceiveToken.SolanaViewModel(
                solanaPubkey: solanaPubkey.base58EncodedString,
                solanaTokenWallet: solanaTokenWallet,
                navigationSubject: navigationSubject,
                hasExplorerButton: hasExplorerButton
            )
            
            receiveBitcoinViewModel = ReceiveToken.ReceiveBitcoinViewModel(
                navigationSubject: navigationSubject,
                isRenBTCWalletCreated: isRenBTCWalletCreated,
                hasExplorerButton: hasExplorerButton
            )
            
            super.init()

            bind()
        }
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
        
        var tokenTypeDriver: Driver<ReceiveToken.TokenType> { tokenTypeSubject.asDriver() }
        
        var updateLayoutDriver: Driver<Void> {
            Driver.combineLatest(
                    tokenTypeDriver,
                    receiveBitcoinViewModel.isReceivingRenBTCDriver,
                    receiveBitcoinViewModel.renBTCWalletCreatingDriver,
                    receiveBitcoinViewModel.conditionAcceptedDriver,
                    receiveBitcoinViewModel.addressDriver,
                    receiveBitcoinViewModel.processingTxsDriver
                )
                .map { _ in () }.asDriver()
        }

        var hasAddressesInfoDriver: Driver<Bool> {
            tokenTypeDriver
                .map { [weak self] tokenType in
                    guard let self = self else { return false }

                    switch tokenType {
                    case .solana:
                        return self.screenCanHaveAddressesInfo
                    case .btc:
                        return false
                    }
                }
        }

        var addressesInfoIsOpenedDriver: Driver<Bool> {
            addressesInfoIsOpenedSubject.asDriver()
        }

        var addressesHintIsHiddenDriver: Driver<Bool> {
            addressesHintIsHiddenSubject.asDriver()
        }

        var hasHintViewOnTopDriver: Driver<Bool> {
            tokenTypeDriver
                .map { [weak self] tokenType in
                    guard let self = self else { return false }

                    switch tokenType {
                    case .solana:
                        return self.screenCanHaveHint
                    case .btc:
                        return false
                    }
                }
        }

        func switchToken(_ tokenType: ReceiveToken.TokenType) {
            tokenTypeSubject.accept(tokenType)
        }
        
        func copyToClipboard(address: String, logEvent: AnalyticsEvent) {
            clipboardManager.copyToClipboard(address)
            analyticsManager.log(event: logEvent)
        }

        func showSelectionNetwork() {
            navigationSubject.accept(.networkSelection)
        }

        func copyDirectAddress() {
            guard let address = tokenWallet?.pubkey else { return assertionFailure() }

            clipboardManager.copyToClipboard(address)
            showCopied()
        }

        func copyMintAddress() {
            guard let address = tokenWallet?.mintAddress else { return assertionFailure() }

            clipboardManager.copyToClipboard(address)
            showCopied()
        }
        
        var navigation: Driver<NavigatableScene?> { navigationSubject.asDriver(onErrorDriveWith: Driver.empty()) }

        private func bind() {
            showHideAddressesInfoButtonTapSubject
                .subscribe(onNext: { [weak addressesInfoIsOpenedSubject] in
                    guard let addressesInfoIsOpenedSubject = addressesInfoIsOpenedSubject else { return }
                    addressesInfoIsOpenedSubject.accept(!addressesInfoIsOpenedSubject.value)
                })
                .disposed(by: disposeBag)

            hideAddressesHintSubject
                .subscribe(onNext: { [weak addressesHintIsHiddenSubject] in
                    guard let addressesHintIsHiddenSubject = addressesHintIsHiddenSubject else { return }
                    addressesHintIsHiddenSubject.accept(true)
                })
                .disposed(by: disposeBag)
        }

        private func showCopied() {
            notificationsService.showInAppNotification(.done(L10n.copiedToClipboard))
        }
    }
}
