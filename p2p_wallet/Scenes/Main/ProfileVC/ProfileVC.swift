//
//  ProfileVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/12/20.
//

import Foundation
import SwiftyUserDefaults
import LocalAuthentication
import SwiftUI

protocol ProfileScenesFactory {
    func makeBackupVC() -> BackupVC
    func makeSelectNetworkVC() -> SelectNetworkVC
    func makeConfigureSecurityVC() -> ConfigureSecurityVC
    func makeSelectLanguageVC() -> SelectLanguageVC
    func makeSelectAppearanceVC() -> SelectAppearanceVC
}

class ProfileVC: ProfileVCBase {
    lazy var secureMethodsLabel = UILabel(textSize: 15, weight: .medium, textColor: .textSecondary)
    lazy var activeLanguageLabel = UILabel(textSize: 15, weight: .medium, textColor: .textSecondary)
    lazy var appearanceLabel = UILabel(textSize: 15, weight: .medium, textColor: .textSecondary)
    lazy var networkLabel = UILabel(textSize: 15, weight: .medium, textColor: .textSecondary)
    
    var disposables = [DefaultsDisposable]()
    let rootViewModel: RootViewModel
    let scenesFactory: ProfileScenesFactory
    
    init(rootViewModel: RootViewModel, scenesFactory: ProfileScenesFactory) {
        self.scenesFactory = scenesFactory
        self.rootViewModel = rootViewModel
    }
    
    deinit {
        disposables.forEach {$0.dispose()}
    }
    
    // MARK: - Methods
    override func setUp() {
        title = L10n.profile
        
        super.setUp()
        
        stackView.addArrangedSubviews([
            createCell(text: L10n.backup, descriptionView: UIImageView(width: 17, height: 21, image: .backupShield, tintColor: .textSecondary)
            )
                .withTag(1)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            createCell(text: L10n.network, descriptionView: networkLabel)
                .withTag(2)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            createCell(text: L10n.security, descriptionView: secureMethodsLabel
            )
                .withTag(3)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            createCell(text: L10n.language, descriptionView: activeLanguageLabel
            )
                .withTag(4)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            createCell(
                text: L10n.appearance,
                descriptionView: appearanceLabel
            )
                .withTag(5)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            UIButton(label: L10n.logout, labelFont: .systemFont(ofSize: 15), textColor: .textSecondary)
                .onTap(self, action: #selector(buttonLogoutDidTouch))
        ])
        
        setUp(enabledBiometry: Defaults.isBiometryEnabled)
        
        setUp(network: Defaults.network)
        
        setUp(theme: AppDelegate.shared.window?.overrideUserInterfaceStyle)
        
        activeLanguageLabel.text = Locale.current.uiLanguageLocalizedString?.uppercaseFirst
    }
    
    override func bind() {
        super.bind()
        
        disposables.append(Defaults.observe(\.isBiometryEnabled) { update in
            self.setUp(enabledBiometry: update.newValue)
        })
        
        disposables.append(Defaults.observe(\.network){ update in
            self.setUp(network: update.newValue)
        })
    }
    
    func setUp(enabledBiometry: Bool?) {
        var text = ""
        if enabledBiometry == true {
            text += LABiometryType.current.stringValue + ", "
        }
        text += L10n.pinCode
        secureMethodsLabel.text = text
    }
    
    func setUp(network: SolanaSDK.Network?) {
        networkLabel.text = network?.cluster
    }
    
    func setUp(theme: UIUserInterfaceStyle?) {
        appearanceLabel.text = theme?.localizedString
    }
    
    override func createHeaderView() -> UIStackView {
        let headerView = super.createHeaderView()
        headerView.arrangedSubviews.first?.removeFromSuperview()
        headerView.insertArrangedSubview(.spacer, at: 0)
        return headerView
    }
    
    // MARK: - Actions
    @objc func buttonLogoutDidTouch() {
        showAlert(title: L10n.logout, message: L10n.doYouReallyWantToLogout, buttonTitles: ["OK", L10n.cancel], highlightedButtonIndex: 1) { (index) in
            if index == 0 {
                self.dismiss(animated: true) {
                    self.rootViewModel.logout()
                }
            }
        }
    }
    
    override func buttonDoneDidTouch() {
        back()
    }
    
    @objc func cellDidTouch(_ gesture: UIGestureRecognizer) {
        guard let tag = gesture.view?.tag else {return}
        switch tag {
        case 1:
            let vc = scenesFactory.makeBackupVC()
            show(vc, sender: nil)
        case 2:
            let vc = scenesFactory.makeSelectNetworkVC()
            show(vc, sender: nil)
        case 3:
            let vc = scenesFactory.makeConfigureSecurityVC()
            show(vc, sender: nil)
        case 4:
            let vc = scenesFactory.makeSelectLanguageVC()
            show(vc, sender: nil)
        case 5:
            let vc = scenesFactory.makeSelectAppearanceVC()
            show(vc, sender: nil)
        default:
            return
        }
    }
    
    // MARK: - Helpers
    private func createCell(text: String, descriptionView: UIView) -> UIStackView
    {
        let stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
            UIImageView(width: 44, height: 44, backgroundColor: .textSecondary, cornerRadius: 22),
            UILabel(text: text, textSize: 15),
            descriptionView,
            UIImageView(width: 4.5, height: 9, image: .nextArrow, tintColor: .textBlack)
        ])
        stackView.setCustomSpacing(12, after: descriptionView)
        return stackView
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            setUp(theme: traitCollection.userInterfaceStyle)
        }
    }
}