//
// Created by Giang Long Tran on 19.04.2022.
//

import Foundation
import SolanaSwift

/// This protocol that maps, updates, filters and forms the output of transactions.
protocol HistoryOutput {
    /// Transform incoming data
    ///
    /// - Parameter newData: incoming data
    /// - Returns: transformed data
    func process(newData: [SolanaSDK.ParsedTransaction]) -> [SolanaSDK.ParsedTransaction]
}
