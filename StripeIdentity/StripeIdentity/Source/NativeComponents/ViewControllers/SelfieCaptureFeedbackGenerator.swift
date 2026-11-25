//
//  SelfieCaptureFeedbackGenerator.swift
//  StripeIdentity
//
//  Created by Stripe on 6/24/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import AudioToolbox
import UIKit

protocol SelfieCaptureFeedbackGeneratorProtocol {
    func notifyCaptureAccepted()
}

final class SelfieCaptureFeedbackGenerator: SelfieCaptureFeedbackGeneratorProtocol {
    private enum Constants {
        static let confirmationSoundName = "selfie_capture_confirmed"
        static let confirmationSoundExtension = "wav"
    }

    private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

    // Capture is accepted on the main thread, where AVAudioPlayer.play() starts the audio hardware
    // synchronously and can block for seconds. A system sound plays asynchronously.
    let confirmationSoundID: SystemSoundID?

    init() {
        var soundID: SystemSoundID = 0
        if let url = Self.resourceURL(),
            AudioServicesCreateSystemSoundID(url as CFURL, &soundID) == kAudioServicesNoError
        {
            confirmationSoundID = soundID
        } else {
            confirmationSoundID = nil
        }
    }

    deinit {
        if let confirmationSoundID {
            AudioServicesDisposeSystemSoundID(confirmationSoundID)
        }
    }

    func notifyCaptureAccepted() {
        notificationFeedbackGenerator.notificationOccurred(.success)

        guard let confirmationSoundID else {
            return
        }

        AudioServicesPlaySystemSoundWithCompletion(confirmationSoundID, nil)
    }

    private static func resourceURL() -> URL? {
        let bundle = StripeIdentityBundleLocator.resourcesBundle

        return bundle.url(
            forResource: Constants.confirmationSoundName,
            withExtension: Constants.confirmationSoundExtension
        )
    }
}
