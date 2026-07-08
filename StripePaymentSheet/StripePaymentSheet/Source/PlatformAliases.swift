#if canImport(AppKit) && !canImport(UIKit)
import AppKit
import QuartzCore
import SwiftUI
@_spi(STP) import StripeUICore

typealias CABasicAnimation = QuartzCore.CABasicAnimation
typealias CAAnimationGroup = QuartzCore.CAAnimationGroup
typealias CGColor = CoreGraphics.CGColor
typealias CGPath = CoreGraphics.CGPath
typealias CALayer = QuartzCore.CALayer
typealias CAShapeLayer = QuartzCore.CAShapeLayer
typealias CAGradientLayer = QuartzCore.CAGradientLayer
typealias CAShapeLayerFillRule = QuartzCore.CAShapeLayerFillRule
typealias CATransaction = QuartzCore.CATransaction
typealias CAMediaTimingFunction = QuartzCore.CAMediaTimingFunction
typealias CAMediaTimingFunctionName = QuartzCore.CAMediaTimingFunctionName
typealias NSLayoutConstraint = AppKit.NSLayoutConstraint
typealias NSLayoutDimension = AppKit.NSLayoutDimension
typealias NSLayoutManager = AppKit.NSLayoutManager
public typealias NSDirectionalEdgeInsets = AppKit.NSDirectionalEdgeInsets
typealias NSUnderlineStyle = AppKit.NSUnderlineStyle
typealias NSMutableParagraphStyle = AppKit.NSMutableParagraphStyle
typealias NSTextAttachment = AppKit.NSTextAttachment
typealias NSTextContainer = AppKit.NSTextContainer
typealias NSTextStorage = AppKit.NSTextStorage
public typealias NSTextAlignment = AppKit.NSTextAlignment
public typealias UIAction = StripeUICore.UIAction
public typealias UIAdaptivePresentationControllerDelegate = StripeUICore.UIAdaptivePresentationControllerDelegate
public typealias UIAccessibility = StripeUICore.UIAccessibility
public typealias UIAccessibilityCustomAction = StripeUICore.UIAccessibilityCustomAction
public typealias UIAlertAction = StripeUICore.UIAlertAction
public typealias UIAlertController = StripeUICore.UIAlertController
public typealias UIApplication = StripeUICore.UIApplication
public typealias UIBarButtonItem = StripeUICore.UIBarButtonItem
public typealias UIBezierPath = StripeUICore.UIBezierPath
public typealias UIButton = StripeUICore.UIButton
public typealias UIColor = StripeUICore.UIColor
public typealias UIControl = StripeUICore.UIControl
public typealias UIContextMenuInteraction = StripeUICore.UIContextMenuInteraction
public typealias UIContextMenuActionProvider = StripeUICore.UIContextMenuActionProvider
public typealias UIContextMenuConfiguration = StripeUICore.UIContextMenuConfiguration
public typealias UIEdgeInsets = StripeUICore.UIEdgeInsets
public typealias UIEvent = StripeUICore.UIEvent
public typealias UIImage = StripeUICore.UIImage
public typealias UIImageView = StripeUICore.UIImageView
public typealias UIImpactFeedbackGenerator = StripeUICore.UIImpactFeedbackGenerator
public typealias UIKeyCommand = StripeUICore.UIKeyCommand
public typealias UIKeyboardAppearance = StripeUICore.UIKeyboardAppearance
public typealias UIKeyboardType = StripeUICore.UIKeyboardType
public typealias UILayoutPriority = StripeUICore.UILayoutPriority
public typealias UIInteraction = StripeUICore.UIInteraction
public typealias UILabel = StripeUICore.UILabel
public typealias UIMenu = StripeUICore.UIMenu
public typealias UIMenuElement = StripeUICore.UIMenuElement
public typealias UINavigationController = StripeUICore.UINavigationController
public typealias UINotificationFeedbackGenerator = StripeUICore.UINotificationFeedbackGenerator
public typealias UIPasteboard = StripeUICore.UIPasteboard
public typealias UIPickerView = StripeUICore.UIPickerView
public typealias UIPresentationController = StripeUICore.UIPresentationController
public typealias UISelectionFeedbackGenerator = StripeUICore.UISelectionFeedbackGenerator
public typealias UIStackView = StripeUICore.UIStackView
public typealias UISpringTimingParameters = StripeUICore.UISpringTimingParameters
public typealias UIScrollEdgeElementContainerInteraction = StripeUICore.UIScrollEdgeElementContainerInteraction
public typealias UITapGestureRecognizer = StripeUICore.UITapGestureRecognizer
public typealias UITextContentType = StripeUICore.UITextContentType
public typealias UITextField = StripeUICore.UITextField
public typealias UITextFieldDelegate = StripeUICore.UITextFieldDelegate
public typealias UITextItemInteraction = StripeUICore.UITextItemInteraction
public typealias UITextPosition = StripeUICore.UITextPosition
public typealias UITextRange = StripeUICore.UITextRange
public typealias UITextSelectionRect = StripeUICore.UITextSelectionRect
public typealias UITextView = StripeUICore.UITextView
public typealias UITraitCollection = StripeUICore.UITraitCollection
public typealias UIDevice = StripeUICore.UIDevice
public typealias UIDeviceOrientation = StripeUICore.UIDeviceOrientation
public typealias UIFontDescriptor = AppKit.NSFontDescriptor
public typealias UIFontMetrics = StripeUICore.UIFontMetrics
public typealias UIView = StripeUICore.UIView
public typealias UIViewControllerAnimatedTransitioning = StripeUICore.UIViewControllerAnimatedTransitioning
public typealias UIViewControllerContextTransitioning = StripeUICore.UIViewControllerContextTransitioning
public typealias UIViewControllerTransitionCoordinator = StripeUICore.UIViewControllerTransitionCoordinator
public typealias UIViewControllerTransitioningDelegate = StripeUICore.UIViewControllerTransitioningDelegate
public typealias UIViewController = StripeUICore.UIViewController
public typealias UIViewPropertyAnimator = StripeUICore.UIViewPropertyAnimator
public typealias UIWindow = StripeUICore.UIWindow
public typealias UIWindowScene = StripeUICore.UIWindowScene
public typealias UITransitionContextViewControllerKey = StripeUICore.UITransitionContextViewControllerKey

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

