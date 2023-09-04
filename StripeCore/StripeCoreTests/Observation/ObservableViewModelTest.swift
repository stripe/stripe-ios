//
//  ObservableViewModelTest.swift
//  StripeCoreTests
//
//  Created by Eduardo Urias on 10/10/23.
//

@_spi(STP) @testable import StripeCore
import XCTest

final class ObservableViewModelTest: XCTestCase {
    class TestObservableViewModel: ObservableViewModel {
        let notifier = ViewModelObservationNotifier()

        func notify() {
            notifier.notify()
        }
    }

    class TestObserver {}

    func testObservations() {
        let viewModel = TestObservableViewModel()

        var aCalled = false
        var bCalled = false

        let observerA: TestObserver? = TestObserver()
        viewModel.addObserver(observerA!) {
            XCTAssertFalse(aCalled)
            aCalled = true
        }
        var observerB: TestObserver? = TestObserver()
        viewModel.addObserver(observerB!) {
            XCTAssertFalse(bCalled)
            bCalled = true
        }

        XCTAssertEqual(viewModel.notifier.observers.count, 2)

        viewModel.notify()
        XCTAssertTrue(aCalled)
        XCTAssertTrue(bCalled)

        viewModel.removeObserver(observerA!)
        XCTAssertEqual(viewModel.notifier.observers.count, 1)

        observerB = nil
        viewModel.notify()
        XCTAssertEqual(viewModel.notifier.observers.count, 0)
    }
}
