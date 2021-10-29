//
//  OrcaSwapV2.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension OrcaSwapV2 {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var authenticationHandler: AuthenticationHandler
        @Injected private var analyticsManager: AnalyticsManagerType
        private let orcaSwap: OrcaSwapType
        private let walletsRepository: WalletsRepository
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var isSelectingSourceWallet = false // indicate if selecting source wallet or destination wallet
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let loadingStateSubject = BehaviorRelay<LoadableState>(value: .notRequested)
        private let sourceWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let destinationWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let tradablePoolsPairsSubject = LoadableRelay<[OrcaSwap.PoolsPair]>(request: .just([]))
        private let bestPoolsPairSubject = BehaviorRelay<OrcaSwap.PoolsPair?>(value: nil)
        private let inputAmountSubject = BehaviorRelay<Double?>(value: nil)
        private let estimatedAmountSubject = BehaviorRelay<Double?>(value: nil)
        private let feesSubject = LoadableRelay<[PayingFee]>(request: .just([]))
        private let slippageSubject = BehaviorRelay<Double>(value: Defaults.slippage)
        private let isExchangeRateReversedSubject = BehaviorRelay<Bool>(value: false)
        private let payingTokenSubject = BehaviorRelay<PayingToken>(value: .nativeSOL) // FIXME
        private let errorSubject = BehaviorRelay<VerificationError?>(value: nil)
        
        // MARK: - Initializer
        init(
            orcaSwap: OrcaSwapType,
            walletsRepository: WalletsRepository,
            initialWallet: Wallet?
        ) {
            self.orcaSwap = orcaSwap
            self.walletsRepository = walletsRepository
            
            bind(initialWallet: initialWallet)
        }
        
        func bind(initialWallet: Wallet?) {
            // wait until loaded and choose initial wallet
            if let initialWallet = initialWallet {
                loadingStateSubject
                    .take(until: {$0 == .loaded})
                    .take(1)
                    .subscribe(onNext: {[weak self] _ in
                        self?.sourceWalletSubject.accept(initialWallet)
                    })
                    .disposed(by: disposeBag)
            }
            
            // get tradable pools pair for each token pair
            Observable.combineLatest(
                sourceWalletSubject.distinctUntilChanged(),
                destinationWalletSubject.distinctUntilChanged()
            )
                .subscribe(onNext: {[weak self] sourceWallet, destinationWallet in
                    guard let self = self,
                          let sourceWallet = sourceWallet,
                          let destinationWallet = destinationWallet
                    else {
                        self?.tradablePoolsPairsSubject.request = .just([])
                        self?.tradablePoolsPairsSubject.reload()
                        self?.fixPayingToken()
                        return
                    }
                    
                    self.tradablePoolsPairsSubject.request = self.orcaSwap.getTradablePoolsPairs(
                        fromMint: sourceWallet.token.address,
                        toMint: destinationWallet.token.address
                    )
                    self.tradablePoolsPairsSubject.reload()
                    self.fixPayingToken()
                })
                .disposed(by: disposeBag)
            
            // Fill input amount and estimated amount after loaded
            tradablePoolsPairsSubject.stateObservable
                .distinctUntilChanged()
                .filter {$0 == .loaded}
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else {return}
                    if let inputAmount = self.inputAmountSubject.value {
                        self.enterInputAmount(inputAmount)
                    } else if let estimatedAmount = self.estimatedAmountSubject.value {
                        self.enterEstimatedAmount(estimatedAmount)
                    }
                })
                .disposed(by: disposeBag)
            
            // fees
            Observable.combineLatest(
                bestPoolsPairSubject,
                inputAmountSubject,
                slippageSubject
            )
                .map {[weak self] _ in self?.calculateFees() ?? []}
                .subscribe(onNext: {[weak self] fees in
                    self?.feesSubject.request = .just(fees)
                    self?.feesSubject.reload()
                })
                .disposed(by: disposeBag)
            
            // Error
            Observable.combineLatest(
                loadingStateSubject,
                sourceWalletSubject,
                destinationWalletSubject,
                tradablePoolsPairsSubject.stateObservable,
                bestPoolsPairSubject,
                feesSubject.valueObservable,
                slippageSubject,
                payingTokenSubject
            )
                .map {[weak self] _ in self?.verify() }
                .bind(to: errorSubject)
                .disposed(by: disposeBag)
        }
        
        func authenticateAndSwap() {
            authenticationHandler.authenticate(
                presentationStyle:
                    .init(
                        isRequired: false,
                        isFullScreen: false,
                        completion: { [weak self] in
                            self?.swap()
                        }
                    )
            )
        }
        
        func swap() {
            guard verify() == nil else {return}
            
            let sourceWallet = sourceWalletSubject.value!
            let destinationWallet = destinationWalletSubject.value!
            let bestPoolsPair = bestPoolsPairSubject.value!
            let inputAmount = inputAmountSubject.value!
            let estimatedAmount = estimatedAmountSubject.value!
            
            // log
            analyticsManager.log(
                event: .swapSwapClick(
                    tokenA: sourceWallet.token.symbol,
                    tokenB: destinationWallet.token.symbol,
                    sumA: inputAmount,
                    sumB: estimatedAmount
                )
            )
            
            // form request
            let request = orcaSwap.swap(
                fromWalletPubkey: sourceWallet.pubkey!,
                toWalletPubkey: destinationWallet.pubkey,
                bestPoolsPair: bestPoolsPair,
                amount: inputAmount,
                slippage: slippageSubject.value,
                isSimulation: false
            )
                .map {$0 as ProcessTransactionResponseType}
            
            // show processing scene
            navigationSubject.accept(
                .processTransaction(
                    request: request,
                    transactionType: .orcaSwap(
                        from: sourceWallet,
                        to: destinationWallet,
                        inputAmount: inputAmount.toLamport(decimals: sourceWallet.token.decimals),
                        estimatedAmount: estimatedAmount.toLamport(decimals: destinationWallet.token.decimals),
                        fees: feesSubject.value?.filter {$0.type != .liquidityProviderFee} ?? []
                    )
                )
            )
        }
    }
}