public class UIScrollView: UIView {
    public enum KeyboardDismissMode {
        case none
        case onDrag
    }

    public enum ContentInsetAdjustmentBehavior {
        case automatic
        case never
    }

    public var keyboardDismissMode = KeyboardDismissMode.none
    public var contentInset = NSEdgeInsetsZero
    public var verticalScrollIndicatorInsets = NSEdgeInsetsZero
    public var automaticallyAdjustsScrollIndicatorInsets = true
    public var contentInsetAdjustmentBehavior = ContentInsetAdjustmentBehavior.automatic
    public var contentSize = CGSize.zero
    public var contentOffset = CGPoint.zero
    public var alwaysBounceVertical = false
    public weak var delegate: AnyObject?
    public let frameLayoutGuide = NSLayoutGuide()
    public let contentLayoutGuide = NSLayoutGuide()

    public func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        self.contentOffset = contentOffset
    }

    public func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
    }

    public func updateConstraintsIfNeeded() {
        updateConstraints()
    }
}

public protocol UIScrollViewDelegate: AnyObject {
}

public class UIVisualEffect: NSObject {
}

public class UIBlurEffect: UIVisualEffect {
    public enum Style {
        case systemUltraThinMaterialDark
    }

    public init(style: Style) {
        super.init()
    }
}

public class UIVibrancyEffect: UIVisualEffect {
    public init(blurEffect: UIBlurEffect) {
        super.init()
    }
}

public class UIVisualEffectView: UIView {
    public let contentView = UIView()
    public var effect: UIVisualEffect?

