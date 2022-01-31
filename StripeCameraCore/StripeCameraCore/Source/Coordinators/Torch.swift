//
//  Torch.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 12/1/21.
//

import Foundation
import AVFoundation

struct Torch {
    enum State {
        case off
        case on
    }
    let device: AVCaptureDevice?
    var state: State
    var lastStateChange: Date
    var level: Float

    init(device: AVCaptureDevice) {
        self.state = .off
        self.lastStateChange = Date()
        if device.hasTorch {
            self.device = device
            if device.isTorchActive {
                self.state = .on
            }
        } else {
            self.device = nil
        }
        self.level = 1.0
    }

    mutating func toggle() {
        self.state = self.state == .on ? .off : .on
        do {
            try self.device?.lockForConfiguration()
            if self.state == .on {
                try self.device?.setTorchModeOn(level: self.level)
            } else {
                self.device?.torchMode = .off
            }
        } catch {
            // no-op
        }
        // Always unlock when we're done even if `setTorchModeOn` threw
        self.device?.unlockForConfiguration()
    }
}
