//
//  STDSJSONEncoder.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STDSJSONEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 `STDSJSONEncoder` is a utility class to help with converting API objects into JSON
 */
@interface STDSJSONEncoder : NSObject

/**
 Method to convert an STDSJSONEncodable object into a JSON dictionary.
 */
+ (NSDictionary *)dictionaryForObject:(NSObject<STDSJSONEncodable> *)object;

@end

NS_ASSUME_NONNULL_END
