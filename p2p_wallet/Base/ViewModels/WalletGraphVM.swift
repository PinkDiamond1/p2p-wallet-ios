//
//  WalletGraphVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2020.
//

import Foundation
import RxSwift

class WalletGraphVM: BaseVM<[PriceRecord]> {
    let wallet: Wallet
    var period: Period = .week
    
    init(wallet: Wallet) {
        self.wallet = wallet
        super.init(initialData: [])
    }
    
    override var request: Single<[PriceRecord]> {
        PricesManager.shared.fetchHistoricalPrice(for: wallet.symbol, period: period)
    }
}