    public init(effect: UIVisualEffect?) {
        self.effect = effect
        super.init(frame: .zero)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

public class UIHostingController<Content: SwiftUI.View>: UIViewController {
    public let rootView: Content

    public init(rootView: Content) {
        self.rootView = rootView
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        nil
    }
}

public class UICollectionViewLayout: NSObject {
    public func invalidateLayout() {
    }
}

public class UICollectionViewFlowLayout: UICollectionViewLayout {
    public enum ScrollDirection {
        case vertical
        case horizontal
    }

    public var itemSize = CGSize.zero
    public var minimumInteritemSpacing: CGFloat = 0
    public var minimumLineSpacing: CGFloat = 0
    public var scrollDirection = ScrollDirection.vertical
    public var sectionInset = UIEdgeInsets()
}

public protocol UICollectionViewDataSource: AnyObject {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
}

public protocol UICollectionViewDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool
}

public protocol UICollectionViewDelegateFlowLayout: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
}

public extension UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        true
    }
}

public extension UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        (collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize ?? .zero
    }
}

public class UICollectionViewCell: UIView {
    public let contentView = UIView()
    public var isSelected = false {
        didSet {
            setNeedsDisplay()
        }
    }
    public required override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        addSubview(contentView)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(contentView)
    }

    public override func layout() {
        super.layout()
        contentView.frame = bounds
    }
}

public class UICollectionView: UIScrollView {
    public var collectionViewLayout: UICollectionViewLayout
    public weak var dataSource: UICollectionViewDataSource?
    public var indexPathsForSelectedItems: [IndexPath]?
    public var showsHorizontalScrollIndicator = true
    private var cellClassesByReuseIdentifier: [String: UICollectionViewCell.Type] = [:]
    private var cellsByIndexPath: [IndexPath: UICollectionViewCell] = [:]
    public var visibleCells: [UICollectionViewCell] {
        cellsByIndexPath.keys.sorted().compactMap { cellsByIndexPath[$0] }
    }

