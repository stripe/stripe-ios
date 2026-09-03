#include "MediaPipeSPMGraphReferencesInternal.h"
#include "MediaPipeSPMGraphReferences.h"

static volatile MediaPipeSPMSymbolReference mediaPipeSPMSymbolSink;

void MediaPipeSPMKeepSymbolReferences(
    const MediaPipeSPMSymbolReference *symbols,
    size_t count
) {
    for (size_t index = 0; index < count; index++) {
        mediaPipeSPMSymbolSink = symbols[index];
    }
}

void MediaPipeSPMKeepFaceLandmarkerGraphRegistrations(void) {
    MediaPipeSPMKeepDefaultStreamHandlerReferences();
    MediaPipeSPMKeepFaceLandmarkerGraphReferences();
    MediaPipeSPMKeepFaceLandmarkerCalculatorReferences();
}
