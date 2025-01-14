//
//  Onboarding.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import AnalyticsManager
import LocalAuthentication
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift
import UIKit
import UserNotifications

protocol OnboardingHandler {
    func onboardingDidCancel()
    func onboardingDidComplete()
}

protocol OnboardingViewModelType {
    var navigatableSceneDriver: Driver<Onboarding.NavigatableScene?> { get }

    func savePincode(_ pincode: String)

    func getBiometryType() -> LABiometryType
    func authenticateAndEnableBiometry(errorHandler: ((Error) -> Void)?)
    func enableBiometryLater()

    func requestRemoteNotifications()
    func markNotificationsAsSet()

    func navigateNext()
    func cancelOnboarding()
}

extension Onboarding {
    class ViewModel {
        // MARK: - Dependencies

        @Injected private var handler: OnboardingHandler
        @Injected private var pinCodeStorage: PincodeStorageType
        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var notificationService: NotificationService

        // MARK: - Properties

        private let context = LAContext()

        // MARK: - Subjects

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)

        // MARK: - Initializer

        init() {
            navigateNext()
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
    }
}

extension Onboarding.ViewModel: OnboardingViewModelType {
    var navigatableSceneDriver: Driver<Onboarding.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    // MARK: - Pincode

    func savePincode(_ pincode: String) {
        pinCodeStorage.save(pincode)
        navigateNext()
    }

    // MARK: - Biometry

    func getBiometryType() -> LABiometryType {
        context.biometryType
    }

    func authenticateAndEnableBiometry(errorHandler: ((Error) -> Void)? = nil) {
        let reason = L10n.identifyYourself

        context
            .evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                            localizedReason: reason)
            { success, authenticationError in

                DispatchQueue.main.async { [weak self] in
                    if success {
                        self?.setEnableBiometry(true)
                    } else {
                        errorHandler?(authenticationError ?? SolanaError.unknown)
                        self?.enableBiometryLater()
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
        if on {
            analyticsManager.log(event: AmplitudeEvent.bioApproved(lastScreen: "Onboarding"))
        } else {
            analyticsManager.log(event: AmplitudeEvent.bioRejected)
        }

        navigateNext()
    }

    // MARK: - Notification

    func requestRemoteNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                debugPrint("Permission granted: \(granted)")
                DispatchQueue.main.async { [weak self] in
                    guard granted else {
                        UIApplication.shared.openAppSettings()
                        return
                    }
                    self?.notificationService.registerForRemoteNotifications()
                    self?.markNotificationsAsSet()
                }
            }
    }

    func markNotificationsAsSet() {
        Defaults.didSetEnableNotifications = true
        navigateNext()
    }

    // MARK: - Navigation

    func navigateNext() {
        if pinCodeStorage.pinCode == nil {
            navigationSubject.accept(.createPincode)
            return
        }

        if !Defaults.didSetEnableBiometry {
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                // evaluate
                navigationSubject.accept(.setUpBiometryAuthentication)
                analyticsManager.log(event: AmplitudeEvent.setupFaceidOpen)
            } else {
                enableBiometryLater()
            }

            if let error = error {
                debugPrint("deviceOwnerAuthenticationWithBiometrics error: \(error)")
            }
            return
        }

        if !Defaults.didSetEnableNotifications {
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
                debugPrint("Notification settings: \(settings)")

                guard let self = self else { return }

                // not authorized
                guard settings.authorizationStatus == .authorized else {
                    self.navigationSubject.accept(.setUpNotifications)
                    self.analyticsManager.log(event: AmplitudeEvent.setupAllowPushOpen)
                    return
                }

                // authorized
                DispatchQueue.main.async { [weak self] in
                    self?.notificationService.registerForRemoteNotifications()
                    self?.markNotificationsAsSet()
                }
            }
            return
        }

        endOnboarding()
    }

    func cancelOnboarding() {
        navigationSubject.accept(.dismiss)
        handler.onboardingDidCancel()
    }

    func endOnboarding() {
        switch OnboardingTracking.currentFlow {
        case .create:
            analyticsManager.log(event: AmplitudeEvent.walletCreated(
                lastScreen: navigationSubject.value?.screenName ?? "Sign_In_Apple"
            ))
        case .restore:
            analyticsManager.log(event: AmplitudeEvent.walletRestored(
                lastScreen: navigationSubject.value?.screenName ?? "Sign_In_Apple"
            ))
        case .none:
            break
        }

        navigationSubject.accept(.dismiss)
        handler.onboardingDidComplete()
    }
}
