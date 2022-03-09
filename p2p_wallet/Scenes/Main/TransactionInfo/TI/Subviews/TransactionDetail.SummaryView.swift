//
//  TransactionDetail.SummaryView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/03/2022.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import SolanaSwift
import BEPureLayout

extension TransactionDetail {
    final class SummaryView: UIStackView {
        private let disposeBag = DisposeBag()
        
        init() {
            super.init(frame: .zero)
            set(axis: .horizontal, spacing: 8, alignment: .center, distribution: .equalCentering)
            
            addArrangedSubviews {
                SubView()
                
                UIImageView(width: 32, height: 32, image: .squircleArrowForward, tintColor: .textSecondary)
                    
                SubView()
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func driven(with driver: Driver<SolanaSDK.ParsedTransaction?>) -> TransactionDetail.SummaryView {
            
            driver
                .drive(onNext: { parsedTransaction in
                    
                })
                .disposed(by: disposeBag)
            
            return self
        }
    }
}

private extension TransactionDetail.SummaryView {
    final class SubView: UIStackView {
        private let logoImageView = CoinLogoImageView(size: 44)
        private let titleLabel = UILabel(text: "0.00227631 renBTC", textSize: 15, numberOfLines: 0, textAlignment: .center)
        private let subtitleLabel = UILabel(text: "~ $150", textSize: 13, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center)
        
        init() {
            super.init(frame: .zero)
            set(axis: .vertical, spacing: 8, alignment: .center, distribution: .fill)
            addArrangedSubviews {
                logoImageView
                titleLabel
                BEStackViewSpacing(0)
                subtitleLabel
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
