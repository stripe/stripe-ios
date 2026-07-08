#if canImport(AppKit) && !canImport(UIKit)
import AppKit

private var STPPresentedWindows: [ObjectIdentifier: NSWindow] = [:]

public typealias UIColor = NSColor
public typealias UIFont = NSFont
public typealias UIImage = NSImage
public typealias UIWindow = NSWindow
public typealias UIUserInterfaceStyle = UITraitCollection.UserInterfaceStyle
public typealias UILayoutPriority = NSLayoutConstraint.Priority
public typealias UIEdgeInsets = NSEdgeInsets

public class UIEvent: NSObject {
}

public class UITouch: NSObject {
    public weak var view: UIView?

    public func location(in view: UIView?) -> CGPoint {
        .zero
    }
}

open class UIView: NSView {
    public struct AnimationOptions: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let curveEaseInOut = AnimationOptions(rawValue: 1 << 0)
        public static let curveEaseOut = AnimationOptions(rawValue: 1 << 1)
        public static let transitionFlipFromRight = AnimationOptions(rawValue: 1 << 2)
        public static let transitionFlipFromLeft = AnimationOptions(rawValue: 1 << 3)
        public static let transitionCrossDissolve = AnimationOptions(rawValue: 1 << 4)
        public static let beginFromCurrentState = AnimationOptions(rawValue: 1 << 5)
    }

    public enum AnimationCurve: Int {
        case easeInOut
        case easeIn
        case easeOut
        case linear
    }

    public enum ContentMode {
        case center
        case left
        case top
        case bottom
        case scaleAspectFill
        case scaleAspectFit
    }

    public static let layoutFittingCompressedSize = CGSize(width: 0, height: 0)
    public static let layoutFittingExpandedSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    public static var areAnimationsEnabled = true

    open override var isFlipped: Bool {
        true
    }

    public override var layer: CALayer! {
        get {
            wantsLayer = true
            if super.layer == nil {
                super.layer = CALayer()
            }
            return super.layer
        }
        set {
            super.layer = newValue
        }
    }

    public var directionalLayoutMargins = NSDirectionalEdgeInsets.zero
    public var insetsLayoutMarginsFromSafeArea = true
    public var preservesSuperviewLayoutMargins = true
    private var storedTag = 0
    private var storedIsOpaque = false
    public var accessibilityHint: String?
    public var accessibilityIdentifier: String?
    public var accessibilityLabel: String?
    public var accessibilityTraits = UIAccessibilityTraits()
    public var accessibilityValue: String?
    open var accessibilityAttributedValue: NSAttributedString?
    open var accessibilityAttributedLabel: NSAttributedString?
    public var accessibilityElements: [Any]?
    public var accessibilityCustomRotors: [UIAccessibilityCustomRotor]?
    public var accessibilityCustomActions: [UIAccessibilityCustomAction]?
    public var accessibilityElementsHidden = false
    public var isAccessibilityElement = false
    @objc open var inputAccessoryView: UIView?
    @objc open var inputView: UIView?
    @objc open var canBecomeFirstResponder: Bool {
        true
    }
    @objc open var canResignFirstResponder: Bool {
        true
    }
    @objc open var isFirstResponder: Bool {
        window?.firstResponder === self
    }
    open var isUserInteractionEnabled = true
    public var contentMode = ContentMode.scaleAspectFit
    public var showsMenuAsPrimaryAction = false
    public var isContextMenuInteractionEnabled = false
    public var tintColor: UIColor = .controlAccentColor
    public var transform = CGAffineTransform.identity
    public var mask: UIView?
    public var effectiveUserInterfaceLayoutDirection = UIUserInterfaceLayoutDirection.leftToRight
    public var overrideUserInterfaceStyle = UIUserInterfaceStyle.unspecified
    public var next: AnyObject? {
        nextResponder
    }
    public var traitCollection: UITraitCollection {
        .current
    }

    open override var tag: Int {
        get {
            storedTag
        }
        set {
            storedTag = newValue
        }
    }

    open override var isOpaque: Bool {
        get {
            storedIsOpaque
        }
        set {
            storedIsOpaque = newValue
        }
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    @objc open dynamic func layoutSubviews() {
    }

    public func layoutIfNeeded() {
        layoutSubtreeIfNeeded()
    }

    public func setNeedsLayout() {
        needsLayout = true
    }

    public func setNeedsUpdateConstraints() {
        needsUpdateConstraints = true
    }

    public var layoutMargins: UIEdgeInsets {
        get {
            UIEdgeInsets(
                top: directionalLayoutMargins.top,
                left: directionalLayoutMargins.leading,
                bottom: directionalLayoutMargins.bottom,
                right: directionalLayoutMargins.trailing
            )
        }
        set {
            directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: newValue.top,
                leading: newValue.left,
                bottom: newValue.bottom,
                trailing: newValue.right
            )
        }
    }

    public func sendSubviewToBack(_ view: UIView) {
        addSubview(view, positioned: .below, relativeTo: nil)
    }

    @objc open dynamic func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.contains(point)
    }

    public func setNeedsDisplay() {
        needsDisplay = true
    }

    @objc open dynamic func sizeToFit() {
        frame.size = intrinsicContentSize
    }

    open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    }

    @objc open dynamic func tintColorDidChange() {
    }

    open var keyCommands: [UIKeyCommand]? {
        nil
    }

    @objc open dynamic func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    @objc open dynamic func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        false
    }

    @objc open dynamic func paste(_ sender: Any?) {
    }

    @objc open dynamic func menuAttachmentPoint(for configuration: UIContextMenuConfiguration) -> CGPoint {
        .zero
    }

    @objc open dynamic func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        nil
    }

    @objc open dynamic func willMove(toWindow newWindow: UIWindow?) {
    }

    open func didMoveToWindow() {
    }

    open func didMoveToSuperview() {
    }

    public static func animate(withDuration duration: TimeInterval, animations: () -> Void) {
        animations()
    }

    public static func animate(
        withDuration duration: TimeInterval,
        animations: () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        animations()
        completion?(true)
    }

    public static func animate(
        withDuration duration: TimeInterval,
        delay: TimeInterval,
        options: AnimationOptions = [],
        animations: () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        animations()
        completion?(true)
    }

    public static func transition(
        with view: UIView,
        duration: TimeInterval,
        options: AnimationOptions = [],
        animations: (() -> Void)?,
        completion: ((Bool) -> Void)? = nil
    ) {
        animations?()
        completion?(true)
    }

    public static func animate(
        withDuration duration: TimeInterval,
        delay: TimeInterval,
        usingSpringWithDamping dampingRatio: CGFloat,
        initialSpringVelocity velocity: CGFloat,
        options: AnimationOptions = [],
        animations: () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        animations()
        completion?(true)
    }

    public func convert(_ rect: CGRect, to window: UIWindow?) -> CGRect {
        super.convert(rect, to: nil as NSView?)
    }

    public func endEditing(_ force: Bool) -> Bool {
        resignFirstResponder()
    }

    public func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        gestureRecognizer.view = self
    }

    public func addInteraction(_ interaction: UIContextMenuInteraction) {
    }

    public func addInteraction(_ interaction: any UIInteraction) {
    }

    public func insertSubview(_ view: UIView, at index: Int) {
        addSubview(view, positioned: .below, relativeTo: subviews.first)
    }

    public func bringSubviewToFront(_ view: UIView) {
        addSubview(view, positioned: .above, relativeTo: nil)
    }

    public func snapshotView(afterScreenUpdates: Bool) -> UIView? {
        UIView(frame: frame)
    }

    public func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        intrinsicContentSize
    }

    @objc open dynamic func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        systemLayoutSizeFitting(targetSize)
    }

    open override func hitTest(_ point: NSPoint) -> NSView? {
        hitTest(point, with: nil)
    }

    @objc open dynamic func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, self.point(inside: point, with: event) else {
            return nil
        }
        for subview in subviews.reversed() {
            guard let subview = subview as? UIView else {
                continue
            }
            let convertedPoint = subview.convert(point, from: self)
            if let hitView = subview.hitTest(convertedPoint, with: event) {
                return hitView
            }
        }
        return self
    }

    public static func performWithoutAnimation(_ actionsWithoutAnimation: () -> Void) {
        actionsWithoutAnimation()
    }

    public static func setAnimationsEnabled(_ enabled: Bool) {
        areAnimationsEnabled = enabled
    }
}