extension OrcaSwapV2.ViewModel: OrcaSwapV2ViewModelType {
    var navigationDriver: Driver<OrcaSwapV2.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var loadingStateDriver: Driver<LoadableState> {
        loadingStateSubject.asDriver()
    }
    
    var sourceWalletDriver: Driver<Wallet?> {
        sourceWalletSubject.asDriver().distinctUntilChanged()
    }
    
    var destinationWalletDriver: Driver<Wallet?> {
        destinationWalletSubject.asDriver().distinctUntilChanged()
    }
    
    var isTokenPairValidDriver: Driver<Loadable<Bool>> {
        tradablePoolsPairsSubject.asDriver()
            .map { value, state, reloadAction in
                (value?.isEmpty == false, state, reloadAction)
            }
    }
    
    var bestPoolsPairDriver: Driver<OrcaSwap.PoolsPair?> {
        bestPoolsPairSubject.asDriver()
    }
    
    var inputAmountDriver: Driver<Double?> {
        inputAmountSubject.asDriver()
    }
    
    var estimatedAmountDriver: Driver<Double?> {
        estimatedAmountSubject.asDriver()
    }
    
    var feesDriver: Driver<Loadable<[PayingFee]>> {
        feesSubject.asDriver()
    }
    
    var availableAmountDriver: Driver<Double?> {
        Driver.combineLatest(
            sourceWalletDriver,
            destinationWalletDriver,
            feesDriver
        )
            .map {[weak self] _ in self?.calculateAvailableAmount()}
    }
    
    var slippageDriver: Driver<Double> {
        slippageSubject.asDriver()
    }
    
