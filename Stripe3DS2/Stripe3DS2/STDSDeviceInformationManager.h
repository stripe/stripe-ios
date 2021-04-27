//
//  STDSDeviceInformationManager.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/23/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STDSDeviceInformation;
@class STDSWarning;

NS_ASSUME_NONNULL_BEGIN

@interface STDSDeviceInformationManager : NSObject

+ (STDSDeviceInformation *)deviceInformationWithWarnings:(NSArray<STDSWarning *> *)warnings
                                    ignoringRestrictions:(BOOL)ignoreRestrictions;

@end

NS_ASSUME_NONNULL_END
