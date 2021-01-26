//
//  STDSDeviceInformationParameter.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/23/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STDSDeviceInformationParameter : NSObject

+ (NSArray<STDSDeviceInformationParameter *> *)allParameters;

- (void)collectIgnoringRestrictions:(BOOL)ignoreRestrictions withHandler:(void (^)(BOOL, NSString *, id))handler;

@end

NS_ASSUME_NONNULL_END