    var minimumReceiveAmountDriver: Driver<Double?> {
        bestPoolsPairSubject
            .withLatestFrom(
                Observable.combineLatest(
                    inputAmountSubject,
                    slippageSubject,
                    sourceWalletSubject,
                    destinationWalletSubject
                )
            ) { ($0, $1.0, $1.1, $1.2, $1.3) }
            .map { poolsPair, inputAmount, slippage, sourceWallet, destinationWallet in
                guard let poolsPair = poolsPair,
                      let sourceDecimals = sourceWallet?.token.decimals,
                      let inputAmount = inputAmount?.toLamport(decimals: sourceDecimals),
                      let destinationDecimals = destinationWallet?.token.decimals
                else {return nil}
                return poolsPair.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)?.convertToBalance(decimals: destinationDecimals)
            }
            .asDriver(onErrorJustReturn: nil)
    }
    
    var exchangeRateDriver: Driver<Double?> {
        Observable.combineLatest(
            inputAmountSubject,
            estimatedAmountSubject,
            isExchangeRateReversedSubject
        )
            .map { inputAmount, estimatedAmount, isReversed in
                guard let inputAmount = inputAmount,
                      let estimatedAmount = estimatedAmount,
                      inputAmount > 0,
                      estimatedAmount > 0
                else {return nil}
                return isReversed ? inputAmount / estimatedAmount: estimatedAmount / inputAmount
            }
            .asDriver(onErrorJustReturn: nil)
    }
    
    var isExchangeRateReversed: Driver<Bool> {
        isExchangeRateReversedSubject.asDriver()
    }
    
    var payingTokenDriver: Driver<PayingToken> {
        payingTokenSubject.asDriver()
    }
    
    var errorDriver: Driver<OrcaSwapV2.VerificationError?> {
        errorSubject.asDriver()
    }
    
    // MARK: - Actions
    func reload() {
        loadingStateSubject.accept(.loading)
        orcaSwap.load()
            .subscribe(onCompleted: { [weak self] in
                self?.loadingStateSubject.accept(.loaded)
            }, onError: {error in
                self.loadingStateSubject.accept(.error(error.readableDescription))
            })
            .disposed(by: disposeBag)
    }
    
    func log(_ event: AnalyticsEvent) {
        analyticsManager.log(event: event)
    }
    
    func navigate(to scene: OrcaSwapV2.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func chooseSourceWallet() {
        isSelectingSourceWallet = true
        navigationSubject.accept(.chooseSourceWallet)
    }
    
    func chooseDestinationWallet() {
        var destinationMints = [String]()
        if let sourceWallet = sourceWalletSubject.value,
           let validMints = try? orcaSwap.findPosibleDestinationMints(fromMint: sourceWallet.token.address)
        {
            destinationMints = validMints
        }
        isSelectingSourceWallet = false
        navigationSubject.accept(.chooseDestinationWallet(validMints: Set(destinationMints), excludedSourceWalletPubkey: sourceWalletSubject.value?.pubkey))
    }
    
    func swapSourceAndDestination() {
        let source = sourceWalletSubject.value
        sourceWalletSubject.accept(destinationWalletSubject.value)
        destinationWalletSubject.accept(source)
    }
    
    func retryLoadingRoutes() {
        tradablePoolsPairsSubject.reload()
    }
    
    func walletDidSelect(_ wallet: Wallet) {
        if isSelectingSourceWallet {
            analyticsManager.log(event: .swapTokenASelectClick(tokenTicker: wallet.token.symbol))
            sourceWalletSubject.accept(wallet)
        } else {
            analyticsManager.log(event: .swapTokenBSelectClick(tokenTicker: wallet.token.symbol))
            destinationWalletSubject.accept(wallet)
        }
    }
    
    func useAllBalance() {
        let availableAmount = calculateAvailableAmount()
        enterInputAmount(availableAmount)
        
        // fees depends on input amount, so after entering availableAmount, fees has changed, so needed to calculate availableAmount again
        let availableAmountUpdated = calculateAvailableAmount()
        enterInputAmount(availableAmountUpdated)
    }
    
    func enterInputAmount(_ amount: Double?) {
        inputAmountSubject.accept(amount)
        
        // calculate estimated amount
        if let sourceDecimals = sourceWalletSubject.value?.token.decimals,
           let destinationDecimals = destinationWalletSubject.value?.token.decimals,
           let inputAmount = amount?.toLamport(decimals: sourceDecimals),
           let poolsPairs = tradablePoolsPairsSubject.value,
           let bestPoolsPair = try? orcaSwap.findBestPoolsPairForInputAmount(inputAmount, from: poolsPairs),
           let bestEstimatedAmount = bestPoolsPair.getOutputAmount(fromInputAmount: inputAmount)
        {
            estimatedAmountSubject.accept(bestEstimatedAmount.convertToBalance(decimals: destinationDecimals))
            bestPoolsPairSubject.accept(bestPoolsPair)
        } else {
            estimatedAmountSubject.accept(nil)
            bestPoolsPairSubject.accept(nil)
        }
    }
    
    func enterEstimatedAmount(_ amount: Double?) {
        estimatedAmountSubject.accept(amount)
        
        // calculate input amount
        if let sourceDecimals = sourceWalletSubject.value?.token.decimals,
           let destinationDecimals = destinationWalletSubject.value?.token.decimals,
           let estimatedAmount = amount?.toLamport(decimals: destinationDecimals),
           let poolsPairs = tradablePoolsPairsSubject.value,
           let bestPoolsPair = try? orcaSwap.findBestPoolsPairForEstimatedAmount(estimatedAmount, from: poolsPairs),
           let bestInputAmount = bestPoolsPair.getInputAmount(fromEstimatedAmount: estimatedAmount)
        {
            inputAmountSubject.accept(bestInputAmount.convertToBalance(decimals: sourceDecimals))
            bestPoolsPairSubject.accept(bestPoolsPair)
        } else {
            inputAmountSubject.accept(nil)
            bestPoolsPairSubject.accept(nil)
        }
    }
    
    func changeSlippage(to slippage: Double) {
        Defaults.slippage = slippage
        slippageSubject.accept(slippage)
    }
    
    func reverseExchangeRate() {
        isExchangeRateReversedSubject.accept(!isExchangeRateReversedSubject.value)
    }
    
    func changePayingToken(to payingToken: PayingToken) {
        Defaults.payingToken = payingToken
        fixPayingToken()
    }
}

