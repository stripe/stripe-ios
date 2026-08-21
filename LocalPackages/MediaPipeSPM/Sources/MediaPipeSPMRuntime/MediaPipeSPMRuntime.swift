// This target exposes the MediaPipeSPM product and keeps the binary artifacts
// available to downstream SwiftPM clients.
import MediaPipeSPMGraphReferences
@_exported import MediaPipeTasksVision

public func prepareMediaPipeSPMFaceLandmarkerGraph() {
    MediaPipeSPMKeepFaceLandmarkerGraphRegistrations()
}