public class UIViewPropertyAnimator: NSObject {
    private let animations: () -> Void
    public var isInterruptible = false

    public init(duration: TimeInterval, controlPoint1: CGPoint, controlPoint2: CGPoint, animations: @escaping () -> Void) {
        self.animations = animations
        super.init()
    }

    public init(duration: TimeInterval, controlPoint1: CGPoint, controlPoint2: CGPoint) {
        self.animations = {}
        super.init()
    }

    public init(duration: TimeInterval, curve: UIView.AnimationCurve, animations: @escaping () -> Void) {
        self.animations = animations
        super.init()
    }

    public init(duration: TimeInterval, timingParameters parameters: UISpringTimingParameters) {
        self.animations = {}
        super.init()
    }

    public func startAnimation() {
        animations()
    }

    public func startAnimation(afterDelay delay: TimeInterval) {
        animations()
    }

    public func addAnimations(_ animation: @escaping () -> Void) {
        animation()
    }

    public func addCompletion(_ completion: @escaping (UIViewAnimatingPosition) -> Void) {
        completion(.end)
    }

    public func stopAnimation(_ withoutFinishing: Bool) {
    }
}

public enum UIViewAnimatingPosition {
    case end
}

open class UIViewController: NSViewController {
    open var navigationController: UINavigationController?
    open var navigationItem = UINavigationItem()
    open var overrideUserInterfaceStyle = UIUserInterfaceStyle.unspecified
    open var isModalInPresentation = false
    open var modalPresentationCapturesStatusBarAppearance = false
    open weak var transitioningDelegate: UIViewControllerTransitioningDelegate?
    open var transitionCoordinator: UIViewControllerTransitionCoordinator?

    open override func loadView() {
        view = UIView(frame: .zero)
    }

    open func viewWillAppear(_ animated: Bool) {
    }

    open func viewDidAppear(_ animated: Bool) {
    }

    open func viewWillDisappear(_ animated: Bool) {
    }

    open func viewDidDisappear(_ animated: Bool) {
    }

    open func viewDidLayoutSubviews() {
    }

    open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    }

    open func registerForTraitChanges(
        _ traits: [UITraitUserInterfaceStyle.Type],
        action: Selector
    ) {
    }

    open func registerForTraitChanges<T: UIViewController>(
        _ traits: [UITraitUserInterfaceStyle.Type],
        handler: @escaping (T, UITraitCollection) -> Void
    ) {
    }

    open func willMove(toParent parent: UIViewController?) {
    }

    open func didMove(toParent parent: UIViewController?) {
    }

    open override func removeFromParent() {
    }

    open func beginAppearanceTransition(_ isAppearing: Bool, animated: Bool) {
    }

    open func endAppearanceTransition() {
    }

    open func present(_ viewControllerToPresent: UIViewController, animated flag: Bool) {
        present(viewControllerToPresent, animated: flag, completion: nil)
    }

    open func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if viewControllerToPresent.preferredContentSize == .zero {
            viewControllerToPresent.preferredContentSize = CGSize(width: 420, height: 620)
        }
        viewControllerToPresent.view.setFrameSize(viewControllerToPresent.preferredContentSize)
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: viewControllerToPresent.preferredContentSize),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = String(describing: type(of: viewControllerToPresent))
        window.contentViewController = viewControllerToPresent
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        STPPresentedWindows[ObjectIdentifier(viewControllerToPresent)] = window
        completion?()
    }

    open func dismiss(animated flag: Bool) {
        if let window = STPPresentedWindows.removeValue(forKey: ObjectIdentifier(self)) {
            window.close()
            return
        }
        presentingViewController?.dismiss(self)
    }

    open func setNeedsStatusBarAppearanceUpdate() {
    }
}

public enum UIUserInterfaceLayoutDirection {
    case leftToRight
    case rightToLeft
}

public enum UITraitUserInterfaceStyle {
}

public enum UISemanticContentAttribute {
    case unspecified
    case forceLeftToRight
}

public struct UIAccessibilityTraits: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let button = UIAccessibilityTraits(rawValue: 1 << 0)
    public static let notEnabled = UIAccessibilityTraits(rawValue: 1 << 1)
    public static let selected = UIAccessibilityTraits(rawValue: 1 << 2)
    public static let header = UIAccessibilityTraits(rawValue: 1 << 3)
    public static let staticText = UIAccessibilityTraits(rawValue: 1 << 4)
}

public class UIAccessibilityCustomRotor: NSObject {
    public enum SystemRotorType {
        case link
    }

    public var systemRotorType: SystemRotorType = .link
}

public class UIAccessibilityCustomAction: NSObject {
    public init(name: String, target: Any?, selector: Selector) {
        super.init()
    }
}

public enum UIAccessibility {
    public static var shouldDifferentiateWithoutColor = false

    public enum Notification {
        case announcement
        case layoutChanged
        case screenChanged
    }

    public static func post(notification: Notification, argument: Any?) {
    }
}

public protocol UIGestureRecognizerDelegate: AnyObject {
}

public class UIGestureRecognizer: NSObject {
    public enum State {
        case possible
        case began
        case changed
        case ended
        case cancelled
        case failed
    }

    public weak var view: UIView?
    public weak var delegate: UIGestureRecognizerDelegate?
    public var cancelsTouchesInView = true
    public var state = State.possible

    public init(target: Any?, action: Selector?) {
        super.init()
    }
}

public class UITapGestureRecognizer: UIGestureRecognizer {
    public func location(in view: UIView?) -> CGPoint {
        .zero
    }
}

public class UILongPressGestureRecognizer: UIGestureRecognizer {
    public var minimumPressDuration: TimeInterval = 0
}

public class UIPanGestureRecognizer: UIGestureRecognizer {
}

public enum UIDeviceOrientation {
    case unknown
    case portrait
    case portraitUpsideDown
    case landscapeLeft
    case landscapeRight
    case faceUp
    case faceDown
}

public class UIDevice: NSObject {
    public enum UserInterfaceIdiom {
        case mac
        case phone
        case pad
    }

    public static let current = UIDevice()
    public var userInterfaceIdiom = UserInterfaceIdiom.phone
    public var orientation = UIDeviceOrientation.portrait
}

public class UIBezierPath: NSObject {
    public enum LineCapStyle {
        case square
    }

    public enum LineJoinStyle {
        case bevel
    }

