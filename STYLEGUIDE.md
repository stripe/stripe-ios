# Stripe iOS Objective-C Style Guide

## Ground Rules

### Spacing

- Indent using 4 spaces. No tabs.

- Avoid starting methods with an empty line

- There should not be a need to use multiple consecutive empty lines

- Asterisks should be attached to the variable name `NSString *text` unless it's `NSString * const Text`

### Variable Naming

- Lean towards clarity over compactness

- Avoid single letter variables. Try using `idx` / `jdx` instead of `i` / `j` in for loops.

- Acronyms should be all lowercase as a method prefix (ex:`url` or `urlString`). Otherwise, they should be all caps when occurring elsewhere in the method name, or as a class name (ex: `handleStripeURLCallbackWithURL` or `STPAPIClient`)

- Internal or private methods and ivars should begin with an `_`, e.g. `- (void)_doPrivateStuff` and `id _internalVariable`. This is not required for private properties which should not include an underscore (this is to distinguish them from their underlying variable which automatically has an `_` prefix).

### Control Flow

- Place `else if` and `else` on the same line as the preceding closing curly brace:

```objc
if (condition) {
    // A
} else if (condition) {
    // B
} else {
    // C
}
```

- Always wrap conditional bodies with curly braces

- Each return statement should be on a separate line for ease of debugging. i.e. do NOT write `if (condition) return YES;`

- Use ternary operators sparingly and for simple conditions only:

```objc
type = isCard ? @"card" : @"unknown";

type = dictionary[@"type"] ?: @"default";
```

- `switch` statements for enums should contain an entry for each value and avoid using `default`

### Documentation

- Document using the multi-line syntax in all cases with the content aligned with the first asterisk:

```objc
/**
 This is a one line description for a simple method
 */
- (void)title;

/**
 This is a multi-line description for a complicated method

 @param

 @see https://...
 */
- (void)title;
```

- Header documentation should wrap lines to 80 characters

### Literals

- Use literals to create immutable instances of `NSString`, `NSDictionary`, `NSArray`, `NSNumber`:

```objc
NSArray *brands = @[@"visa", @"mastercard", @"discover"];

NSDictionary *parameters = @{
                              @"currency": @"usd",
                              @"amount": @1000,
                            };
```

- Dictionary colons should be attached to the key

- Align multi-line literals using default Xcode indentation

### Constants

- Use static constants whenever appropriate. Names should start with a capital letter:

```objc
static NSString * const HTTPMethodGET = @"GET";

static const CGFloat ButtonHeight = 100.0;
```

- Any public static constants should be prefixed with `STP`:

```objc
static NSString * const STPSDKVersion = @"11.0.0";
```

### Folders

- We use flat folder structure on disk with some exceptions

- Save files to the appropriate root level folder. Typical folders include:
  - `stripe-ios/Stripe/`
  - `stripe-ios/Tests/Tests/`
  - `stripe-ios/Example/Basic Integration/`
  - `stripe-ios/Example/Non-Card Payment Examples/`

- Save public header files in `stripe-ios/Stripe/PublicHeaders/` for Cocoapods and Swift Package Manager compatibility

## Design Patterns

### Imports

- Ordering for imports in headers
  - Import system frameworks
  - Import superclasses and protocols sorted alphabetically
  - Use `@class` for everything else

```objc
#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPBankAccountParams.h"

@class STPAddress, @STPToken;
```

- Ordering for imports in implementations
  - Import system frameworks
  - Import corresponding headers
  - Import everything else sorted alphabetically

```objc
#import <PassKit/PassKit.h>

#import "STPSource.h"
#import "STPSource+Private.h"

#import "NSDictionary+Stripe.h"
#import "STPSourceOwner.h"
#import "STPSourceReceiver.h"
#import "STPSourceRedirect.h"
#import "STPSourceVerification.h"
```

### Interfaces and Protocols

- Stick to Xcode default spacing for interfaces, categories, and protocols

- Always define `NS_ASSUME_NON_NULL_BEGIN` / `NS_ASSUME_NON_NULL_END` in headers. `NS_ASSUME_NON_NULL_BEGIN` / `NS_ASSUME_NON_NULL_END` should also be used in implementation (`.m`) files

```objc
NS_ASSUME_NON_NULL_BEGIN

@protocol STPSourceProtocol <NSObject>

// ...

@end

// ...

@interface STPSource : NSObject<STPAPIResponseDecodable, STPSourceProtocol>

// ...

@end

// ...

@interface STPSource () <STPInternalAPIResponseDecodable>

// ...

@end

NS_ASSUME_NON_NULL_END
```

- Category methods on certain classes need to be prefixed with `stp_` to avoid collision:

```
// NSDictionary+Stripe.h

@interface NSDictionary (Stripe)

- (NSDictionary *)stp_jsonDictionary;

@end
```

- Define private properties and methods as class extensions inside the implementation. Ex: `STPSource.m`.

- Define internal properties and methods as class extensions inside a `+Private.h` file. Ex: `STPSource+Private.h`.

- Access private properties and methods from test classes by defining a class extension inside the test implementation:

```
//  STPBankAccountTest.m

@interface STPBankAccount ()

+ (STPBankAccountStatus)statusFromString:(NSString *)string;
+ (NSString *)stringFromStatus:(STPBankAccountStatus)status;

@end

@interface STPBankAccountTest : XCTestCase

@end

@implementation STPBankAccountTest

// ...

@end
```

### Properties

- Properties should be defined using this syntax:

```
@property (<nonatomic / atomic>, <weak / copy / _>, <nullable / _>, <readonly / _>) <class> *<name>;

@property (<nonatomic / atomic>, <readonly / _>) <type> <name>;
```

- Omit default properties (`assign`, `readwrite`, `strong`)

- Use `copy` for classes with mutable counterparts such as `NSString`, `NSArray`, `NSDictionary`

- Leverage auto property synthesis whenever possible

- Declare `@synthesize` and `@dynamic` on separate lines for shorter diffs

- Use properties (`self.foo`) instead of their corresponding instance variables (`_foo`). Instance variables should only be accessed directly in initializer methods (`init`, `initWithCoder:`, etc…), `dealloc` methods, and within custom getters and setters. For more information, see [Apple’s docs on using accessor methods in initializer methods and dealloc.](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmPractical.html#//apple_ref/doc/uid/TP40004447-SW6).

### Init

```objc
- (instancetype)init {
    self = [super init];
    if (self) {
        // ...
    }
    return self;
}
```

### Methods

- If a method takes more than three arguments, each argument should be on a separate line.

- See [Coding Guidelines for Cocoa - Naming Methods](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CodingGuidelines/Articles/NamingMethods.html#//apple_ref/doc/uid/20001282-BCIGIJJF)

### Implementation

- Do not use `#define` to define a block of code -- `#define` code is very difficult to debug

- Use `#pragma mark - <text>` and `#pragma mark <text>` to group methods In large implementation files:

```objc
#pragma mark - Button Handlers

#pragma mark - UITableViewDataSource

#pragma mark - UITableViewDelegate
```
