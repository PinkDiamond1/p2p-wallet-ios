//
//  Onboarding.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/09/2021.
//

import AnalyticsManager
import Foundation

enum Onboarding {
    enum NavigatableScene: ScreenEvents {
        case createPincode
        case setUpBiometryAuthentication
        case setUpNotifications
        case dismiss
    }
}
