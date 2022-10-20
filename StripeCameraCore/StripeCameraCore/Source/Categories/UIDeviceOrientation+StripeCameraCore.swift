//
//  UIDeviceOrientation+StripeCameraCore.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 1/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import AVKit
import UIKit

@_spi(STP) public extension UIDeviceOrientation {
    var videoOrientation: AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
}
