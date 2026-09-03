#include "MediaPipeSPMGraphReferencesInternal.h"

#define MEDIAPIPE_SPM_SYMBOL(name, symbol) \
    extern void name(void) __asm(symbol)

MEDIAPIPE_SPM_SYMBOL(
    MediaPipeSPMFaceLandmarkerGraphGetConfig,
    "__ZN9mediapipe5tasks6vision15face_landmarker19FaceLandmarkerGraph9GetConfigEPNS_15SubgraphContextE"
);
MEDIAPIPE_SPM_SYMBOL(
    MediaPipeSPMFaceDetectorGraphGetConfig,
    "__ZN9mediapipe5tasks6vision13face_detector17FaceDetectorGraph9GetConfigEPNS_15SubgraphContextE"
);
MEDIAPIPE_SPM_SYMBOL(
    MediaPipeSPMFaceGeometryFromLandmarksGraphGetConfig,
    "__ZN9mediapipe5tasks6vision13face_geometry30FaceGeometryFromLandmarksGraph9GetConfigEPNS_15SubgraphContextE"
);
MEDIAPIPE_SPM_SYMBOL(
    MediaPipeSPMMultiFaceLandmarksDetectorGraphGetConfig,
    "__ZN9mediapipe5tasks6vision15face_landmarker31MultiFaceLandmarksDetectorGraph9GetConfigEPNS_15SubgraphContextE"
);
MEDIAPIPE_SPM_SYMBOL(
    MediaPipeSPMSingleFaceLandmarksDetectorGraphGetConfig,
    "__ZN9mediapipe5tasks6vision15face_landmarker32SingleFaceLandmarksDetectorGraph9GetConfigEPNS_15SubgraphContextE"
);
MEDIAPIPE_SPM_SYMBOL(
    MediaPipeSPMFaceBlendshapesGraphGetConfig,
    "__ZN9mediapipe5tasks6vision15face_landmarker20FaceBlendshapesGraph9GetConfigEPNS_15SubgraphContextE"
);
MEDIAPIPE_SPM_SYMBOL(
    MediaPipeSPMTensorsToFaceLandmarksGraphGetConfig,
    "__ZN9mediapipe5tasks6vision15face_landmarker27TensorsToFaceLandmarksGraph9GetConfigEPNS_15SubgraphContextE"
);
MEDIAPIPE_SPM_SYMBOL(
    MediaPipeSPMImagePreprocessingGraphGetConfig,
    "__ZN9mediapipe5tasks10components10processors23ImagePreprocessingGraph9GetConfigEPNS_15SubgraphContextE"
);
MEDIAPIPE_SPM_SYMBOL(
    MediaPipeSPMModelTaskGraphGetConfig,
    "__ZN9mediapipe5tasks4core14ModelTaskGraph9GetConfigEPNS_15SubgraphContextE"
);
MEDIAPIPE_SPM_SYMBOL(
    MediaPipeSPMInferenceCalculatorSelectorImplGetConfig,
    "__ZN9mediapipe4api231InferenceCalculatorSelectorImpl9GetConfigERKNS_26CalculatorGraphConfig_NodeE"
);
MEDIAPIPE_SPM_SYMBOL(
    MediaPipeSPMFaceGeometryEnvGeneratorGetExtension,
    "__ZN9mediapipe4tool12GetExtensionINS_5tasks6vision13face_geometry41FaceGeometryEnvGeneratorCalculatorOptionsELi0EEEPT_RNS_17CalculatorOptionsE"
);
MEDIAPIPE_SPM_SYMBOL(
    MediaPipeSPMFaceGeometryPipelineGetExtension,
    "__ZN9mediapipe4tool12GetExtensionINS_5tasks6vision13face_geometry37FaceGeometryPipelineCalculatorOptionsELi0EEEPT_RNS_17CalculatorOptionsE"
);
MEDIAPIPE_SPM_SYMBOL(
    MediaPipeSPMFaceGeometryGraphGetExtension,
    "__ZN9mediapipe4tool12GetExtensionINS_5tasks6vision13face_geometry5proto24FaceGeometryGraphOptionsELi0EEEPT_RNS_17CalculatorOptionsE"
);
MEDIAPIPE_SPM_SYMBOL(
    MediaPipeSPMModelResourcesGetExtension,
    "__ZN9mediapipe4tool12GetExtensionINS_5tasks4core5proto31ModelResourcesCalculatorOptionsELi0EEEPT_RNS_17CalculatorOptionsE"
);

static const MediaPipeSPMSymbolReference graphReferences[] = {
    MediaPipeSPMFaceLandmarkerGraphGetConfig,
    MediaPipeSPMFaceDetectorGraphGetConfig,
    MediaPipeSPMFaceGeometryFromLandmarksGraphGetConfig,
    MediaPipeSPMMultiFaceLandmarksDetectorGraphGetConfig,
    MediaPipeSPMSingleFaceLandmarksDetectorGraphGetConfig,
    MediaPipeSPMFaceBlendshapesGraphGetConfig,
    MediaPipeSPMTensorsToFaceLandmarksGraphGetConfig,
    MediaPipeSPMImagePreprocessingGraphGetConfig,
    MediaPipeSPMModelTaskGraphGetConfig,
    MediaPipeSPMInferenceCalculatorSelectorImplGetConfig,
    MediaPipeSPMFaceGeometryEnvGeneratorGetExtension,
    MediaPipeSPMFaceGeometryPipelineGetExtension,
    MediaPipeSPMFaceGeometryGraphGetExtension,
    MediaPipeSPMModelResourcesGetExtension,
};

void MediaPipeSPMKeepFaceLandmarkerGraphReferences(void) {
    MediaPipeSPMKeepSymbolReferences(
        graphReferences,
        sizeof(graphReferences) / sizeof(graphReferences[0])
    );
}
