//
//  RecipientsListViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/10/2021.
//

import BECollectionView
import Foundation
import NameService
import Resolver
import RxSwift

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    class RecipientsListViewModel: BEListViewModel<SendToken.Recipient> {
        // MARK: - Dependencies

        @Injected private var nameService: NameService
        var solanaAPIClient: SendServiceType!
        var preSelectedNetwork: SendToken.Network!

        // MARK: - Properties

        var searchString: String?

        private let addressSize = 44
        var isSearchingByAddress: Bool {
            searchString?
                .matches(oneOfRegexes: .bitcoinAddress(isTestnet: solanaAPIClient.isTestNet()), .publicKey) == true
        }

        // MARK: - Methods

        /// The only methods that MUST be inheritted
        override func createRequest() -> Single<[SendToken.Recipient]> {
            guard let searchString = searchString, !searchString.isEmpty else { return .just([]) }

            // force find by address when network is bitcoin
            return preSelectedNetwork == .bitcoin || isSearchingByAddress
                ? findRecipientBy(address: searchString)
                : findRecipientsBy(name: searchString)
        }

        private func findRecipientsBy(name: String) -> Single<[SendToken.Recipient]> {
            Single.async { [weak self] in
                guard let self = self else { throw NameServiceError.unknown }
                let owners = try await self.nameService.getOwners(name)
                return owners.map {
                    .init(
                        address: $0.owner,
                        name: $0.name,
                        hasNoFunds: false
                    )
                }
            }
        }

        private func findRecipientBy(address: String) -> Single<[SendToken.Recipient]> {
            switch preSelectedNetwork {
            case .bitcoin:
                return findAddressInBitcoinNetwork(address: address)
            case .solana:
                return findAddressInSolanaNetwork(address: address)
            case .none:
                if address.matches(oneOfRegexes: .bitcoinAddress(isTestnet: solanaAPIClient.isTestNet())) {
                    return findAddressInBitcoinNetwork(address: address)
                } else {
                    return findAddressInSolanaNetwork(address: address)
                }
            }
        }

        private func findAddressInBitcoinNetwork(address: String) -> Single<[SendToken.Recipient]> {
            if address.matches(oneOfRegexes: .bitcoinAddress(isTestnet: solanaAPIClient.isTestNet())) {
                return .just([.init(address: address, name: nil, hasNoFunds: false)])
            } else {
                return .just([])
            }
        }

        private func findAddressInSolanaNetwork(address: String) -> Single<[SendToken.Recipient]> {
            Single<Bool>.async { [weak self] in
                (try? await self?.solanaAPIClient.checkAccountValidation(account: address)) ?? false
            }.map {
                [
                    .init(
                        address: address,
                        name: nil,
                        hasNoFunds: $0
                    ),
                ]
            }
        }
    }
}
