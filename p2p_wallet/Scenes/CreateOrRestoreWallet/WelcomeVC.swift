//
//  WelcomeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class WelcomeVC: BEPagesVC, BEPagesVCDelegate {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    let createOrRestoreWalletViewModel: CreateOrRestoreWalletViewModel
    init(createOrRestoreWalletViewModel: CreateOrRestoreWalletViewModel)
    {
        self.createOrRestoreWalletViewModel = createOrRestoreWalletViewModel
    }
    
    override func setUp() {
        super.setUp()
        viewControllers = [
            FirstVC(createOrRestoreWalletViewModel: createOrRestoreWalletViewModel),
            FirstVC(createOrRestoreWalletViewModel: createOrRestoreWalletViewModel),
            FirstVC(createOrRestoreWalletViewModel: createOrRestoreWalletViewModel),
            SecondVC(createOrRestoreWalletViewModel: createOrRestoreWalletViewModel)
        ]
        currentPageIndicatorTintColor = .white
        pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
        
        self.delegate = self
    }
    
    func bePagesVC(_ pagesVC: BEPagesVC, currentPageDidChangeTo currentPage: Int) {
        pageControl.isHidden = false
        if currentPage == viewControllers.count - 1 {
            pageControl.isHidden = true
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }
}

extension WelcomeVC {
    class SlideVC: WLIntroVC {
        lazy var createWalletButton = WLButton.stepButton(type: .blue, label: L10n.createNewWallet.uppercaseFirst)
            .onTap(self, action: #selector(buttonCreateWalletDidTouch))
        lazy var restoreWalletButton = WLButton.stepButton(type: .sub, label: L10n.iVeAlreadyHadAWallet.uppercaseFirst)
            .onTap(self, action: #selector(buttonRestoreWalletDidTouch))
        
        let createOrRestoreWalletViewModel: CreateOrRestoreWalletViewModel
        init(createOrRestoreWalletViewModel: CreateOrRestoreWalletViewModel)
        {
            self.createOrRestoreWalletViewModel = createOrRestoreWalletViewModel
        }
        
        override func setUp() {
            super.setUp()
            
            buttonsStackView.addArrangedSubview(createWalletButton)
            buttonsStackView.addArrangedSubview(restoreWalletButton)
        }
        
        // MARK: - Actions
        @objc func buttonCreateWalletDidTouch() {
            createOrRestoreWalletViewModel.navigationSubject.accept(.createWallet)
        }
        
        @objc func buttonRestoreWalletDidTouch() {
            createOrRestoreWalletViewModel.navigationSubject.accept(.restoreWallet)
        }
    }
    
    class FirstVC: SlideVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .embeded
        }
        
        override func setUp() {
            super.setUp()
            titleLabel.text = L10n.p2PWallet
            descriptionLabel.text = L10n.secureNonCustodialBankOfFuture + "\n" + L10n.simpleFinanceForEveryone
            buttonsStackView.alpha = 0
        }
    }
    
    class SecondVC: SlideVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .embeded
        }
        
        override func setUp() {
            super.setUp()
            titleLabel.text = L10n.p2PWallet
            descriptionLabel.text = L10n.secureNonCustodialBankOfFuture + "\n" + L10n.simpleFinanceForEveryone
        }
    }
}