//
//  STPDelegateProxyTest.m
//  Stripe
//
//  Created by Ben Guo on 3/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPDelegateProxy.h"

@protocol TestDelegate <NSObject>
@optional
- (NSString *)delegateMethod1;
- (NSString *)delegateMethod2;
@end

@interface ConcreteTestDelegate : NSObject<TestDelegate>
@end
@implementation ConcreteTestDelegate

- (NSString *)delegateMethod1 {
    return @"foo";
}

- (NSString *)delegateMethod2 {
    return @"foo";
}

@end

@interface TestClass : NSObject
@property (nonatomic, weak) id<TestDelegate> delegate;
@end

@implementation TestClass
- (NSString *)invokeDelegate1 {
    return [self.delegate delegateMethod1];
}

- (NSString *)invokeDelegate2 {
    return [self.delegate delegateMethod2];
}
@end

@interface TestDelegateProxy : STPDelegateProxy<TestDelegate>
@end
@implementation TestDelegateProxy

- (NSString *)delegateMethod2 {
    return @"bar";
}

@end

@interface STPDelegateProxyTest : XCTestCase

@end

@implementation STPDelegateProxyTest

- (void)testDelegateProxyImplementationOverridesOriginal {
    TestClass *sut = [TestClass new];
    TestDelegateProxy *proxy = [TestDelegateProxy new];
    ConcreteTestDelegate *delegate = [ConcreteTestDelegate new];
    proxy.delegate = delegate;
    sut.delegate = proxy;

    XCTAssertEqualObjects([sut invokeDelegate1], @"foo");
    XCTAssertEqualObjects([sut invokeDelegate2], @"bar");
}

@end
