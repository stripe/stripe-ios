//
//  STDSLocalizedString.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 7/9/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSBundleLocator.h"

#ifndef STDSLocalizedString_h
#define STDSLocalizedString_h

#define STDSLocalizedString(key, comment) \
[[STDSBundleLocator stdsResourcesBundle] localizedStringForKey:(key) value:@"" table:nil]


#endif /* STDSLocalizedString_h */
