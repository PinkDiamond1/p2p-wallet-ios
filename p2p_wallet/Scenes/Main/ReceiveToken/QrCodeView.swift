//
//  QrCodeView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Foundation

class QrCodeView: BEView {
    private let size: CGFloat
    private let coinLogoSize: CGFloat
    
    private lazy var qrCodeView = UIImageView(backgroundColor: .white)
    private lazy var logoImageView: CoinLogoImageView = {
        let imageView = CoinLogoImageView(cornerRadius: 12)
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.textWhite.cgColor
        return imageView
    }()
    
    init(size: CGFloat, coinLogoSize: CGFloat) {
        self.size = size
        self.coinLogoSize = coinLogoSize
        super.init(frame: .zero)
    }
    
    override func commonInit() {
        super.commonInit()
        configureForAutoLayout()
        autoSetDimensions(to: .init(width: size, height: size))
        logoImageView.autoSetDimensions(to: .init(width: coinLogoSize, height: coinLogoSize))
        
        addSubview(qrCodeView)
        qrCodeView.autoPinEdgesToSuperviewEdges()
        
        addSubview(logoImageView)
        logoImageView.autoCenterInSuperview()
    }
    
    func setUp(wallet: Wallet?) {
        qrCodeView.setQrCode(string: wallet?.pubkey)
        logoImageView.setUp(wallet: wallet)
    }
}