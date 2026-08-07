//
//  SelfieCaptureFeedbackGenerator.swift
//  StripeIdentity
//
//  Created by Stripe on 6/24/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import AVFoundation
import UIKit

protocol SelfieCaptureFeedbackGeneratorProtocol {
    func notifyCaptureAccepted()
}

final class SelfieCaptureFeedbackGenerator: SelfieCaptureFeedbackGeneratorProtocol {
    private enum Constants {
        static let confirmationSoundName = "selfie_capture_confirmed"
        static let confirmationSoundExtension = "wav"
        static let confirmationSoundSubdirectory = "Audio"
    }

    private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

    private lazy var audioPlayer: AVAudioPlayer? = {
        guard let url = resourceURL() else {
            return nil
        }

        let audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.prepareToPlay()
        return audioPlayer
    }()

    func notifyCaptureAccepted() {
        notificationFeedbackGenerator.notificationOccurred(.success)

        guard let audioPlayer else {
            return
        }

        if audioPlayer.isPlaying {
            audioPlayer.stop()
        }
        audioPlayer.currentTime = 0
        audioPlayer.play()
    }

    private func resourceURL() -> URL? {
        let bundle = StripeIdentityBundleLocator.resourcesBundle

        return bundle.url(
            forResource: Constants.confirmationSoundName,
            withExtension: Constants.confirmationSoundExtension,
            subdirectory: Constants.confirmationSoundSubdirectory
        ) ?? bundle.url(
            forResource: Constants.confirmationSoundName,
            withExtension: Constants.confirmationSoundExtension
        )
    }
}
