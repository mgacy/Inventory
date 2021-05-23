//
//  UIControl+Rx.swift
//  Mobile
//
//  Created by Mathew Gacy on 3/8/18.
//

import UIKit
import RxCocoa
import RxSwift

extension UIControl {

    /// https://github.com/ReactiveX/RxSwift/issues/681
    /// https://github.com/ReactiveX/RxSwift/issues/991
    static func valuePublic<T, ControlType: UIControl>(_ control: ControlType, getter:  @escaping (ControlType) -> T, setter: @escaping (ControlType, T) -> Void) -> ControlProperty<T> {
        let values: Observable<T> = Observable.deferred { [weak control] in
            guard let existingSelf = control else {
                return Observable.empty()
            }

            return (existingSelf as UIControl).rx.controlEvent([.allEditingEvents, .valueChanged])
                .flatMap { _ in
                    return control.map { Observable.just(getter($0)) } ?? Observable.empty()
                }
                .startWith(getter(existingSelf))
        }
        //return ControlProperty(values: values, valueSink: UIBindingObserver(UIElement: control) { control, value in
        return ControlProperty(values: values, valueSink: Binder(control) { control, value in
            setter(control, value)
        })
    }

}
