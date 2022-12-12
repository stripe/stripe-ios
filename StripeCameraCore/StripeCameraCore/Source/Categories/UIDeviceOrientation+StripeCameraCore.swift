//
//  UIDeviceOrientation+StripeCameraCore.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 1/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import AVKit
import Foundation
import UIKit

@_spi(STP) extension UIDeviceOrientation {
    public var videoOrientation: AVCaptureVideoOrientation {
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