// MARK: - Helpers
private extension OrcaSwapV2.ViewModel {
    func fixPayingToken() {
        // TODO: - Later
//        var payingToken = Defaults.payingToken
//
//        // Force using native sol when source or destination is nativeSOL
//        if sourceWalletSubject.value?.isNativeSOL == true ||
//            destinationWalletSubject.value?.isNativeSOL == true // FIXME: - Fee relayer will support case where destination is native sol
//        {
//            payingToken = .nativeSOL
//        }
//
//        payingTokenSubject.accept(payingToken)
    }
    
    /// Verify error in current context IN ORDER
    /// - Returns: String or nil if no error
    func verify() -> OrcaSwapV2.VerificationError? {
        // loading state
        if loadingStateSubject.value != .loaded {
            return .swappingIsNotAvailable
        }
        
        // source wallet
        guard let sourceWallet = sourceWalletSubject.value else {
            return .sourceWalletIsEmpty
        }
        
        // destination wallet
        guard let destinationWallet = destinationWalletSubject.value else {
            return .destinationWalletIsEmpty
        }
        
        // prevent swap the same token
        if sourceWallet.token.address == destinationWallet.token.address {
            return .canNotSwapToItSelf
        }
        
        // pools pairs
        if tradablePoolsPairsSubject.state != .loaded {
            return .tradablePoolsPairsNotLoaded
        }
        
        if tradablePoolsPairsSubject.value == nil ||
            tradablePoolsPairsSubject.value?.isEmpty == true
        {
            return .tradingPairNotSupported
        }
        
        // inputAmount
        guard let inputAmount = inputAmountSubject.value else {
            return .inputAmountIsEmpty
        }
        
        if inputAmount.rounded(decimals: sourceWallet.token.decimals) <= 0 {
            return .inputAmountIsNotValid
        }
        
        if inputAmount > calculateAvailableAmount() {
            return .insufficientFunds
        }
        
        // estimated amount
        guard let estimatedAmount = estimatedAmountSubject.value else {
            return .estimatedAmountIsNotValid
        }
        
        if estimatedAmount.rounded(decimals: destinationWallet.token.decimals) <= 0 {
            return .estimatedAmountIsNotValid
        }
        
        // best pools pairs
        if bestPoolsPairSubject.value == nil {
            return .bestPoolsPairsIsEmpty
        }
        
        // fees
        if feesSubject.state.isError {
            return .couldNotCalculatingFees
        }
        
        guard let fees = feesSubject.value?.totalFee?.lamports else {
            return .feesIsBeingCalculated
        }
        
        // paying with SOL
        if payingTokenSubject.value == .nativeSOL {
            guard let wallet = walletsRepository.nativeWallet else {
                return .nativeWalletNotFound
            }
            
            if fees > (wallet.lamports ?? 0) {
                return .notEnoughSOLToCoverFees
            }
        }
        
        // paying with SPL token
        else {
            // TODO: - fee compensation
            //                if feeCompensationPool == nil {
            //                    return L10n.feeCompensationPoolNotFound
            //                }
            if fees > (sourceWallet.lamports ?? 0) {
                return .notEnoughBalanceToCoverFees
            }
        }
        
        // slippage
        if !isSlippageValid() {
            return .slippageIsNotValid
        }
        
        return nil
    }
    