    private let mutablePath = CGMutablePath()
    public var usesEvenOddFillRule = false
    public var lineWidth: CGFloat = 1
    public var lineCapStyle = LineCapStyle.square
    public var lineJoinStyle = LineJoinStyle.bevel
    public var cgPath: CGPath {
        mutablePath.copy()!
    }

    public override init() {
        super.init()
    }

    public init(rect: CGRect) {
        mutablePath.addRect(rect)
        super.init()
    }

    public init(roundedRect rect: CGRect, cornerRadius: CGFloat) {
        mutablePath.addPath(CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil))
        super.init()
    }

    public init(
        arcCenter center: CGPoint,
        radius: CGFloat,
        startAngle: CGFloat,
        endAngle: CGFloat,
        clockwise: Bool
    ) {
        mutablePath.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: !clockwise)
        super.init()
    }

    public func move(to point: CGPoint) {
        mutablePath.move(to: point)
    }

    public func addLine(to point: CGPoint) {
        mutablePath.addLine(to: point)
    }

    public func fill() {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }
        context.addPath(cgPath)
        context.fillPath()
    }

    public func stroke() {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }
        context.addPath(cgPath)
        context.strokePath()
    }

    public func addClip() {
        NSGraphicsContext.current?.cgContext.addPath(cgPath)
        NSGraphicsContext.current?.cgContext.clip()
    }

    public func append(_ path: UIBezierPath) {
        mutablePath.addPath(path.cgPath)
    }
}

open class UIControl: UIView {
    @objc public enum ContentVerticalAlignment: Int {
        case center
        case top
        case bottom
        case fill
    }

    public struct Event: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let touchUpInside = Event(rawValue: 1 << 0)
        public static let editingChanged = Event(rawValue: 1 << 1)
        public static let valueChanged = Event(rawValue: 1 << 2)
        public static let touchDown = Event(rawValue: 1 << 3)
        public static let touchUpOutside = Event(rawValue: 1 << 4)
    }

    public struct State: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let normal = State(rawValue: 0)
        public static let highlighted = State(rawValue: 1 << 0)
        public static let disabled = State(rawValue: 1 << 1)
        public static let selected = State(rawValue: 1 << 2)
    }

    open var isEnabled = true
    @objc open dynamic var contentVerticalAlignment = ContentVerticalAlignment.center
    open var isHighlighted = false
    open var isSelected = false
    private var actionTargets: [(target: AnyObject?, action: Selector, events: Event)] = []
    public var state: State {
        var state: State = .normal
        if isHighlighted {
            state.insert(.highlighted)
        }
        if !isEnabled {
            state.insert(.disabled)
        }
        if isSelected {
            state.insert(.selected)
        }
        return state
    }

    public func addTarget(_ target: Any?, action: Selector, for event: Event) {
        actionTargets.append((target as AnyObject?, action, event))
    }

    public func removeTarget(_ target: Any?, action: Selector?, for event: Event) {
        actionTargets.removeAll { actionTarget in
            let targetMatches = target == nil || actionTarget.target === (target as AnyObject?)
            let actionMatches = action == nil || actionTarget.action == action
            return targetMatches && actionMatches && actionTarget.events.intersection(event).isEmpty == false
        }
    }

    public func sendActions(for controlEvents: Event) {
        for actionTarget in actionTargets where actionTarget.events.intersection(controlEvents).isEmpty == false {
            NSApplication.shared.sendAction(actionTarget.action, to: actionTarget.target, from: self)
        }
    }

    open override func mouseDown(with event: NSEvent) {
        guard isEnabled else {
            return
        }
        isHighlighted = true
        sendActions(for: .touchDown)
    }

    open override func mouseUp(with event: NSEvent) {
        guard isEnabled else {
            return
        }
        isHighlighted = false
        let point = convert(event.locationInWindow, from: nil)
        sendActions(for: bounds.contains(point) ? .touchUpInside : .touchUpOutside)
    }
}

public struct UIKeyModifierFlags: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let command = UIKeyModifierFlags(rawValue: 1 << 0)
}

public class UIKeyCommand: NSObject {
    public init(input: String, modifierFlags: UIKeyModifierFlags, action: Selector) {
        super.init()
    }
}

public class UIApplication: NSObject {
    public struct OpenExternalURLOptionsKey: RawRepresentable, Equatable, Hashable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let universalLinksOnly = OpenExternalURLOptionsKey(rawValue: "UIApplicationOpenURLOptionUniversalLinksOnly")
    }

    public static let shared = UIApplication()
    public static let didBecomeActiveNotification = Notification.Name("UIApplicationDidBecomeActiveNotification")
    public static let didEnterBackgroundNotification = Notification.Name("UIApplicationDidEnterBackgroundNotification")
    public static let willEnterForegroundNotification = Notification.Name("UIApplicationWillEnterForegroundNotification")
    public var connectedScenes: Set<UIScene> {
        []
    }

    public func open(
        _ url: URL,
        options: [OpenExternalURLOptionsKey: Any] = [:],
        completionHandler completion: ((Bool) -> Void)? = nil
    ) {
        completion?(false)
    }
}

public class UIScene: NSObject {
    public enum ActivationState {
        case foregroundActive
        case foregroundInactive
        case background
        case unattached
    }

    public var activationState = ActivationState.unattached
}

public class UIWindowScene: UIScene {
    public var traitCollection: UITraitCollection {
        .current
    }

    public var windows: [UIWindow] {
        []
    }
}

public class UIResponder: NSObject {
    public static let keyboardAnimationCurveUserInfoKey = "UIResponderKeyboardAnimationCurveUserInfoKey"
    public static let keyboardAnimationDurationUserInfoKey = "UIResponderKeyboardAnimationDurationUserInfoKey"
    public static let keyboardFrameEndUserInfoKey = "UIResponderKeyboardFrameEndUserInfoKey"
    public static let keyboardWillHideNotification = Notification.Name("UIResponderKeyboardWillHideNotification")
    public static let keyboardWillShowNotification = Notification.Name("UIResponderKeyboardWillShowNotification")
    public static let keyboardWillChangeFrameNotification = Notification.Name("UIResponderKeyboardWillChangeFrameNotification")
}

open class UIPresentationController: NSObject {
    public var containerView: UIView?
    public weak var delegate: UIAdaptivePresentationControllerDelegate?
    open var presentedViewController = UIViewController()
    open var presentingViewController = UIViewController()
    open var presentedView: UIView? {
        presentedViewController.view as? UIView
    }

    public init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        self.presentedViewController = presentedViewController
        self.presentingViewController = presentingViewController ?? UIViewController()
        super.init()
    }

    public override init() {
        super.init()
    }

    open var frameOfPresentedViewInContainerView: CGRect {
        containerView?.bounds ?? .zero
    }

    open func presentationTransitionWillBegin() {
    }

    open func presentationTransitionDidEnd(_ completed: Bool) {
    }

    open func dismissalTransitionWillBegin() {
    }

    open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    }

    open func containerViewWillLayoutSubviews() {
    }

    open func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    }
}

public protocol UIAdaptivePresentationControllerDelegate: AnyObject {
}

public protocol UIViewControllerAnimatedTransitioning: AnyObject {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
}

public protocol UIViewControllerTransitioningDelegate: AnyObject {
}

public protocol UIViewControllerContextTransitioning: AnyObject {
    var containerView: UIView { get }
    var transitionWasCancelled: Bool { get }
    func finalFrame(for viewController: UIViewController) -> CGRect
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController?
    func completeTransition(_ didComplete: Bool)
}

