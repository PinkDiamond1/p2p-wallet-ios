//
//  Onboarding.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa
import LocalAuthentication

protocol OnboardingHandler {
    func onboardingDidCancel()
    func onboardingDidComplete()
}

protocol OnboardingViewModelType {
    var navigatableSceneDriver: Driver<Onboarding.NavigatableScene?> {get}
    
    func savePincode(_ pincode: String)
    
    func getBiometryType() -> LABiometryType
    func authenticateAndEnableBiometry(errorHandler: ((Error) -> Void)?)
    func enableBiometryLater()
    
    func markNotificationsAsSet()
    
    func navigateNext()
    func cancelOnboarding()
    func endOnboarding()
}

extension Onboarding {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var handler: OnboardingHandler
        @Injected private var accountStorage: KeychainAccountStorage
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let bag = DisposeBag()
        private let context = LAContext()
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        
        // MARK: - Initializer
        init() {
            navigateNext()
        }
    }
}

extension Onboarding.ViewModel: OnboardingViewModelType {
    var navigatableSceneDriver: Driver<Onboarding.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Pincode
    func savePincode(_ pincode: String) {
        accountStorage.save(pincode)
        navigateNext()
    }
    
    // MARK: - Biometry
    func getBiometryType() -> LABiometryType {
        context.biometryType
    }
    
    func authenticateAndEnableBiometry(errorHandler: ((Error) -> Void)? = nil) {
        let reason = L10n.identifyYourself

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (success, authenticationError) in

            DispatchQueue.main.async { [weak self] in
                if success {
                    self?.setEnableBiometry(true)
                } else {
                    errorHandler?(authenticationError ?? SolanaSDK.Error.unknown)
                }
            }
        }
    }
    
    func enableBiometryLater() {
        setEnableBiometry(false)
    }
    
    private func setEnableBiometry(_ on: Bool) {
        Defaults.isBiometryEnabled = on
        Defaults.didSetEnableBiometry = true
        analyticsManager.log(event: .setupFaceidClick(faceID: on))
        
        navigateNext()
    }
    
    // MARK: - Notification
    func markNotificationsAsSet() {
        Defaults.didSetEnableNotifications = true
        navigateNext()
    }
    
    // MARK: - Navigation
    func navigateNext() {
        if accountStorage.pinCode == nil {
            navigationSubject.accept(.createPincode)
            return
        }
        
        if !Defaults.didSetEnableBiometry {
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                // evaluate
                navigationSubject.accept(.setUpBiometryAuthentication)
                analyticsManager.log(event: .setupFaceidOpen)
            } else {
                enableBiometryLater()
            }
            return
        }
        
        if !Defaults.didSetEnableNotifications {
            navigationSubject.accept(.setUpNotifications)
            return
        }
        
        endOnboarding()
    }
    
    func cancelOnboarding() {
        navigationSubject.accept(.dismiss)
        handler.onboardingDidCancel()
    }
    
    func endOnboarding() {
        navigationSubject.accept(.dismiss)
        handler.onboardingDidComplete()
    }
}