    private func calculateAvailableAmount() -> Double? {
        guard let sourceWallet = sourceWalletSubject.value,
              let fees = feesSubject.value?.totalFee?.lamports
        else {return sourceWalletSubject.value?.amount}
        
        // paying with native wallet
        if payingTokenSubject.value == .nativeSOL && !sourceWallet.isNativeSOL {
            return sourceWallet.amount
        }
        
        // paying with wallet itself
        else {
            let availableAmount = (sourceWallet.amount ?? 0) - fees.convertToBalance(decimals: sourceWallet.token.decimals)
            return availableAmount > 0 ? availableAmount: 0
        }
    }
    
    private func isSlippageValid() -> Bool {
        slippageSubject.value <= .maxSlippage && slippageSubject.value > 0
    }
    
    private func calculateFees() -> [PayingFee] {
        guard let sourceWallet = sourceWalletSubject.value,
              let sourceWalletPubkey = sourceWallet.pubkey
        else {return []}
        
        let destinationWallet = destinationWalletSubject.value
        let bestPoolsPair = bestPoolsPairSubject.value
        let inputAmount = inputAmountSubject.value
        let myWalletsMints = walletsRepository.getWallets().compactMap {$0.token.address}
        
        guard let fees = try? orcaSwap.getFees(
            myWalletsMints: myWalletsMints,
            fromWalletPubkey: sourceWalletPubkey,
            toWalletPubkey: destinationWallet?.pubkey,
            feeRelayerFeePayerPubkey: nil, // TODO: - Fee relayer
            bestPoolsPair: bestPoolsPair,
            inputAmount: inputAmount,
            slippage: slippageSubject.value,
            lamportsPerSignature: 5000,
            minRentExempt: 2039280
        ) else {return []}
        
        let liquidityProviderFees: [PayingFee]
        
        if let destinationWallet = destinationWallet {
            if fees.liquidityProviderFees.count == 1 {
                liquidityProviderFees = [.init(type: .liquidityProviderFee, lamports: fees.liquidityProviderFees.first!, token: destinationWallet.token)
                ]
            } else if fees.liquidityProviderFees.count == 2 {
                liquidityProviderFees = [.init(type: .liquidityProviderFee, lamports: fees.liquidityProviderFees.last!, token: destinationWallet.token)
                ]
            } else {
                liquidityProviderFees = []
            }
        } else {
            liquidityProviderFees = []
        }
        
        return liquidityProviderFees + [.init(type: .transactionFee, lamports: fees.transactionFees, token: .nativeSolana)]
    }
}