public struct UITransitionContextViewControllerKey: RawRepresentable, Equatable, Hashable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let from = UITransitionContextViewControllerKey(rawValue: "from")
    public static let to = UITransitionContextViewControllerKey(rawValue: "to")
}

public class UIViewControllerTransitionCoordinatorContext: NSObject {
    public var containerView = UIView()
}

public class UIViewControllerTransitionCoordinator: NSObject {
    private let context = UIViewControllerTransitionCoordinatorContext()

    public func animate(alongsideTransition animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?) {
        animation?(context)
    }

    public func animate(
        alongsideTransition animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil
    ) {
        animation?(context)
        completion?(context)
    }

    public func animate(_ animation: (UIViewControllerTransitionCoordinatorContext) -> Void) {
        animation(context)
    }
}

public class UINotificationFeedbackGenerator: NSObject {
    public enum FeedbackType {
        case error
        case success
    }

    public func prepare() {
    }

    public func notificationOccurred(_ notificationType: FeedbackType) {
    }
}

public class UISelectionFeedbackGenerator: NSObject {
    public func selectionChanged() {
    }
}

public class UIImpactFeedbackGenerator: NSObject {
    public enum FeedbackStyle {
        case light
        case medium
        case heavy
    }

    public init(style: FeedbackStyle) {
        super.init()
    }

    public func impactOccurred() {
    }
}

public class UIMenuController: NSObject {
    public static let shared = UIMenuController()
    public var isMenuVisible = false

    public func showMenu(from targetView: UIView, rect targetRect: CGRect) {
        isMenuVisible = true
    }

    public func hideMenu() {
        isMenuVisible = false
    }
}

public class UIPasteboard: NSObject {
    public static let general = UIPasteboard()
    public var string: String?
    public var hasStrings: Bool {
        string != nil
    }
}

public class UINavigationController: UIViewController {
    public let navigationBar = UINavigationBar()
    public var visibleViewController: UIViewController?

    public init(rootViewController: UIViewController) {
        self.visibleViewController = rootViewController
        super.init(nibName: nil, bundle: nil)
        rootViewController.navigationController = self
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func pushViewController(_ viewController: UIViewController, animated: Bool) {
        visibleViewController = viewController
        viewController.navigationController = self
    }

    public func popToRootViewController(animated: Bool) -> [UIViewController]? {
        []
    }

    public func popViewController(animated: Bool) -> UIViewController? {
        visibleViewController
    }
}

public class UINavigationBar: UIView {
    public var isTranslucent = false
    public var items: [UINavigationItem]?
}

public class UINavigationItem: NSObject {
    public var leftBarButtonItem: UIBarButtonItem?
    public var rightBarButtonItem: UIBarButtonItem?
}

public class UITabBarController: UIViewController {
    public var selectedViewController: UIViewController?
}

public class UIBarButtonItem: NSObject {
    public enum SystemItem {
        case cancel
        case close
        case done
        case flexibleSpace
    }

    public var tintColor: UIColor?
    public var isEnabled = true

    public required init(
        barButtonSystemItem systemItem: SystemItem,
        target: Any?,
        action: Selector?
    ) {
    }

    public init(customView: UIView) {
    }
}

public class UIActivityIndicatorView: UIView {
    public enum Style {
        case medium
        case large
    }

    public var color: UIColor?

    public init(style: Style) {
        super.init(frame: .zero)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func startAnimating() {
    }

    public func stopAnimating() {
    }
}

public class UIToolbar: UIView {
    public var items: [UIBarButtonItem]?

    public func setItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        self.items = items
    }

    public override func sizeToFit() {
        frame.size.height = max(frame.height, 44)
    }

}

public class UIAlertAction: NSObject {
    public enum Style {
        case `default`
        case cancel
        case destructive
    }

    public init(title: String?, style: Style, handler: ((UIAlertAction) -> Void)? = nil) {
        super.init()
    }
}

public class UIAlertController: UIViewController {
    public enum Style {
        case alert
        case actionSheet
    }

    public class PopoverPresentationController: NSObject {
        public var sourceView: UIView?
        public var sourceRect = CGRect.zero
    }

    public var popoverPresentationController: PopoverPresentationController? = PopoverPresentationController()

    public init(title: String?, message: String?, preferredStyle: Style) {
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func addAction(_ action: UIAlertAction) {
    }
}

public struct UIConfigurationTextAttributesTransformer {
    public struct AttributeContainer {
        public var font: UIFont?

        public init() {
        }
    }

    public init(_ transform: @escaping (AttributeContainer) -> AttributeContainer) {
    }
}

open class UIButton: UIControl {
    public enum ButtonType {
        case custom
        case system
    }

    public struct Configuration {
        public struct Background {
            public var backgroundColor: UIColor?
            public var strokeColor: UIColor?
        }

        public var attributedTitle: AttributedString?
        public var background = Background()
        public var baseForegroundColor: UIColor?
        public var contentInsets = NSDirectionalEdgeInsets.zero
        public var image: UIImage?
        public var imagePadding: CGFloat = 0
        public var title: String?
        public var titleTextAttributesTransformer: UIConfigurationTextAttributesTransformer?

        public static func plain() -> Configuration {
            Configuration()
        }
    }

    public convenience init(type: ButtonType) {
        self.init(frame: .zero)
    }

    public convenience init(configuration: Configuration) {
        self.init(frame: .zero)
        self.configuration = configuration
    }

    public var configuration: Configuration?
    public let titleLabel: UILabel? = UILabel()

    public func setImage(_ image: UIImage?, for state: UIControl.State) {
    }

    public func setTitle(_ title: String?, for state: UIControl.State) {
        titleLabel?.text = title
    }

    public func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        titleLabel?.textColor = color
    }

    public func setAttributedTitle(_ title: NSAttributedString?, for state: UIControl.State) {
        titleLabel?.attributedText = title
    }
}

public enum UIKeyboardType: Int {
    case `default`
    case asciiCapable
    case numbersAndPunctuation
    case URL
    case namePhonePad
    case emailAddress
    case webSearch
    case numberPad
    case phonePad
    case decimalPad
    case twitter
    case asciiCapableNumberPad
}

public struct UITextContentType: RawRepresentable, Equatable, Hashable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let addressCity = UITextContentType(rawValue: "addressCity")
    public static let addressState = UITextContentType(rawValue: "addressState")
    public static let creditCardNumber = UITextContentType(rawValue: "creditCardNumber")
    public static let emailAddress = UITextContentType(rawValue: "emailAddress")
    public static let familyName = UITextContentType(rawValue: "familyName")
    public static let givenName = UITextContentType(rawValue: "givenName")
    public static let name = UITextContentType(rawValue: "name")
    public static let none = UITextContentType(rawValue: "")
    public static let oneTimeCode = UITextContentType(rawValue: "oneTimeCode")
    public static let postalCode = UITextContentType(rawValue: "postalCode")
    public static let streetAddressLine1 = UITextContentType(rawValue: "streetAddressLine1")
    public static let streetAddressLine2 = UITextContentType(rawValue: "streetAddressLine2")
    public static let telephoneNumber = UITextContentType(rawValue: "telephoneNumber")
}

public enum UITextAutocapitalizationType: Int {
    case none
    case words
    case sentences
    case allCharacters
}

public enum UITextAutocorrectionType: Int {
    case `default`
    case no
    case yes
}

