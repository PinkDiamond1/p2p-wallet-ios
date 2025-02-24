//
//  BuyToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/09/2021.
//

import Foundation
import RxCocoa

struct BuyProcessing {}

extension WLSpinnerView: BuyTokenWidgetLoadingView {
    public func startLoading() {
        animate()
    }

    public func stopLoading() {
        stopAnimating()
    }
}
