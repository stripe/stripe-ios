//
//  STDSVisionSupport.h
//  Stripe3DS2
//
//  Created by David Estes on 11/21/23.
//

#ifndef STDSVisionSupport_h
#define STDSVisionSupport_h

#ifdef TARGET_OS_VISION
#if TARGET_OS_VISION
#define STP_TARGET_VISION 1
#else
#endif
#else
#define STP_TARGET_VISION 0
#endif


#endif /* STDSVisionSupport_h */