public enum UITextSpellCheckingType: Int {
    case `default`
    case no
    case yes
}

@objc public enum UIKeyboardAppearance: Int {
    case `default`
    case dark
    case light
}

public class UISpringTimingParameters: NSObject {
    public struct Velocity {
        public static let zero = Velocity()
    }

    public override init() {
        super.init()
    }

    public required init(
        mass: CGFloat,
        stiffness: CGFloat,
        damping: CGFloat,
        initialVelocity: Velocity
    ) {
    }
}

public class UITraitCollection: NSObject {
    public enum UserInterfaceStyle {
        case light
        case dark
        case unspecified
    }

    public enum LayoutDirection {
        case leftToRight
        case rightToLeft
    }

    public static let current = UITraitCollection()

    public let userInterfaceStyle: UserInterfaceStyle
    public var preferredContentSizeCategory: UIContentSizeCategory {
        .large
    }

    public var imageConfiguration: NSImage.SymbolConfiguration? {
        nil
    }

    public var layoutDirection: LayoutDirection {
        .leftToRight
    }

    public func hasDifferentColorAppearance(comparedTo previousTraitCollection: UITraitCollection?) -> Bool {
        previousTraitCollection?.userInterfaceStyle != userInterfaceStyle
    }

    public func performAsCurrent(_ actions: () -> Void) {
        actions()
    }

    public override init() {
        userInterfaceStyle = .light
        super.init()
    }

    public init(preferredContentSizeCategory: UIContentSizeCategory) {
        userInterfaceStyle = .light
        super.init()
    }

    public init(traitsFrom traitCollections: [UITraitCollection]) {
        self.userInterfaceStyle = traitCollections.last?.userInterfaceStyle ?? .light
        super.init()
    }

    public init(userInterfaceStyle: UserInterfaceStyle) {
        self.userInterfaceStyle = userInterfaceStyle
        super.init()
    }
}

public enum UIContentSizeCategory: Equatable {
    case large
}

open class UIImageView: UIView {
    public typealias ContentMode = UIView.ContentMode

    public var image: UIImage? {
        didSet {
            needsDisplay = true
            invalidateIntrinsicContentSize()
        }
    }

    public convenience init() {
        self.init(image: nil)
    }

    public init(image: UIImage?) {
        self.image = image
        super.init(frame: .zero)
    }

    public override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    open override var intrinsicContentSize: CGSize {
        image?.size ?? .zero
    }

    open override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let image else {
            return
        }
        let drawRect: CGRect
        switch contentMode {
        case .scaleAspectFit:
            let imageSize = image.size
            guard imageSize.width > 0, imageSize.height > 0, bounds.width > 0, bounds.height > 0 else {
                return
            }
            let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
            let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            drawRect = CGRect(
                x: bounds.midX - size.width / 2,
                y: bounds.midY - size.height / 2,
                width: size.width,
                height: size.height
            )
        case .center:
            drawRect = CGRect(
                x: bounds.midX - image.size.width / 2,
                y: bounds.midY - image.size.height / 2,
                width: image.size.width,
                height: image.size.height
            )
        default:
            drawRect = bounds
        }
        image.draw(in: drawRect)
    }
}

open class UILabel: UIView {
    public var adjustsFontForContentSizeCategory = false
    public var adjustsFontSizeToFitWidth = false
    public var attributedText: NSAttributedString? {
        didSet {
            needsDisplay = true
            invalidateIntrinsicContentSize()
        }
    }
    public var font: UIFont = .systemFont(ofSize: NSFont.systemFontSize) {
        didSet {
            needsDisplay = true
            invalidateIntrinsicContentSize()
        }
    }
    public var lineBreakMode = NSLineBreakMode.byTruncatingTail
    public var minimumContentSizeCategory = UIContentSizeCategory.large
    public var minimumScaleFactor: CGFloat = 0
    public var numberOfLines = 1 {
        didSet {
            needsDisplay = true
            invalidateIntrinsicContentSize()
        }
    }
    public var preferredMaxLayoutWidth: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    public var text: String? {
        didSet {
            needsDisplay = true
            invalidateIntrinsicContentSize()
        }
    }
    @objc open dynamic var textAlignment = NSTextAlignment.natural {
        didSet {
            needsDisplay = true
        }
    }
    public var textColor: UIColor? {
        didSet {
            needsDisplay = true
        }
    }

    public func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        bounds
    }

    @objc open dynamic func sizeThatFits(_ size: CGSize) -> CGSize {
        intrinsicContentSize
    }

    public override var intrinsicContentSize: CGSize {
        let size = attributedString.boundingRect(
            with: CGSize(
                width: preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            ),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        ).size
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }

    open override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        attributedString.draw(in: bounds)
    }

    private var attributedString: NSAttributedString {
        if let attributedText {
            return attributedText
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor ?? UIColor.label,
            .paragraphStyle: paragraphStyle,
        ]
        return NSAttributedString(string: text ?? "", attributes: attributes)
    }
}

public class UISwitch: UIControl {
    public override var accessibilityTraits: UIAccessibilityTraits {
        get { .button }
        set {}
    }
}

@objc public protocol UITextFieldDelegate: NSObjectProtocol {
    @objc optional func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
    @objc optional func textFieldDidBeginEditing(_ textField: UITextField)
    @objc optional func textFieldDidEndEditing(_ textField: UITextField)
    @objc optional func textFieldShouldReturn(_ textField: UITextField) -> Bool
    @objc(textField:shouldChangeCharactersInRange:replacementString:) optional func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
}

public protocol UIPickerViewDelegate: AnyObject {
}

public protocol UIPickerViewDataSource: AnyObject {
}

public class UIPickerView: UIView {
    public weak var delegate: UIPickerViewDelegate?
    public weak var dataSource: UIPickerViewDataSource?
    private var selectedRows: [Int: Int] = [:]

    public func selectedRow(inComponent component: Int) -> Int {
        selectedRows[component] ?? 0
    }

    public func selectRow(_ row: Int, inComponent component: Int, animated: Bool) {
        selectedRows[component] = row
    }

    public func reloadComponent(_ component: Int) {
    }
}

public class UITextSelectionRect: NSObject {
}

public protocol UIMenuElement {
}

public class UIAction: NSObject, UIMenuElement {
    public struct Identifier: RawRepresentable, Equatable, Hashable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public struct Attributes: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let disabled = Attributes(rawValue: 1 << 0)
        public static let destructive = Attributes(rawValue: 1 << 1)
    }

    public enum State {
        case off
        case on
    }

    public let identifier: Identifier

    public init(
        title: String,
        image: UIImage? = nil,
        identifier: Identifier = .init(rawValue: ""),
        attributes: Attributes = [],
        state: State = .off,
        handler: @escaping (UIAction) -> Void
    ) {
        self.identifier = identifier
        super.init()
    }
}

public class UIMenu: NSObject, UIMenuElement {
    public struct Identifier: RawRepresentable, Equatable, Hashable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let autoFill = Identifier(rawValue: "autoFill")
    }

    public init(children: [any UIMenuElement]) {
        super.init()
    }
}

public class UIContextMenuConfiguration: NSObject {
    public init(actionProvider: @escaping ([any UIMenuElement]) -> UIMenu?) {
        super.init()
    }
}

public class UIContextMenuInteraction: NSObject {
    public init(delegate: Any?) {
        super.init()
    }
}

