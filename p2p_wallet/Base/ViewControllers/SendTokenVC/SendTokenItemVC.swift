//
//  SendTokenItemVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/11/2020.
//

import Foundation

class SendTokenItemVC: BaseVC {
    lazy var tokenNameLabel = UILabel(text: "TOKEN", weight: .semibold)
    lazy var coinImageView = UIImageView(width: 44, height: 44, backgroundColor: .gray, cornerRadius: 22)
    lazy var amountTextField = UITextField(font: .systemFont(ofSize: 27, weight: .semibold), textColor: .textBlack, keyboardType: .decimalPad, placeholder: "0.0", autocorrectionType: .no)
    lazy var equityValueLabel = UILabel(text: "=", textSize: 13, textColor: .secondary)
    lazy var addressLabel = UILabel(textSize: 15, textColor: .black, numberOfLines: 0)
    lazy var qrCodeImageView = UIImageView(width: 18, height: 18, image: .scanQr, tintColor: UIColor.black.withAlphaComponent(0.5))
    
    lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .clear
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        let amountView: UIStackView = {
            let stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill)
            let downArrowImage = UIImageView(width: 11, height: 8, image: .downArrow)
            downArrowImage.tintColor = .textBlack
            
            let amountVStack: UIStackView = {
                let stackView = UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill)
                stackView.addArrangedSubviews([.spacer, amountTextField, equityValueLabel])
                return stackView
            }()
            
            stackView.addArrangedSubviews([
                coinImageView,
                downArrowImage,
                amountVStack
            ])
            amountTextField.autoAlignAxis(.horizontal, toSameAxisOf: coinImageView)
            return stackView
        }()
        
        let separator = UIView.separator(height: 2, color: view.backgroundColor!)
        
        let addressView: UIStackView = {
            let stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
            let containerView: UIView = {
                let view = UIView(backgroundColor: .c4c4c4, cornerRadius: 16)
                let stackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill)
                view.addSubview(stackView)
                stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(all: 20))
                stackView.addArrangedSubviews([addressLabel, qrCodeImageView])
                return view
            }()
            stackView.addArrangedSubviews([
                UILabel(text: L10n.walletAddress, textSize: 15, weight: .semibold),
                containerView
            ])
            return stackView
        }()
        
        stackView.addArrangedSubviews([
            .spacer,
            tokenNameLabel.padding(UIEdgeInsets(x: 16, y: 0)),
            amountView.padding(UIEdgeInsets(x: 16, y: 0)),
            separator,
            addressView.padding(UIEdgeInsets(x: 16, y: 0)),
            .spacer
        ])
        stackView.setCustomSpacing(16, after: tokenNameLabel.wrapper!)
        stackView.setCustomSpacing(30, after: separator)
    }
    
    func setUp(token: SolanaSDK.Token) {
        tokenNameLabel.text = token.name
        coinImageView.setImage(urlString: token.icon)
        addressLabel.text = token.mintAddress
    }
}