    public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        self.collectionViewLayout = layout
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        self.collectionViewLayout = UICollectionViewLayout()
        super.init(coder: coder)
    }

    public func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        if let cellClass = cellClass as? UICollectionViewCell.Type {
            cellClassesByReuseIdentifier[identifier] = cellClass
        }
    }

    public func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionViewCell {
        let cellClass = cellClassesByReuseIdentifier[identifier] ?? UICollectionViewCell.self
        return cellClass.init(frame: .zero)
    }

    public func reloadData() {
        cellsByIndexPath.values.forEach { $0.removeFromSuperview() }
        cellsByIndexPath.removeAll()
        guard let dataSource else {
            return
        }
        let itemCount = dataSource.collectionView(self, numberOfItemsInSection: 0)
        for item in 0..<itemCount {
            let indexPath = IndexPath(item: item, section: 0)
            let cell = dataSource.collectionView(self, cellForItemAt: indexPath)
            cell.isSelected = indexPathsForSelectedItems?.contains(indexPath) ?? false
            cellsByIndexPath[indexPath] = cell
            addSubview(cell)
        }
        needsLayout = true
    }

    public func reloadItems(at indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            cellsByIndexPath[indexPath]?.removeFromSuperview()
            if let cell = dataSource?.collectionView(self, cellForItemAt: indexPath) {
                cell.isSelected = indexPathsForSelectedItems?.contains(indexPath) ?? false
                cellsByIndexPath[indexPath] = cell
                addSubview(cell)
            }
        }
        needsLayout = true
    }

    public func reloadItems(at indexPaths: [IndexPath], animated: Bool) {
        reloadItems(at: indexPaths)
    }

    public func reloadSections(_ sections: IndexSet) {
        reloadData()
    }

    public func deleteItems(at indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            cellsByIndexPath.removeValue(forKey: indexPath)?.removeFromSuperview()
        }
        needsLayout = true
    }

    public func selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: ScrollPosition) {
        for cell in cellsByIndexPath.values {
            cell.isSelected = false
        }
        indexPathsForSelectedItems = indexPath.map { [$0] }
        if let indexPath {
            cellsByIndexPath[indexPath]?.isSelected = true
        }
    }

    public func scrollToItem(at indexPath: IndexPath, at scrollPosition: ScrollPosition, animated: Bool) {
    }

    public func deselectItem(at indexPath: IndexPath, animated: Bool) {
        cellsByIndexPath[indexPath]?.isSelected = false
        indexPathsForSelectedItems?.removeAll { $0 == indexPath }
    }

    public func indexPath(for cell: UICollectionViewCell) -> IndexPath? {
        cellsByIndexPath.first { $0.value === cell }?.key
    }

    public func cellForItem(at indexPath: IndexPath) -> UICollectionViewCell? {
        cellsByIndexPath[indexPath]
    }

    public func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        updates?()
        completion?(true)
    }

    public struct ScrollPosition: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let centeredHorizontally = ScrollPosition(rawValue: 1 << 0)
        public static let bottom = ScrollPosition(rawValue: 1 << 1)
        public static let left = ScrollPosition(rawValue: 1 << 2)
    }

    public override func layout() {
        super.layout()
        if cellsByIndexPath.isEmpty {
            reloadData()
        }

        guard !cellsByIndexPath.isEmpty else {
            return
        }

        let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
        let sortedIndexPaths = cellsByIndexPath.keys.sorted()
        let inset = flowLayout?.sectionInset ?? .zero
        let interitemSpacing = flowLayout?.minimumInteritemSpacing ?? 0
        var origin = CGPoint(x: inset.left, y: inset.top)

        for indexPath in sortedIndexPaths {
            guard let cell = cellsByIndexPath[indexPath] else {
                continue
            }
            let delegateSize = (delegate as? UICollectionViewDelegateFlowLayout)?
                .collectionView(self, layout: collectionViewLayout, sizeForItemAt: indexPath) ?? .zero
            let fallbackSize = flowLayout?.itemSize == .zero ? CGSize(width: 96, height: max(44, bounds.height - inset.top - inset.bottom)) : (flowLayout?.itemSize ?? .zero)
            let itemSize = delegateSize == .zero ? fallbackSize : delegateSize
            cell.frame = CGRect(origin: origin, size: itemSize)
            if flowLayout?.scrollDirection == .horizontal {
                origin.x += itemSize.width + interitemSpacing
            } else {
                origin.y += itemSize.height + (flowLayout?.minimumLineSpacing ?? interitemSpacing)
            }
        }

        contentSize = CGSize(width: max(bounds.width, origin.x + inset.right), height: max(bounds.height, origin.y + inset.bottom))
    }

    public override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let (indexPath, _) = cellsByIndexPath.first(where: { $0.value.frame.contains(point) }) else {
            return
        }
        guard (delegate as? UICollectionViewDelegate)?.collectionView(self, shouldSelectItemAt: indexPath) ?? true else {
            return
        }
        selectItem(at: indexPath, animated: false, scrollPosition: [])
        (delegate as? UICollectionViewDelegate)?.collectionView(self, didSelectItemAt: indexPath)
    }
}

public protocol UITableViewDataSource: AnyObject {
}

public protocol UITableViewDelegate: AnyObject {
}

public class UITableViewCell: UIView {
    public enum CellStyle {
        case `default`
        case subtitle
    }

    public let contentView = UIView()
    public let textLabel: UILabel? = UILabel()
    public let detailTextLabel: UILabel? = UILabel()
    public var indentationWidth: CGFloat = 0

