//
//  TokenDetailActionView.swift
//  p2p_wallet
//
//  Created by Ivan on 10.08.2022.
//

import Combine
import KeyAppUI
import SwiftUI

struct ActionsView: View {
    private let actionSubject = PassthroughSubject<Action, Never>()
    var action: AnyPublisher<Action, Never> { actionSubject.eraseToAnyPublisher() }
    private let cancelSubject = PassthroughSubject<Void, Never>()
    var cancel: AnyPublisher<Void, Never> { cancelSubject.eraseToAnyPublisher() }

    var body: some View {
        VStack(spacing: 28) {
            Color(Asset.Colors.rain.color)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
            Text(L10n.actions)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .text1, weight: .bold))
            VStack(spacing: 42) {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        actionView(
                            image: .homeBuyAction,
                            title: L10n.buy,
                            subtitle: L10n.usingApplePayOrCreditCard,
                            action: {
                                actionSubject.send(.buy)
                            }
                        )
                        actionView(
                            image: .homeReceiveAction,
                            title: L10n.receive,
                            subtitle: L10n.fromAnotherWalletOrExchange,
                            action: {
                                actionSubject.send(.receive)
                            }
                        )
                    }
                    HStack(spacing: 16) {
                        actionView(
                            image: .homeTradeAction,
                            title: L10n.trade,
                            subtitle: L10n.oneCryptoForAnother,
                            action: {
                                actionSubject.send(.trade)
                            }
                        )
                        actionView(
                            image: .homeSendAction,
                            title: L10n.send,
                            subtitle: "\(L10n.toUsernameOrAddress)\n",
                            action: {
                                actionSubject.send(.send)
                            }
                        )
                    }
                }
            }
            Button(
                action: {
                    cancelSubject.send()
                },
                label: {
                    Text(L10n.cancel)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text1, weight: .bold))
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.rain.color))
                        .cornerRadius(12)
                }
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .padding(.top, 6)
    }

    func actionView(
        image: UIImage,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(
            action: action,
            label: {
                ZStack(alignment: .leading) {
                    Color(Asset.Colors.snow.color)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(Asset.Colors.rain.color), lineWidth: 1)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .shadow(
                            color: Color(UIColor(red: 0.043, green: 0.122, blue: 0.208, alpha: 0.1)),
                            radius: 128,
                            x: 9,
                            y: 22
                        )
                    VStack(alignment: .leading, spacing: 12) {
                        Image(uiImage: image)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(title)
                                .foregroundColor(Color(Asset.Colors.night.color))
                                .font(uiFont: .font(of: .text1, weight: .bold))
                            Text(subtitle)
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                .font(uiFont: .font(of: .label1, weight: .regular))
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        )
    }
}

// MARK: - Action

extension ActionsView {
    enum Action {
        case buy
        case receive
        case trade
        case send
    }
}

// MARK: - View Height

extension ActionsView {
    var viewHeight: CGFloat {
        (UIScreen.main.bounds.width - 16 * 3) + (UIApplication.shared.kWindow?.safeAreaInsets.bottom ?? 0) + 210
    }
}
