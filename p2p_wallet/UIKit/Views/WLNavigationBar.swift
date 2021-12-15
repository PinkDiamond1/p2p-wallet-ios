//
//  WLNavigationBar.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation

class WLNavigationBar: BEView {
    lazy var stackView = UIStackView(axis: .horizontal, alignment: .center, distribution: .equalCentering, arrangedSubviews: [
        leftItems,
        centerItems,
        rightItemsWrapper
    ])
    
    lazy var leftItems = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
        backButton,
        UIView.spacer
    ])
    lazy var centerItems = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
        titleLabel
    ])
    
    private lazy var rightItemsWrapper = rightItems.padding(.zero.modifying(dRight: 6))
    lazy var rightItems = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
        UIView.spacer
    ])
    
    lazy var backButton = UIImageView(width: 14, height: 24, image: UIImage(systemName: "chevron.left"), tintColor: .h5887ff)
        .padding(.init(x: 6, y: 4))
    lazy var titleLabel = UILabel(textSize: 17, weight: .semibold, numberOfLines: 0, textAlignment: .center)
    
    override func commonInit() {
        super.commonInit()
        stackView.spacing = 8
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 12, y: 8))
        
        leftItems.widthAnchor.constraint(equalTo: rightItemsWrapper.widthAnchor).isActive = true
        
        backgroundColor = .background
    }
    
    func setTitle(_ title: String?) {
        titleLabel.text = title
    }
}

class NewWLNavigationBar: BECompositionView {
    private var backButton: UIView!
    private var title: UILabel!
    
    private let actions: UIView
    
    let initialTitle: String?
    
    init(title: String? = nil) {
        self.initialTitle = title
        self.actions = BEContainer()
        super.init()
    }
    
    init(title: String? = nil, @BEViewBuilder actions: Builder) {
        self.initialTitle = title
        self.actions = actions().build()
        super.init()
    }
    
    @discardableResult
    func onBack(_ callback: @escaping () -> Void) -> Self {
        backButton.onTap {
            print("Back")
            callback()
        }
        return self
    }
    
    override func build() -> UIView {
        UIStackView(axis: .vertical, alignment: .fill) {
            UIStackView(axis: .horizontal, alignment: .center, distribution: .equalCentering) {
                // Back button
                UIImageView(width: 14, height: 24, image: UIImage(systemName: "chevron.left"), tintColor: .h5887ff)
                    .padding(.init(x: 6, y: 4))
                    .setup({ view in
                        self.backButton = view
                        self.backButton.isUserInteractionEnabled = true
                    })
                
                // Title
                UILabel(text: initialTitle, textSize: 17, weight: .semibold, numberOfLines: 0, textAlignment: .center)
                    .setup({ view in self.title = view as! UILabel })
                
                // Actions
                actions
            }.padding(.init(x: 12, y: 8))
            UIView.defaultSeparator()
        }.frame(height: 50)
    }
    
    override func layout() {
        backButton.widthAnchor.constraint(equalTo: actions.widthAnchor).isActive = true
    }
    
}
