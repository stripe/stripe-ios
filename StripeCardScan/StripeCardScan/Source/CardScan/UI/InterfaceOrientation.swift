import AVFoundation
//
//  InterfaceOrientation.swift
//  CardScan
//
//  Created by Jaime Park on 4/23/20.
//
import UIKit

extension UIWindow {
    static var interfaceOrientation: UIInterfaceOrientation {
        return
            UIApplication.shared.windows
            .first?
            .windowScene?
            .interfaceOrientation ?? .unknown
    }

    static var interfaceOrientationToString: String {
        switch self.interfaceOrientation {
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portrait_upside_down"
        case .landscapeRight: return "landscape_right"
        case .landscapeLeft: return "landscape_left"
        case .unknown: return "unknown"
        @unknown default:
            return "unknown"
        }
    }
}

extension AVCaptureVideoOrientation {
    init?(
        deviceOrientation: UIDeviceOrientation
    ) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }

    init?(
        interfaceOrientation: UIInterfaceOrientation
    ) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}
