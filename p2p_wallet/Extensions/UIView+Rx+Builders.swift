//
//  UIView+Rx+Builders.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/12/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension UIView {
    enum DrivableProperty: String {
        case isHidden
        case tintColor
        case backgroundColor
        case text
        case textColor
    }
    
    func with<T>(
        _ drivableProperty: DrivableProperty,
        drivenBy driver: Driver<T>,
        disposedBy disposeBag: DisposeBag
    ) -> Self {
        driver
            .drive(onNext: {[weak self] value in
                self?.setValue(value, forKey: drivableProperty.rawValue)
            })
            .disposed(by: disposeBag)
        return self
    }
    
//    func withDrivenProperty<T, V>(
//        _ keyPath: KeyPath<Reactive<V>, Binder<T>>,
//        by driver: Driver<T>,
//        disposedBy disposeBag: DisposeBag,
//        selfObjType: V.Type
//    ) -> Self {
//        let keyPath = keyPath as! KeyPath<Reactive<Self>, Binder<T>>
//        driver
//            .drive(rx[keyPath: keyPath])
//            .disposed(by: disposeBag)
//        return self
//    }
}