# MediaPipeSPM

This local Swift package contains artifacts sourced from the
`MediaPipeTasksVision` and `MediaPipeTasksCommon` CocoaPods at version
`0.10.21`.

The checked-in artifacts differ from the upstream CocoaPods distribution in
the following ways:

- The `x86_64` architecture is removed from the simulator slices.
- The MediaPipe Tasks Common graph archives are repackaged as
  `MediaPipeCommonGraphLibraries.xcframework` so Swift Package Manager can
  link the registered calculators required by Face Landmarker.

The artifact refresh process is implemented in `Scripts/refresh_artifacts.sh`.
It also copies the license distributed with the upstream CocoaPods to
`LICENSE-MediaPipe`.

MediaPipe is licensed under the Apache License, Version 2.0. The complete
license and upstream attribution notice are available in
[`LICENSE-MediaPipe`](LICENSE-MediaPipe).

The Face Landmarker model bundled by StripeIdentity is published by the
MediaPipe project:

- Model: <https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task>
- Model card: <https://storage.googleapis.com/mediapipe-assets/Model%20Card%20MediaPipe%20Face%20Mesh%20V2.pdf>
