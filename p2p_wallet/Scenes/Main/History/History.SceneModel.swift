//
// Created by Giang Long Tran on 12.04.2022.
//

import BECollectionView
import FeeRelayerSwift
import Foundation
import RxCocoa
import RxSwift
import SolanaSwift

extension History {
    class SceneModel: BEStreamListViewModel<SolanaSDK.ParsedTransaction> {
        private let disposeBag = DisposeBag()

        private let solanaSDK: SolanaSDK
        private let walletsRepository: WalletsRepository
        @Injected private var notificationService: NotificationsService

        let transactionRepository = SolanaTransactionRepository()
        let transactionParser = DefaultTransactionParser(p2pFeePayers: Defaults.p2pFeePayerPubkeys)

        /// Refresh handling
        private let refreshTriggers: [HistoryRefreshTrigger] = [
            PriceRefreshTrigger(),
            ProcessingTransactionRefreshTrigger(),
        ]

        /// A list of source, where data can be fetched
        private var source: HistoryStreamSource = EmptyStreamSource()

        /// A list of output objects, that builds, forms, maps, filters and updates a final list.
        /// This list will be delivered to UI layer.
        private let outputs: [HistoryOutput] = [
            ProcessingTransactionsOutput(),
            PriceUpdatingOutput(),
        ]

        var showItems: Driver<Bool> {
            Observable.zip(
                stateObservable.startWith(.loading),
                dataObservable.startWith([])
                    .filter { $0 != nil }
                    .withPrevious()
            ).map { state, change in
                if state == .loading || state == .initializing {
                    return true
                } else {
                    let amount = change.1?.reduce(0) { partialResult, wallet in
                        partialResult + wallet.amount
                    } ?? 0
                    return amount > 0
                }
            }
            .distinctUntilChanged { $0 }
            .asDriver(onErrorJustReturn: true)
        }

        init(
            solanaSDK: SolanaSDK = Resolver.resolve(),
            walletsRepository: WalletsRepository = Resolver.resolve()
        ) {
            self.solanaSDK = solanaSDK
            self.walletsRepository = walletsRepository

            super.init(isPaginationEnabled: true, limit: 10)

            // Register all refresh triggers
            for trigger in refreshTriggers {
                trigger.register()
                    .emit(onNext: { [weak self] in self?.refreshUI() })
                    .disposed(by: disposeBag)
            }

            // Build source
            buildSource()
        }

        func buildSource() {
            let cachedTransactionRepository: CachingTransactionRepository = .init(
                delegate: SolanaTransactionRepository()
            )
            let cachedTransactionParser: CachingTransactionParsing = .init(
                delegate: DefaultTransactionParser(p2pFeePayers: Defaults.p2pFeePayerPubkeys)
            )

            let accountStreamSources = walletsRepository
                .getWallets()
                .map { wallet in
                    AccountStreamSource(
                        account: wallet.pubkey ?? "",
                        accountSymbol: wallet.token.symbol,
                        transactionRepository: cachedTransactionRepository,
                        transactionParser: cachedTransactionParser
                    )
                }

            source = MultipleStreamSource(sources: accountStreamSources)
        }

        override func clear() {
            // Build source
            buildSource()

            super.clear()
        }

        override func next() -> Observable<[SolanaSDK.ParsedTransaction]> {
            AsyncThrowingStream<[SolanaSDK.SignatureInfo], Error> { stream in
                Task {
                    defer { stream.finish(throwing: nil) }

                    do {
                        var receivedItem = 0
                        while true {
                            let firstTrx = try await source.first()
                            guard
                                let firstTrx = firstTrx,
                                let rawTime = firstTrx.blockTime
                            else { return }

                            // Fetch next 3 days
                            var timeEndFilter = Date(timeIntervalSince1970: TimeInterval(rawTime))
                            timeEndFilter = timeEndFilter.addingTimeInterval(-1 * 60 * 60 * 24 * 3)

                            for try await signatureInfo in source.next(
                                configuration: .init(timestampEnd: timeEndFilter)
                            ) {
                                // Skip duplicated transaction
                                if data.contains(where: { $0.signature == signatureInfo.signature }) { continue }

                                stream.yield([signatureInfo])

                                receivedItem += 1
                                if receivedItem > 15 { return }
                            }
                        }
                    } catch {
                        stream.finish(throwing: error)
                    }
                }
            }
            .asObservable()
            .flatMap { infos in Observable.from(infos) }
            .observe(on: SceneModel.historyFetchingScheduler)
            .flatMap { signatureInfo in
                Observable.asyncThrowing { () -> [SolanaSDK.ParsedTransaction] in
                    let transactionInfo = try await self.transactionRepository
                        .getTransaction(signature: signatureInfo.signature)
                    let transaction = try await self.transactionParser.parse(
                        signatureInfo: signatureInfo,
                        transactionInfo: transactionInfo,
                        account: nil,
                        symbol: nil
                    )

                    return [transaction]
                }
            }
            .do(onError: { [weak self] error in
                DispatchQueue.main.async {
                    self?.notificationService.showInAppNotification(.error(error))
                }
            })
        }

        static let historyFetchingScheduler =
            SerialDispatchQueueScheduler(internalSerialQueueName: "HistoryTransactionFetching")

        override func join(_ newItems: [SolanaSDK.ParsedTransaction]) -> [SolanaSDK.ParsedTransaction] {
            var filteredNewData: [SolanaSDK.ParsedTransaction] = []
            for trx in newItems {
                if data.contains(where: { $0.signature == trx.signature }) { continue }
                filteredNewData.append(trx)
            }
            return data + filteredNewData
        }

        override func map(newData: [SolanaSDK.ParsedTransaction]) -> [SolanaSDK.ParsedTransaction] {
            // Apply output transformation
            var data = newData
            for output in outputs { data = output.process(newData: data) }
            return super.map(newData: data)
        }
    }
}