public typealias UIContextMenuActionProvider = ([any UIMenuElement]) -> UIMenu?

public protocol UIInteraction: AnyObject {
    var view: UIView? { get }
}

public class UIScrollEdgeElementContainerInteraction: NSObject, UIInteraction {
    public weak var view: UIView?
    public weak var scrollView: AnyObject?

    public enum Edge {
        case top
        case bottom
    }

    public var edge = Edge.top
}

public protocol UIMenuBuilder {
    func remove(menu: UIMenu.Identifier)
}

public extension UIMenuBuilder {
    func remove(menu: UIMenu.Identifier) {
    }
}

open class UITextField: UIControl {
    @objc public enum ViewMode: Int {
        case never
        case whileEditing
        case unlessEditing
        case always
    }

    @objc public enum ReturnKeyType: Int {
        case `default`
        case done
    }

    @objc open dynamic weak var delegate: UITextFieldDelegate?
    public var adjustsFontForContentSizeCategory = false
    @objc open dynamic var attributedPlaceholder: NSAttributedString? {
        didSet {
            needsDisplay = true
            invalidateIntrinsicContentSize()
        }
    }
    @objc open dynamic var attributedText: NSAttributedString? {
        didSet {
            text = attributedText?.string
            needsDisplay = true
            invalidateIntrinsicContentSize()
        }
    }
    public var autocapitalizationType = UITextAutocapitalizationType.sentences
    public var autocorrectionType = UITextAutocorrectionType.default
    public let endOfDocument = UITextPosition()
    @objc open dynamic var font: UIFont? {
        didSet {
            needsDisplay = true
            invalidateIntrinsicContentSize()
        }
    }
    public var allowsNumberPadPopover = true
    public var beginningOfDocument = UITextPosition()
    public var defaultTextAttributes: [NSAttributedString.Key: Any] = [:]
    public var isEditing = false
    public var keyboardAppearance = UIKeyboardAppearance.default
    public var keyboardType = UIKeyboardType.default
    public var leftView: UIView?
    @objc open dynamic var leftViewMode = ViewMode.never
    public var markedTextRange: UITextRange?
    @objc open dynamic var placeholder: String? {
        didSet {
            needsDisplay = true
            invalidateIntrinsicContentSize()
        }
    }
    public var returnKeyType = ReturnKeyType.default
    public var rightView: UIView?
    @objc open dynamic var rightViewMode = ViewMode.never
    @objc open dynamic var selectedTextRange: UITextRange?
    public var spellCheckingType = UITextSpellCheckingType.default
    @objc open dynamic var text: String? {
        didSet {
            needsDisplay = true
            invalidateIntrinsicContentSize()
        }
    }
    @objc open dynamic var textAlignment = NSTextAlignment.natural
    public var textColor: UIColor? {
        didSet {
            needsDisplay = true
        }
    }
    public var textContentType: UITextContentType?
    public var hasText: Bool {
        !(text ?? "").isEmpty
    }

    open override var acceptsFirstResponder: Bool {
        true
    }

    open override func becomeFirstResponder() -> Bool {
        guard delegate?.textFieldShouldBeginEditing?(self) ?? true else {
            return false
        }
        isEditing = true
        delegate?.textFieldDidBeginEditing?(self)
        return super.becomeFirstResponder()
    }

    open override func resignFirstResponder() -> Bool {
        isEditing = false
        delegate?.textFieldDidEndEditing?(self)
        needsDisplay = true
        return super.resignFirstResponder()
    }

    public func offset(from: UITextPosition, to: UITextPosition) -> Int {
        0
    }

    public func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        position
    }

    public func reloadInputViews() {
    }

    public func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        UITextRange()
    }

    open func caretRect(for position: UITextPosition) -> CGRect {
        .zero
    }

    @objc open dynamic func closestPosition(to point: CGPoint) -> UITextPosition? {
        nil
    }

    @objc open dynamic func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds
    }

    @objc open dynamic func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds
    }

    @objc open dynamic func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds
    }

    @objc open dynamic func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        bounds
    }

    @objc open dynamic func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        bounds
    }

    @objc open dynamic func sizeThatFits(_ size: CGSize) -> CGSize {
        intrinsicContentSize
    }

    open override var intrinsicContentSize: CGSize {
        let textSize = displayAttributedString.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        ).size
        let height = max(22, ceil((font ?? .systemFont(ofSize: NSFont.systemFontSize)).pointSize * 1.6))
        return CGSize(width: ceil(textSize.width) + 4, height: height)
    }

    open override func mouseDown(with event: NSEvent) {
        _ = becomeFirstResponder()
    }

    open override func keyDown(with event: NSEvent) {
        guard isEnabled else {
            return
        }
        let characters = event.characters ?? ""
        switch characters {
        case "\u{7F}", "\u{8}":
            deleteBackward()
        case "\r", "\n":
            _ = delegate?.textFieldShouldReturn?(self)
        default:
            if !characters.isEmpty {
                insertText(characters)
            } else {
                super.keyDown(with: event)
            }
        }
    }

    open override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let rect = editingRect(forBounds: bounds).insetBy(dx: 2, dy: 0)
        let string = displayAttributedString
        let size = string.boundingRect(with: rect.size, options: [.usesLineFragmentOrigin, .usesFontLeading]).size
        let drawRect = CGRect(
            x: rect.minX,
            y: rect.midY - ceil(size.height) / 2,
            width: rect.width,
            height: ceil(size.height)
        )
        string.draw(in: drawRect)

        if window?.firstResponder === self {
            NSColor.keyboardFocusIndicatorColor.setStroke()
            let caretX = min(rect.maxX, drawRect.minX + ceil(size.width) + 1)
            NSBezierPath.strokeLine(
                from: CGPoint(x: caretX, y: drawRect.minY),
                to: CGPoint(x: caretX, y: drawRect.maxY)
            )
        }
    }

    public func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        []
    }

    public func buildMenu(with builder: any UIMenuBuilder) {
    }

    @objc open func deleteBackward() {
        let oldText = attributedText?.string ?? text ?? ""
        guard !oldText.isEmpty else {
            return
        }
        let range = NSRange(location: max(0, oldText.utf16.count - 1), length: 1)
        guard delegate?.textField?(self, shouldChangeCharactersIn: range, replacementString: "") ?? true else {
            return
        }
        attributedText = nil
        text = String(oldText.dropLast())
        sendActions(for: .editingChanged)
    }

    @objc open func insertText(_ text: String) {
        let oldText = attributedText?.string ?? self.text ?? ""
        let range = NSRange(location: oldText.utf16.count, length: 0)
        guard delegate?.textField?(self, shouldChangeCharactersIn: range, replacementString: text) ?? true else {
            return
        }
        attributedText = nil
        self.text = oldText + text
        sendActions(for: .editingChanged)
    }

    private var displayAttributedString: NSAttributedString {
        if let attributedText, attributedText.length > 0 {
            return attributedText
        }
        if let text, !text.isEmpty {
            return NSAttributedString(string: text, attributes: textAttributes(color: textColor ?? .label))
        }
        if let attributedPlaceholder {
            return attributedPlaceholder
        }
        return NSAttributedString(string: placeholder ?? "", attributes: textAttributes(color: .secondaryLabelColor))
    }

    private func textAttributes(color: UIColor) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        return [
            .font: font ?? UIFont.systemFont(ofSize: NSFont.systemFontSize),
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]
    }
}

