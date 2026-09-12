#ifndef MediaPipeSPMGraphReferencesInternal_h
#define MediaPipeSPMGraphReferencesInternal_h

#include <stddef.h>

typedef void (*MediaPipeSPMSymbolReference)(void);

void MediaPipeSPMKeepSymbolReferences(
    const MediaPipeSPMSymbolReference *symbols,
    size_t count
);
void MediaPipeSPMKeepDefaultStreamHandlerReferences(void);
void MediaPipeSPMKeepFaceLandmarkerGraphReferences(void);
void MediaPipeSPMKeepFaceLandmarkerCalculatorReferences(void);

#endif
