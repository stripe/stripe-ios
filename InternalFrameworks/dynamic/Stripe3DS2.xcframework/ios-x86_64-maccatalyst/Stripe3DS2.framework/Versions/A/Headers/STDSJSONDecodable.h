//
//  STDSJSONDecodable.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol STDSJSONDecodable <NSObject>

/**
 Initializes an instance of the class from its JSON representation.
 
 This method recognizes two categories of errors:
 - a required field is missing.
 - a required field value is in valid (e.g. expected 'Y' or 'N' but received 'X').
 
 Errors populating optional fields are ignored.

 @param json The JSON dictionary that represents an object of this type
 @param outError If there was a missing required field or invalid field value, contains an instance of NSError.
 
 @return The object represented by the JSON dictionary.  If the object could not be decoded, returns nil and populates the outError argument.
 */
+ (nullable instancetype)decodedObjectFromJSON:(nullable NSDictionary *)json error:(NSError **)outError;

@end

NS_ASSUME_NONNULL_END
