// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all
// Generated using tuist — https://github.com/tuist/tuist

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
public enum IdentityVerificationExampleAsset {
  public static let accentColor = IdentityVerificationExampleColors(name: "AccentColor")
  public static let backArrow = IdentityVerificationExampleImages(name: "BackArrow")
  public static let background = IdentityVerificationExampleImages(name: "Background")
  public static let brandColor = IdentityVerificationExampleColors(name: "BrandColor")
  public static let brandLogo = IdentityVerificationExampleImages(name: "BrandLogo")
  public static let logoImage = IdentityVerificationExampleImages(name: "logo_image")
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

public final class IdentityVerificationExampleColors {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  public private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public private(set) lazy var swiftUIColor: SwiftUI.Color = {
    SwiftUI.Color(asset: self)
  }()
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

public extension IdentityVerificationExampleColors.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: IdentityVerificationExampleColors) {
    let bundle = IdentityVerificationExampleResources.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
public extension SwiftUI.Color {
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  init(asset: IdentityVerificationExampleColors) {
    let bundle = IdentityVerificationExampleResources.bundle
    self.init(asset.name, bundle: bundle)
  }
}
#endif

public struct IdentityVerificationExampleImages {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Image = UIImage
  #endif

  public var image: Image {
    let bundle = IdentityVerificationExampleResources.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let image = bundle.image(forResource: NSImage.Name(name))
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

public extension IdentityVerificationExampleImages.Image {
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the IdentityVerificationExampleImages.image property")
  convenience init?(asset: IdentityVerificationExampleImages) {
    #if os(iOS) || os(tvOS)
    let bundle = IdentityVerificationExampleResources.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public extension SwiftUI.Image {
  init(asset: IdentityVerificationExampleImages) {
    let bundle = IdentityVerificationExampleResources.bundle
    self.init(asset.name, bundle: bundle)
  }

  init(asset: IdentityVerificationExampleImages, label: Text) {
    let bundle = IdentityVerificationExampleResources.bundle
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: IdentityVerificationExampleImages) {
    let bundle = IdentityVerificationExampleResources.bundle
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

// swiftlint:enable all
// swiftformat:enable all
