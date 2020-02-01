#!/usr/bin/env ruby

PAYMENT_METHOD_NAME = "BacsDebit"
PAYMENT_METHOD_API_TYPE = "bacs_debit"
PAYMENT_METHOD_PROPERTY_NAME = "bacsDebit"

TODO = "TODO(#{PAYMENT_METHOD_NAME})"

# Appends line_to_add to the lines matching similar_lines_regex
def append_line_to_similar_lines(filename, line_to_add, similar_lines_regex)
	file_lines = File.readlines(filename)

	new_file_lines = ""
	seeing_matching_lines = false
	multiline_comment = false
    File.foreach(filename) do |line|
        # puts line
        # # Ignore newlines
        # if /^\p{Space}$/.match(line)
        #     puts "newline"
        #     new_file_lines += line
        #     next
        # end

        # # Ignore comments
		# if /\/\*\*/.match(line)
        #     puts "comment start"
        #     multiline_comment = true
        #     new_file_lines += line
        #     next
        # elsif multiline_comment
        #     if /\*\//.match(line)
        #         puts "comment end"
        #         multiline_comment = false
        #     end
        #     new_file_lines += line
        #     next
		# end

        if similar_lines_regex.match(line)
			seeing_matching_lines = true
		elsif seeing_matching_lines == true and line_to_add
            seeing_matching_lines = false
            # Inherit the indentation of the previous line
            previous_line =  new_file_lines.split("\n").last
            previous_line_indentation = " " * (previous_line.length - previous_line.lstrip.length)
            # previous_line_indentation = /^(\s)+/.match(new_file_lines.split('\n').last)[0]

			new_file_lines += previous_line_indentation + line_to_add + "\n"
			line_to_add = nil # to avoid adding more than once
		end
		new_file_lines += line
	end

	File.write(filename, new_file_lines)
end

# STPPaymentMethodX.h
payment_method_h = File.new("Stripe/PublicHeaders/STPPaymentMethod#{PAYMENT_METHOD_NAME}.h", "w")
payment_method_h.puts(
%(//
//  STPPaymentMethod#{PAYMENT_METHOD_NAME}.h
//  StripeiOS
//
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 #{TODO}

 @see https://stripe.com/docs/api/payment_methods/object#payment_method_object-#{PAYMENT_METHOD_API_TYPE}
 */
@interface STPPaymentMethod#{PAYMENT_METHOD_NAME} : NSObject <STPAPIResponseDecodable>

/**
You cannot directly instantiate an `STPPaymentMethod#{PAYMENT_METHOD_NAME}`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
- (instancetype)init NS_UNAVAILABLE;

/**
 TODO(#{PAYMENT_METHOD_NAME})

 Example property
 */
@property (nonatomic, nullable, readonly) NSString *fingerprint;

@end

NS_ASSUME_NONNULL_END
))
payment_method_h.close

# STPPaymentMethodX.m
payment_method_m = File.new("Stripe/STPPaymentMethod#{PAYMENT_METHOD_NAME}.m", "w")
payment_method_m.puts(
%(//
//  STPPaymentMethod#{PAYMENT_METHOD_NAME}.m
//  StripeiOS
//
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethod#{PAYMENT_METHOD_NAME}.h"

#import "NSDictionary+Stripe.h"

@implementation STPPaymentMethod#{PAYMENT_METHOD_NAME}

@synthesize allResponseFields = _allResponseFields;

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // #{TODO}
                       // e.g. [NSString stringWithFormat:@"fingerprint = %@", self.fingerprint],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
    	// #{TODO}
    	// e.g. _fingerprint = [[dict stp_stringForKey:@"fingerprint"] copy];

        _allResponseFields = dict.copy;
    }
    return self;
}

@end
))
payment_method_m.close

# Add import to Stripe.h
# TODO

