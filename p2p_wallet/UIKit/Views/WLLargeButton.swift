//
// Created by Giang Long Tran on 09.12.21.
//

import Foundation
import BEPureLayout

class WLLargeButton: BECompositionView {
    let child: UIView
    
    required init(@BEViewBuilder builder: Builder) {
        child = builder().build()
        super.init(frame: .zero)
    }
    
    override func build() -> UIView {
        BEContainer {
            child
                .border(width: 1, color: .f2f2f7)
                .box(cornerRadius: 12)
                .lightShadow()
        }
    }
}