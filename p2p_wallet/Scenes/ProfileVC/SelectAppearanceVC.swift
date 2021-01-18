//
//  SelectAppearanceVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/01/2021.
//

import Foundation

@available(iOS 13.0, *)
class SelectAppearanceVC: ProfileSingleSelectionVC<UIUserInterfaceStyle> {
    var interfaceStyle: UIUserInterfaceStyle { AppDelegate.shared.window?.overrideUserInterfaceStyle ?? .unspecified }
    override var dataDidChange: Bool {selectedItem != interfaceStyle}
    
    override init() {
        super.init()
        data = [
            .dark: interfaceStyle == .dark,
            .light: interfaceStyle == .light,
            .unspecified: interfaceStyle == .unspecified
        ]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        title = L10n.appearance
        super.setUp()
    }
    
    override func createCell(item: UIUserInterfaceStyle) -> Cell<UIUserInterfaceStyle> {
        let cell = super.createCell(item: item)
        cell.label.text = item.localizedString
        return cell
    }
    
    override func saveChange() {
        Defaults.appearance = selectedItem
        AppDelegate.shared.window?.overrideUserInterfaceStyle = selectedItem
        AppDelegate.shared.reloadRootVC()
    }
}