public class UIStackView: UIView {
    public enum Alignment {
        case fill
        case leading
        case center
    }

    public enum Distribution {
        case fill
        case fillEqually
        case fillProportionally
        case equalSpacing
    }

    public var alignment = Alignment.fill
    public private(set) var arrangedSubviews: [UIView] = []
    public var axis = NSLayoutConstraint.Orientation.horizontal
    public var distribution = Distribution.fill
    public var isLayoutMarginsRelativeArrangement = false
    public var semanticContentAttribute = UISemanticContentAttribute.unspecified
    public var spacing: CGFloat = 0
    public var usesArrangedSubviewLayout = true

    public convenience init(arrangedSubviews: [UIView]) {
        self.init(frame: .zero)
        arrangedSubviews.forEach(addArrangedSubview)
    }

    public func addArrangedSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = true
        arrangedSubviews.append(view)
        addSubview(view)
        needsLayout = true
    }

    public func insertArrangedSubview(_ view: UIView, at stackIndex: Int) {
        view.translatesAutoresizingMaskIntoConstraints = true
        arrangedSubviews.insert(view, at: stackIndex)
        addSubview(view)
        needsLayout = true
    }

    public func removeArrangedSubview(_ view: UIView) {
        arrangedSubviews.removeAll { $0 === view }
        view.removeFromSuperview()
        needsLayout = true
    }

    public func setCustomSpacing(_ spacing: CGFloat, after arrangedSubview: UIView) {
    }

    public override var intrinsicContentSize: CGSize {
        let visibleSubviews = arrangedSubviews.filter { !$0.isHidden }
        guard !visibleSubviews.isEmpty else {
            return .zero
        }

        let sizes = visibleSubviews.map { $0.intrinsicContentSize }
        let spacingTotal = spacing * CGFloat(max(visibleSubviews.count - 1, 0))
        if axis == .vertical {
            return CGSize(
                width: sizes.map(\.width).max() ?? 0,
                height: sizes.map(\.height).reduce(0, +) + spacingTotal
            )
        } else {
            return CGSize(
                width: sizes.map(\.width).reduce(0, +) + spacingTotal,
                height: sizes.map(\.height).max() ?? 0
            )
        }
    }

    public override func layout() {
        super.layout()
        guard usesArrangedSubviewLayout else {
            return
        }

        let visibleSubviews = arrangedSubviews.filter { !$0.isHidden }
        guard !visibleSubviews.isEmpty else {
            return
        }

        var layoutBounds = bounds
        if isLayoutMarginsRelativeArrangement {
            layoutBounds = CGRect(
                x: bounds.minX + directionalLayoutMargins.leading,
                y: bounds.minY + directionalLayoutMargins.top,
                width: max(0, bounds.width - directionalLayoutMargins.leading - directionalLayoutMargins.trailing),
                height: max(0, bounds.height - directionalLayoutMargins.top - directionalLayoutMargins.bottom)
            )
        }

        if axis == .vertical {
            var y = layoutBounds.minY
            let flexibleSubviews = visibleSubviews.filter { $0.intrinsicContentSize.height <= 0 }
            let fixedHeight = visibleSubviews
                .filter { $0.intrinsicContentSize.height > 0 }
                .map { $0.intrinsicContentSize.height }
                .reduce(0, +)
            let spacingTotal = spacing * CGFloat(max(visibleSubviews.count - 1, 0))
            let flexibleHeight = flexibleSubviews.isEmpty ? 0 : max(0, (layoutBounds.height - fixedHeight - spacingTotal) / CGFloat(flexibleSubviews.count))

            for subview in visibleSubviews {
                let intrinsicSize = subview.intrinsicContentSize
                let height = intrinsicSize.height > 0 ? intrinsicSize.height : flexibleHeight
                let width = layoutBounds.width
                let x: CGFloat
                switch alignment {
                case .center:
                    x = layoutBounds.midX - width / 2
                case .leading, .fill:
                    x = layoutBounds.minX
                }
                subview.frame = CGRect(x: x, y: y, width: width, height: height)
                subview.layoutSubtreeIfNeeded()
                y += height + spacing
            }
        } else {
            var x = layoutBounds.minX
            let spacingTotal = spacing * CGFloat(max(visibleSubviews.count - 1, 0))
            let intrinsicWidths = visibleSubviews.map { subview -> CGFloat in
                let size = subview.intrinsicContentSize
                if type(of: subview) == UIView.self {
                    let subviewWidths = subview.subviews.map(\.intrinsicContentSize.width).filter { $0 > 0 }
                    guard !subviewWidths.isEmpty else {
                        return 0
                    }
                    return subviewWidths.reduce(0, +)
                }
                return size.width > 0 ? size.width : 0
            }
            let flexibleIndices = intrinsicWidths.indices.filter { intrinsicWidths[$0] <= 0 }
            let fixedWidth = intrinsicWidths.filter { $0 > 0 }.reduce(0, +)
            let flexibleWidth = flexibleIndices.isEmpty ? 0 : max(0, (layoutBounds.width - fixedWidth - spacingTotal) / CGFloat(flexibleIndices.count))

            for (index, subview) in visibleSubviews.enumerated() {
                let intrinsicSize = subview.intrinsicContentSize
                let width = distribution == .fillEqually
                    ? max(0, (layoutBounds.width - spacingTotal) / CGFloat(visibleSubviews.count))
                    : (intrinsicWidths[index] > 0 ? intrinsicWidths[index] : flexibleWidth)
                let height = alignment == .fill ? layoutBounds.height : min(intrinsicSize.height, layoutBounds.height)
                let y: CGFloat
                switch alignment {
                case .center:
                    y = layoutBounds.midY - height / 2
                case .leading, .fill:
                    y = layoutBounds.minY
                }
                subview.frame = CGRect(x: x, y: y, width: width, height: height)
                subview.layoutSubtreeIfNeeded()
                x += width + spacing
            }
        }
    }
}

public protocol UITextViewDelegate: AnyObject {
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
}

public extension UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
        true
    }

    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        true
    }
}

public enum UITextItemInteraction {
    case invokeDefaultAction
}

public class UITextPosition: NSObject {
}

public class UITextRange: NSObject {
    public var isEmpty: Bool {
        false
    }
    public var start: UITextPosition {
        UITextPosition()
    }
    public var end: UITextPosition {
        UITextPosition()
    }
}

public enum UITextGranularity {
    case character
}

public enum UITextLayoutDirection {
    case right
    case left
    case up
    case down
}

public enum UITextStorageDirection {
    case forward
    case backward
}

public struct UITextDirection {
    public static let left = UITextDirection()

    public static func layout(_ direction: UITextDirection) -> UITextDirection {
        direction
    }
}

public class UITextInputTokenizer: NSObject {
    public func rangeEnclosingPosition(
        _ position: UITextPosition,
        with granularity: UITextGranularity,
        inDirection direction: UITextDirection
    ) -> UITextRange? {
        nil
    }
}

public class UITextInputStringTokenizer: UITextInputTokenizer {
    public init(textInput: any UITextInput) {
        super.init()
    }
}

public protocol UITextInputDelegate: AnyObject {
    func selectionWillChange(_ textInput: (any UITextInput)?)
    func selectionDidChange(_ textInput: (any UITextInput)?)
    func textWillChange(_ textInput: (any UITextInput)?)
    func textDidChange(_ textInput: (any UITextInput)?)
}

