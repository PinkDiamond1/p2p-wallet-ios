//
//  ReceiveTokenCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/11/2020.
//

import Foundation

class ReceiveTokenCell: ListCollectionCell<Wallet> {
    lazy var stackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
    lazy var qrCodeView = UIImageView(width: 150, height: 150, backgroundColor: .white)
    lazy var walletNameLabel = UILabel(textSize: 17, weight: .semibold, textAlignment: .center)
    lazy var addressLabel = UILabel(textSize: 13, textColor: .textSecondary, numberOfLines: 0)
    lazy var shareButton: UIButton = {
        let button = UIButton(width: 32, height: 32)
        button.setImage(.walletShare, for: .normal)
        return button
    }()
    lazy var logoImageView: CoinLogoImageView = {
        let imageView = CoinLogoImageView(width: 36, height: 36, cornerRadius: 12)
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.textWhite.cgColor
        return imageView
    }()
    
    override func commonInit() {
        super.commonInit()
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .textWhite
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 57, left: 20, bottom: 52, right: 20))
        
        stackView.addArrangedSubviews([
            qrCodeView.centeredHorizontallyView,
            BEStackViewSpacing(32),
            walletNameLabel,
            BEStackViewSpacing(15),
            UIView.row([
                addressLabel,
                UIView(width: 2, height: 56, backgroundColor: .textWhite),
                shareButton
            ])
                .with(spacing: 16, alignment: .center, distribution: .fill)
                .padding(.init(x: 16, y: 0), backgroundColor: UIColor.textSecondary.withAlphaComponent(0.1), cornerRadius: 12),
            BEStackViewSpacing(24),
            UILabel(text: L10n.allDepositsAreStored100NonCustodiallityWithKeysHeldOnThisDevice, textSize: 13, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center)
        ])
        
        qrCodeView.addSubview(logoImageView)
        logoImageView.autoCenterInSuperview()
    }
    
    func setUp(wallet: Wallet) {
        qrCodeView.setQrCode(string: wallet.pubkey)
        walletNameLabel.text = wallet.name
        addressLabel.text = wallet.pubkeyShort(numOfSymbolsRevealed: 6)
        logoImageView.setUp(wallet: wallet)
    }
}