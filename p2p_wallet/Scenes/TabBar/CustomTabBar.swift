//
//  CustomTabBar.swift
//  p2p_wallet
//
//  Created by Ivan on 09.07.2022.
//

import Combine
import KeyAppUI
import UIKit

final class CustomTabBar: UITabBar {
    private lazy var middleButton: UIButton! = {
        let middleButton = UIButton()
        middleButton.frame.size = CGSize(width: 68, height: 68)
        middleButton.backgroundColor = Asset.Colors.snow.color
        middleButton.layer.cornerRadius = 34
        middleButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        middleButton.setImage(.tabBarCenter, for: .normal)
        middleButton.addTarget(self, action: #selector(middleButtonAction), for: .touchUpInside)
        addSubview(middleButton)
        return middleButton
    }()

    private lazy var selectedView: UIView! = {
        let selectedView = UIView()
        selectedView.frame.size = CGSize(width: 36, height: 4)
        selectedView.layer.cornerRadius = 2
        selectedView.backgroundColor = Asset.Colors.lime.color
        addSubview(selectedView)
        return selectedView
    }()

    var currentIndex: Int? {
        guard let item = selectedItem else { return nil }
        return items?.firstIndex(of: item)
    }

    static var additionalHeight: CGFloat = 16

    private let middleButtonClickedSubject = PassthroughSubject<Void, Never>()
    var middleButtonClicked: AnyPublisher<Void, Never> { middleButtonClickedSubject.eraseToAnyPublisher() }

    override func layoutSubviews() {
        super.layoutSubviews()

        middleButton.center = CGPoint(
            x: frame.width / 2,
            y: frame.height / 2 - Self.additionalHeight - 6
        )
        updateSelectedViewPositionIfNeeded()

        layer.shadowColor = UIColor(red: 0.043, green: 0.122, blue: 0.208, alpha: 0.1).cgColor
        layer.shadowOffset = CGSize(width: 9, height: 22)
        layer.shadowRadius = 128
        layer.shadowOpacity = 1
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        size.height += Self.additionalHeight
        return size
    }

    // MARK: - Actions

    @objc func middleButtonAction() {
        middleButtonClickedSubject.send()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !clipsToBounds, !isHidden, alpha > 0 else { return nil }
        return middleButton.frame.contains(point) ? middleButton : super.hitTest(point, with: event)
    }

    func updateSelectedViewPositionIfNeeded() {
        guard let currentIndex = currentIndex else { return }
        selectedView.center = CGPoint(x: subviews[currentIndex + 1].center.x, y: 0)
    }
}
