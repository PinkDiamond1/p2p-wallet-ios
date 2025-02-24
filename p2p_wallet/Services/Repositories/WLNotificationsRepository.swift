//
//  WLNotificationsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/07/2021.
//

import Foundation
import RxSwift
import SolanaSwift

enum WLNotification: Equatable {
    case sent(account: String, lamports: Lamports)
    case received(account: String, lamports: Lamports)
}

protocol WLNotificationsRepository {
    func observeAllNotifications() -> Observable<WLNotification>
}

extension WLNotificationsRepository {
    func observeChange(account: String) -> Observable<WLNotification> {
        observeAllNotifications()
            .filter {
                switch $0 {
                case let .received(receivedAccount, _):
                    return receivedAccount == account
                case let .sent(sentAccount, _):
                    return sentAccount == account
                }
            }
    }
}
