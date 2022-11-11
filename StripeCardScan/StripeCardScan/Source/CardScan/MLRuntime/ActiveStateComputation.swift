/// # Backgrounding and ML
/// Our ML algorithms use the GPU and can cause crashes when we run them in the background. Thus, we track the app's
/// backgrounding state and stop any tasks before the app reaches the background.
///
/// # Correctness criteria
/// We have three different functions: `async`, `willResignActive`, and `didBecomeActive` that all run on the main dispatch
/// queue. In terms of ordering constraints:
///  - The system enforces state transitions such that each time you resign active it'll be paired with a `didBecomeActive` call
///    and vice versa.
///
/// Given this constraint, you can expect a few different interleavings
///  - async, resign, become
///  - async, become, resign
///  - become, async, resign
///  - become, resign, async
///  - resign, async, become
///  - resign, become, async
///
/// In general, we maintain two states: the system's notion of our app's application state and our own notion of active that is a
/// subset of the more general active system state. In other words, if our app is inactive then our own internal `isActive` is
/// always false, but if the app is active our internal `isActive` may be false or it may be true. However, if it is `false`
/// we know that we'll get a become event soon.
///
/// Our correctness criterai is that our work items run iff the app is in the active state and each of them runs to completion
/// in the same order that they were posted (same semantics as a serial dispatch queue).
///
/// The only time that computation can run is in between calls to `become` and `resign` because of our internal `isActive` variable.
/// After the system calls resign, then all work items are added to the `pendingComputations` list in order, which are then posted to the `queue` in order on the `become` call before releasing the main queue. Subsequent calls to `async` will post to the `queue` but
/// because the posting happens in the main queue, we can ensure correct execution ordering.
import Foundation
import UIKit

class ActiveStateComputation {
    let queue: DispatchQueue
    var pendingComputations: [() -> Void] = []
    var isActive = false

    init(
        label: String
    ) {
        self.queue = DispatchQueue(label: "ActiveStateComputation \(label)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isActive = UIApplication.shared.applicationState == .active

            // We don't need to unregister these functions because the system will clean
            // them up for us
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.willResignActive),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.didBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }
    }

    func async(execute work: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let state = UIApplication.shared.applicationState
            guard state == .active, self.isActive else {
                self.pendingComputations.append(work)
                return
            }

            self.queue.async { work() }
        }
    }

    @objc func willResignActive() {
        assert(UIApplication.shared.applicationState == .active)
        assert(Thread.isMainThread)
        isActive = false
        queue.sync {}
    }

    @objc func didBecomeActive() {
        assert(UIApplication.shared.applicationState == .active)
        assert(Thread.isMainThread)
        isActive = true
        for work in pendingComputations {
            queue.async { work() }
        }
    }
}
