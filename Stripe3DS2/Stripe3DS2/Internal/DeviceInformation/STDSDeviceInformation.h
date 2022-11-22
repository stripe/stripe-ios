//
//  STDSDeviceInformation.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 3/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STDSDeviceInformation : NSObject

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)deviceInformationDict;

@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *dictionaryValue;

@end

NS_ASSUME_NONNULL_END