public extension UITextInputDelegate {
    func selectionWillChange(_ textInput: (any UITextInput)?) {}
    func selectionDidChange(_ textInput: (any UITextInput)?) {}
    func textWillChange(_ textInput: (any UITextInput)?) {}
    func textDidChange(_ textInput: (any UITextInput)?) {}
}

public protocol UIKeyInput: AnyObject {
    var hasText: Bool { get }
    func insertText(_ text: String)
    func deleteBackward()
}

public protocol UITextInput: UIKeyInput {
}

open class UITextView: UIView {
    public weak var delegate: UITextViewDelegate?
    public var adjustsFontForContentSizeCategory = false
    public var attributedText: NSAttributedString? = NSAttributedString()
    public let beginningOfDocument = UITextPosition()
    public var font: UIFont?
    public var isEditable = true
    public var isScrollEnabled = true
    public var isSelectable = true
    public var linkTextAttributes: [NSAttributedString.Key: Any] = [:]
    public var text = ""
    public var textColor: UIColor?
    public var textAlignment = NSTextAlignment.natural
    public var contentSize = CGSize.zero
    public var textContainer = NSTextContainer()
    public var textContainerInset = NSEdgeInsetsZero
    public let tokenizer = UITextInputTokenizer()
    @objc open dynamic var selectedTextRange: UITextRange?

    public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame)
        if let textContainer {
            self.textContainer = textContainer
        }
    }

    public override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func closestPosition(to point: CGPoint) -> UITextPosition? {
        nil
    }

    public func offset(from: UITextPosition, to: UITextPosition) -> Int {
        0
    }

    open func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        []
    }

}

public class UIFontMetrics: NSObject {
    public static let `default` = UIFontMetrics()

    public override init() {
        super.init()
    }

    public init(forTextStyle textStyle: NSFont.TextStyle) {
        super.init()
    }

    public func scaledFont(
        for font: UIFont,
        maximumPointSize: CGFloat,
        compatibleWith traitCollection: UITraitCollection?
    ) -> UIFont {
        font
    }

    public func scaledFont(
        for font: UIFont,
        maximumPointSize: CGFloat
    ) -> UIFont {
        font
    }

    public func scaledFont(
        for font: UIFont,
        compatibleWith traitCollection: UITraitCollection?
    ) -> UIFont {
        font
    }

    public func scaledFont(for font: UIFont) -> UIFont {
        font
    }

    public func scaledValue(for value: CGFloat) -> CGFloat {
        value
    }
}

extension NSDirectionalEdgeInsets {
    public static let zero = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
}

extension NSDirectionalEdgeInsets: Equatable {
    public static func == (lhs: NSDirectionalEdgeInsets, rhs: NSDirectionalEdgeInsets) -> Bool {
        lhs.top == rhs.top &&
            lhs.leading == rhs.leading &&
            lhs.bottom == rhs.bottom &&
            lhs.trailing == rhs.trailing
    }
}

extension NSEdgeInsets {
    public static let zero = NSEdgeInsetsZero
}

extension CGRect {
    public func inset(by insets: NSEdgeInsets) -> CGRect {
        CGRect(
            x: origin.x + insets.left,
            y: origin.y + insets.top,
            width: size.width - insets.left - insets.right,
            height: size.height - insets.top - insets.bottom
        )
    }
}

extension NSFont {
    public var lineHeight: CGFloat {
        ascender - descender + leading
    }

    public static func preferredFont(
        forTextStyle style: NSFont.TextStyle,
        weight: NSFont.Weight,
        maximumPointSize: CGFloat? = nil
    ) -> NSFont {
        systemFont(ofSize: maximumPointSize ?? systemFontSize, weight: weight)
    }

    public static func preferredFont(
        forTextStyle style: NSFont.TextStyle,
        weight: NSFont.Weight
    ) -> NSFont {
        preferredFont(forTextStyle: style, weight: weight, maximumPointSize: nil)
    }
}

public class UIImageAsset: NSObject {
    public func image(with traitCollection: UITraitCollection) -> UIImage {
        UIImage()
    }
}

extension NSImage {
    public enum RenderingMode {
        case alwaysOriginal
        case alwaysTemplate
    }

    public var imageAsset: UIImageAsset? {
        nil
    }

    public convenience init?(
        named name: String,
        in bundle: Bundle?,
        compatibleWith traitCollection: UITraitCollection?
    ) {
        if let bundledImage = bundle?.image(forResource: name) {
            self.init(size: bundledImage.size)
            addRepresentations(bundledImage.representations)
            isTemplate = bundledImage.isTemplate
            return
        }
        self.init(named: name)
    }

    public func withConfiguration(_ configuration: NSImage.SymbolConfiguration?) -> NSImage {
        self
    }

    public func withRenderingMode(_ renderingMode: RenderingMode) -> NSImage {
        let image = copy() as? NSImage ?? self
        switch renderingMode {
        case .alwaysOriginal:
            image.isTemplate = false
        case .alwaysTemplate:
            image.isTemplate = true
        }
        return image
    }

    public func withTintColor(_ color: UIColor, renderingMode: RenderingMode) -> NSImage {
        self
    }

    public func withTintColor(_ color: UIColor) -> NSImage {
        self
    }

    public convenience init?(
        systemName name: String,
        withConfiguration configuration: NSImage.SymbolConfiguration?
    ) {
        self.init(systemSymbolName: name, accessibilityDescription: nil)
    }
}

extension NSColor {
    public static var label: NSColor { .labelColor }
    public static var separator: NSColor { .separatorColor }
    public static var placeholderText: NSColor { .placeholderTextColor }
    public static var opaqueSeparator: NSColor { .separatorColor }
    public static var secondaryLabel: NSColor { .secondaryLabelColor }
    public static var secondarySystemBackground: NSColor { .controlBackgroundColor }
    public static var systemBackground: NSColor { .windowBackgroundColor }
    public static var quaternaryLabel: NSColor { .quaternaryLabelColor }
    public static var systemGray2: NSColor { .secondaryLabelColor }
    public static var systemGray3: NSColor { .tertiaryLabelColor }
    public static var systemGray4: NSColor { .quaternaryLabelColor }
    public static var systemGray5: NSColor { .quaternaryLabelColor }
    public static var systemRed: NSColor { .red }
    public static var tertiaryLabel: NSColor { .tertiaryLabelColor }
    public static var tertiarySystemFill: NSColor { .quaternaryLabelColor }
    public static var tertiarySystemGroupedBackground: NSColor { .underPageBackgroundColor }

    public convenience init(dynamicProvider: (UITraitCollection) -> NSColor) {
        self.init(cgColor: dynamicProvider(.current).cgColor)!
    }

    public func resolvedColor(with traitCollection: UITraitCollection) -> NSColor {
        self
    }
}

extension NSView.AutoresizingMask {
    public static let flexibleWidth = NSView.AutoresizingMask.width
    public static let flexibleHeight = NSView.AutoresizingMask.height
}

extension NSView {
}

extension NSViewController {
    public var isBeingPresented: Bool {
        false
    }

    public var presentationController: UIPresentationController? {
        nil
    }
}

extension NSWindow {
    public var bounds: CGRect {
        frame
    }

    public var rootViewController: UIViewController? {
        get { contentViewController as? UIViewController }
        set { contentViewController = newValue }
    }
}

extension NSScreen {
    public var scale: CGFloat {
        backingScaleFactor
    }
}
#endif
