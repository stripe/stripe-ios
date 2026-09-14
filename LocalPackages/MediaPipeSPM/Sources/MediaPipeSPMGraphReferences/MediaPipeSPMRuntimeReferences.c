#include "MediaPipeSPMGraphReferencesInternal.h"

#define MEDIAPIPE_SPM_SYMBOL(name, symbol) \
    extern void name(void) __asm(symbol)

MEDIAPIPE_SPM_SYMBOL(MediaPipeSPMDefaultInputStreamHandlerDestructor, "__ZN9mediapipe25DefaultInputStreamHandlerD1Ev");
MEDIAPIPE_SPM_SYMBOL(MediaPipeSPMInOrderOutputStreamHandlerDestructor, "__ZN9mediapipe26InOrderOutputStreamHandlerD1Ev");

static const MediaPipeSPMSymbolReference runtimeReferences[] = {
    MediaPipeSPMDefaultInputStreamHandlerDestructor,
    MediaPipeSPMInOrderOutputStreamHandlerDestructor,
};

void MediaPipeSPMKeepDefaultStreamHandlerReferences(void) {
    MediaPipeSPMKeepSymbolReferences(
        runtimeReferences,
        sizeof(runtimeReferences) / sizeof(runtimeReferences[0])
    );
}
