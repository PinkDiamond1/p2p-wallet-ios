//
//  RestoreWallet.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/09/2021.
//

import Foundation

struct RestoreWallet {
    enum NavigatableScene {
        case enterPhrases
        case derivableAccounts(phrases: [String])
    }
}