# STPPaymentMethodXTest
payment_method_test_m = File.new("Tests/Tests/STPPaymentMethod#{PAYMENT_METHOD_NAME}Test.m", "w")
payment_method_test_m.puts(
%(//
//  STPPaymentMethod#{PAYMENT_METHOD_NAME}Test.m
//  StripeiOS Tests
//
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestUtils.h"
#import "STPFixtures.h"

@interface STPPaymentMethod#{PAYMENT_METHOD_NAME}Test : XCTestCase

@end

@implementation STPPaymentMethod#{PAYMENT_METHOD_NAME}Test

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSDictionary *paymentMethodJSON = [STPTestUtils jsonNamed:STPTestJSONPaymentMethod#{PAYMENT_METHOD_NAME}];
    NSArray<NSString *> *requiredFields = @[/* #{TODO} Add required fields */];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [paymentMethodJSON[@"#{PAYMENT_METHOD_API_TYPE}"] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPPaymentMethod#{PAYMENT_METHOD_NAME} decodedObjectFromAPIResponse:response]);
    }

    STPPaymentMethod *paymentMethod = [STPPaymentMethod decodedObjectFromAPIResponse:paymentMethodJSON];
    XCTAssertNotNil(paymentMethod);
    XCTAssertNotNil(paymentMethod.#{PAYMENT_METHOD_PROPERTY_NAME});
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONPaymentMethod#{PAYMENT_METHOD_NAME}][@"#{PAYMENT_METHOD_API_TYPE}"];
    STPPaymentMethod#{PAYMENT_METHOD_NAME} *pm = [STPPaymentMethod#{PAYMENT_METHOD_NAME} decodedObjectFromAPIResponse:response];
    // #{TODO}
    // e.g. XCTAssertEqualObjects(bacs.fingerprint, @"9eMbmctOrd8i7DYa");
}

@end
))
payment_method_test_m.close

# Add STPTestJSONPaymentMethodX to Tests/Tests/STPFixtures.m
append_line_to_similar_lines("Tests/Tests/STPFixtures.m",
	%(NSString *const STPTestJSONPaymentMethod#{PAYMENT_METHOD_NAME} = @"#{PAYMENT_METHOD_NAME}PaymentMethod";),
    /NSString \*const STPTestJSONPaymentMethod/)

# Add STPTestJSONPaymentMethodX to Tests/Tests/STPFixtures.h
append_line_to_similar_lines("Tests/Tests/STPFixtures.h",
	%(extern NSString *const STPTestJSONPaymentMethod#{PAYMENT_METHOD_NAME};),
	/extern NSString \*const STPTestJSONPaymentMethod/)

# Add XPaymentMethod.json
payment_method_json = File.new("Tests/Tests/#{PAYMENT_METHOD_NAME}PaymentMethod.json", "w")
payment_method_json.puts("#{TODO} Create the PaymentMethod and paste the response")
payment_method_json.close

# Add property to STPPaymentMethod.h
append_line_to_similar_lines("Stripe/PublicHeaders/STPPaymentMethod.h",
	"
/**
 If this is a #{TODO} PaymentMethod (ie `self.type == STPPaymentMethodType#{PAYMENT_METHOD_NAME}`), this contains additional details.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodBacsDebit *bacsDebit;",
	/@property \(nonatomic, nullable, readonly\) STPPaymentMethod/)

# TODO Append @class STPPaymentMethodX

## Add stuff to STPPaymentMethod.m
append_line_to_similar_lines("Stripe/STPPaymentMethod.m",
	"#import \"STPPaymentMethod#{PAYMENT_METHOD_NAME}.h // #{TODO} Sort alphabetically \"",
	/#import "STPPaymentMethod\w+\.h/)

append_line_to_similar_lines("Stripe/STPPaymentMethod.m",
	"@property (nonatomic, strong, nullable, readwrite) STPPaymentMethod#{PAYMENT_METHOD_NAME} *#{PAYMENT_METHOD_PROPERTY_NAME};",
	/@property \(nonatomic, strong, nullable, readwrite\) STPPaymentMethod/)

append_line_to_similar_lines("Stripe/STPPaymentMethod.m",
	"[NSString stringWithFormat:@\"#{PAYMENT_METHOD_PROPERTY_NAME} = %@\", self.bacsDebit], // #{TODO} Sort alphabetically",
    /STPPaymentMethod details \(alphabetical\)/)

append_line_to_similar_lines("Stripe/STPPaymentMethod.m",
    "@\"bacs_debit\": @(STPPaymentMethodTypeBacsDebit),",
	/@\"\w+\": @/)

append_line_to_similar_lines("Stripe/STPPaymentMethod.m",
	"paymentMethod.#{PAYMENT_METHOD_PROPERTY_NAME} = [STPPaymentMethod#{PAYMENT_METHOD_NAME} decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@\"#{PAYMENT_METHOD_API_TYPE}\"]];",
	/paymentMethod\.\w+ = /)

# Add enum
append_line_to_similar_lines("Stripe/PublicHeaders/STPPaymentMethodEnums.h",
    "
    /**
    A #{TODO} payment method.
    */
    STPPaymentMethodType#{PAYMENT_METHOD_NAME},",
	/STPPaymentMethodType\w+,/)

puts "
Added some boilerplate. Now, you need to:

 1. Add the generated new files to the project
 2. Search and fix #{TODO}
 3. Fix compiler errors
 4. Profit
 "