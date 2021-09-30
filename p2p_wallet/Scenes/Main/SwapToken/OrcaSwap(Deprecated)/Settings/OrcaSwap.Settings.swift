//
//  OrcaSwap.Settings.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/08/2021.
//

import Foundation
import RxCocoa

extension OrcaSwap {
    // Forward to NewSwap, remove later
    typealias SettingsNavigationController = SwapToken.SettingsNavigationController
    typealias SettingsBaseViewController = SwapToken.SettingsBaseViewController
    typealias SettingsViewController = SwapToken.SettingsViewController
    typealias SlippageSettingsViewController = SwapToken.SlippageSettingsViewController
    typealias NetworkFeePayerSettingsViewController = SwapToken.NetworkFeePayerSettingsViewController
    typealias SwapFeesViewController = SwapToken.SwapFeesViewController
}

extension OrcaSwap.ViewModel: SwapTokenSettingsViewModelType {
    var sourceWalletDriver: Driver<Wallet?> {
        output.sourceWallet
    }
    
    var destinationWalletDriver: Driver<Wallet?> {
        output.destinationWallet
    }
    
    var slippageDriver: Driver<Double?> {
        output.slippage.map(Optional.init)
    }
    
    func changeSlippage(to slippage: Double) {
        input.slippage.accept(slippage)
    }
}

extension OrcaSwap.ViewModel: SwapTokenSwapFeesViewModelType {
    var feesDriver: Driver<Loadable<[SwapToken.Fee]>> {
        Driver.combineLatest(
            output.feeInLamports,
            output.liquidityProviderFee,
            output.sourceWallet,
            output.destinationWallet
        )
            .map {fee, liquidityProviderFee, source, destination in
                var result = [SwapToken.Fee]()
                guard let source = source, let destination = destination
                else {return (value: result, state: .loaded, reloadAction: nil)}

                if let fee = liquidityProviderFee {
                    result.append(
                        .init(
                            type: .liquidityProviderFee,
                            lamports: fee.toLamport(decimals: destination.token.decimals),
                            token: destination.token,
                            toString: nil
                        )
                    )
                }

                if let fee = fee {
                    if OrcaSwap.isFeeRelayerEnabled(source: source, destination: destination) {
                        result.append(
                            .init(
                                type: .networkFee,
                                lamports: fee,
                                token: source.token,
                                toString: nil
                            )
                        )
                    } else {
                        result.append(
                            .init(
                                type: .networkFee,
                                lamports: fee,
                                token: .nativeSolana,
                                toString: nil
                            )
                        )
                    }
                }

                return (value: result, state: .loaded, reloadAction: nil)
            }
    }
}
