//
//  WCVHeaderView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation

class WCVSectionHeaderView: UICollectionReusableView {
    lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .center, distribution: .fill)
    
    lazy var headerLabel = UILabel(text: "Wallets", textSize: 17, weight: .bold)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        addSubview(stackView)
        stackView.autoPinEdge(toSuperviewEdge: .top, withInset: 16)
        stackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 16)
        stackView.autoPinEdge(toSuperviewEdge: .leading)
        stackView.autoPinEdge(toSuperviewEdge: .trailing)
        
        stackView.addArrangedSubview(headerLabel)
        headerLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor)
            .isActive = true
    }
}

class WCVFirstSectionHeaderView: WCVSectionHeaderView {
    lazy var priceLabel = UILabel(text: "$120,00", textSize: 36, weight: .semibold, textAlignment: .center)
    lazy var priceChangeLabel = UILabel(text: "+ 0,16 US$ (0,01%) 24 hrs", textSize: 15, textColor: UIColor.textBlack.withAlphaComponent(0.5), numberOfLines: 0, textAlignment: .center)
    
    lazy var sendButton = createButton(title: L10n.send)
    lazy var receiveButton = createButton(title: L10n.receive)
    lazy var swapButton = createButton(title: L10n.swap)
    
    override func commonInit() {
        super.commonInit()
        let buttonsView: UIView = {
            let view = UIView(forAutoLayout: ())
            view.layer.cornerRadius = 16
            view.layer.masksToBounds = true
            let buttonsStackView = UIStackView(axis: .horizontal, spacing: 2, alignment: .fill, distribution: .fillEqually)
            buttonsStackView.addArrangedSubviews([sendButton, receiveButton, swapButton])
            view.addSubview(buttonsStackView)
            buttonsStackView.autoPinEdgesToSuperviewEdges()
            return view
        }()
        
        let spacer1 = UIView.spacer
        stackView.insertArrangedSubview(spacer1, at: 0)
        stackView.insertArrangedSubview(priceLabel, at: 1)
        stackView.insertArrangedSubview(priceChangeLabel, at: 2)
        stackView.insertArrangedSubview(buttonsView, at: 3)
        
        stackView.setCustomSpacing(5, after: priceLabel)
        stackView.setCustomSpacing(30, after: priceChangeLabel)
        stackView.setCustomSpacing(30, after: buttonsView)
    }
    
    // MARK: - Helpers
    func createButton(title: String) -> UIView {
        let view = UIView(height: 56, backgroundColor: .textBlack)
        let label = UILabel(text: title, textSize: 15, weight: .semibold, textColor: .textWhite, numberOfLines: 0, textAlignment: .center)
        view.addSubview(label)
        label.autoPinEdge(toSuperviewEdge: .top)
        label.autoPinEdge(toSuperviewEdge: .bottom)
        label.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
        label.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
        return view
    }
}
