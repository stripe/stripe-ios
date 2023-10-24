//
//  ViewModelObservation.swift
//  StripePaymentSheet
//
//  Created by Eduardo Urias on 10/10/23.
//

import Foundation

@_spi(STP) public typealias UpdateCallback = () -> Void
@_spi(STP) public typealias ErrorUpdateCallback = (Error?) -> Void

@_spi(STP) public protocol ObservableViewModel: AnyObject {
    var notifier: ViewModelObservationNotifier { get }

    func addObserver(_ observer: AnyObject, callback: @escaping UpdateCallback)
    func removeObserver(_ observer: AnyObject)
}

@_spi(STP) public extension ObservableViewModel {
    func addObserver(_ observer: AnyObject, callback: @escaping UpdateCallback) {
        notifier.addObserver(observer, callback: callback)
    }

    func removeObserver(_ observer: AnyObject) {
        notifier.removeObserver(observer)
    }
}

@_spi(STP) public protocol ObservableViewModelWithError: ObservableViewModel {
    var error: Error? { get }
    var errorNotifier: ViewModelObservationNotifier { get }

    func addErrorObserver(_ observer: AnyObject, callback: @escaping ErrorUpdateCallback)
    func removeErrorObserver(_ observer: AnyObject)
}

@_spi(STP) public extension ObservableViewModelWithError {
    func addErrorObserver(_ observer: AnyObject, callback: @escaping ErrorUpdateCallback) {
        errorNotifier.addObserver(observer) { [weak self] in
            callback(self?.error)
        }
    }

    func removeErrorObserver(_ observer: AnyObject) {
        errorNotifier.removeObserver(observer)
    }
}

@_spi(STP) public class ViewModelObservationNotifier {
    var observers: [ViewModelObserver] = []

    @_spi(STP) public init() {}

    @_spi(STP) public func notify() {
        cleanUpObservers()
        observers.forEach { $0.invoke() }
    }

    @_spi(STP) public func addObserver(_ observer: AnyObject, callback: @escaping UpdateCallback) {
        cleanUpObservers()
        observers.append(ViewModelObserver(observer: observer, callback: callback))
    }

    @_spi(STP) public func removeObserver(_ observer: AnyObject) {
        cleanUpObservers()
        observers.removeAll { $0.observer === observer }
    }

    private func cleanUpObservers() {
        observers.removeAll { $0.observer == nil }
    }
}

struct ViewModelObserver {
    weak var observer: AnyObject?
    var callback: UpdateCallback

    func invoke() {
        callback()
    }
}