    public init(style: CellStyle, reuseIdentifier: String?) {
        super.init(frame: .zero)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

public class UITableView: UIScrollView {
    public weak var dataSource: UITableViewDataSource?
    public var separatorColor: UIColor?
    public var tableFooterView: UIView?

    public func reloadData() {
    }

    public func dequeueReusableCell(withIdentifier identifier: String) -> UITableViewCell? {
        nil
    }
}

extension IndexPath {
    public init(row: Int, section: Int) {
        self.init(item: row, section: section)
    }

    public var row: Int {
        item
    }
}

extension NSAttributedString.Key {
    static let accessibilitySpeechPitch = NSAttributedString.Key("UIAccessibilitySpeechAttributePitch")
    static let accessibilitySpeechSpellOut = NSAttributedString.Key("UIAccessibilitySpeechAttributeSpellOut")
}

extension UIEdgeInsets: @retroactive Equatable {
    public static func == (lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> Bool {
        lhs.top == rhs.top &&
        lhs.left == rhs.left &&
        lhs.bottom == rhs.bottom &&
        lhs.right == rhs.right
    }
}

extension NSLayoutConstraint.Priority {
    static let fittingSizeLevel = NSLayoutConstraint.Priority(rawValue: 50)

    static func + (lhs: NSLayoutConstraint.Priority, rhs: Int) -> NSLayoutConstraint.Priority {
        NSLayoutConstraint.Priority(rawValue: lhs.rawValue + Float(rhs))
    }

    static func - (lhs: NSLayoutConstraint.Priority, rhs: Int) -> NSLayoutConstraint.Priority {
        NSLayoutConstraint.Priority(rawValue: lhs.rawValue - Float(rhs))
    }
}

let CATransform3DIdentity = QuartzCore.CATransform3DIdentity

func CATransform3DScale(_ t: CATransform3D, _ sx: CGFloat, _ sy: CGFloat, _ sz: CGFloat) -> CATransform3D {
    QuartzCore.CATransform3DScale(t, sx, sy, sz)
}

func CACurrentMediaTime() -> CFTimeInterval {
    QuartzCore.CACurrentMediaTime()
}

final class UIScreen {
    static let main = UIScreen()

    var bounds: CGRect {
        NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1024, height: 768)
    }

    var scale: CGFloat {
        NSScreen.main?.backingScaleFactor ?? 1
    }

    var nativeScale: CGFloat {
        scale
    }
}

private var currentImageContextSize = CGSize(width: 1, height: 1)

func UIGraphicsBeginImageContextWithOptions(_ size: CGSize, _ opaque: Bool, _ scale: CGFloat) {
    currentImageContextSize = size
}

func UIRectFill(_ rect: CGRect) {
}

func UIGraphicsGetImageFromCurrentImageContext() -> UIImage? {
    UIImage(size: currentImageContextSize)
}

func UIGraphicsEndImageContext() {
}

func UIGraphicsGetCurrentContext() -> CGContext? {
    CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
}

final class UIGraphicsImageRenderer {
    private let size: CGSize

    init(size: CGSize) {
        self.size = size
    }

    func image(actions: (CGContext) -> Void) -> UIImage {
        let image = UIImage(size: size)
        actions(CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!)
        return image
    }
}

extension NSImage {
    convenience init?(data: Data, scale: CGFloat) {
        self.init(data: data)
    }

    func withAlignmentRectInsets(_ alignmentInsets: UIEdgeInsets) -> NSImage {
        self
    }

    func pngData() -> Data? {
        tiffRepresentation
    }
}

extension NSFontDescriptor {
    static func preferredFontDescriptor(withTextStyle style: NSFont.TextStyle, compatibleWith traitCollection: UITraitCollection?) -> NSFontDescriptor {
        NSFont.preferredFont(forTextStyle: style).fontDescriptor
    }
}

extension NSImage.SymbolConfiguration {
    convenience init(font: UIFont) {
        self.init(pointSize: font.pointSize, weight: .regular)
    }
}

extension NSView {
    func addGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
    }

    func endEditing(_ force: Bool) -> Bool {
        window?.makeFirstResponder(nil) ?? false
    }

    func firstResponder() -> UIView? {
        window?.firstResponder as? UIView
    }

    func convert(_ rect: CGRect, from window: NSWindow?) -> CGRect {
        convert(rect, from: nil as NSView?)
    }
}

extension NSLayoutGuide {
    var layoutFrame: CGRect {
        owningView?.bounds ?? .zero
    }
}

extension NSValue {
    var cgRectValue: CGRect {
        rectValue
    }
}
#endif
