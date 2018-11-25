//
//  STPNetworkStubbingTestCase.m
//  StripeiOS Tests
//
//  Created by Jack Flintermann on 11/24/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPNetworkStubbingTestCase.h"
#import "STPAPIClient+Private.h"
#import <SWHttpTrafficRecorder/SWHttpTrafficRecorder.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHHTTPStubs+Mocktail.h>

@implementation STPNetworkStubbingTestCase

- (void)setUp {
    [super setUp];
    
    NSMutableArray *components = [[[self name] componentsSeparatedByString:@" "] mutableCopy];
    NSCAssert(components.count == 2, @"Invalid format received from XCTest#name: %@", [self name]);
    [components enumerateObjectsUsingBlock:^(NSString *component, NSUInteger idx, __unused BOOL *stop) {
        components[idx] = [[component componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
    }];
    
    NSString *testClass = components[0];
    NSString *testMethod = components[1];
    NSString *relativePath = [@"recorded_network_traffic" stringByAppendingPathComponent:[testClass stringByAppendingPathComponent:testMethod]];
    
    if (self.recordingMode) {
#if TARGET_OS_SIMULATOR
#else
        NSCAssert(NO, @"Tests executed in recording mode must be run in the simulator.");
#endif
        NSURLSessionConfiguration *config = [STPAPIClient sharedUrlSessionConfiguration];
        SWHttpTrafficRecorder *recorder = [SWHttpTrafficRecorder sharedRecorder];
        
        __block int count = 0;
        [recorder setFileNamingBlock:^NSString *(NSURLRequest *request, __unused NSURLResponse *response, __unused NSString *defaultName) {
            NSString *method = [request.HTTPMethod lowercaseString];
            NSString *urlPath = [request.URL.path stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
            NSString *fileName = [NSString stringWithFormat:@"%@%@_%d", method, urlPath, count];
            fileName = [fileName stringByAppendingPathExtension:@"tail"];
            count++;
            return fileName;
        }];
        
        NSString *testDirectoryName = @"stripe-ios/Tests";
        NSString *basePath = [NSString stringWithFormat:@"%s", __FILE__];
        while (![basePath hasSuffix:testDirectoryName]) {
            NSCAssert([basePath containsString:testDirectoryName], @"Not in a subdirectory of %@: %s", testDirectoryName, __FILE__);
            basePath = [basePath stringByDeletingLastPathComponent];
        }
        NSString *recordingPath = [basePath stringByAppendingPathComponent:relativePath];
        [[NSFileManager defaultManager] removeItemAtPath:recordingPath error:nil];
        NSError *recordingError;
        BOOL success = [[SWHttpTrafficRecorder sharedRecorder] startRecordingAtPath:recordingPath forSessionConfiguration:config error:&recordingError];
        NSCAssert(success, @"Error recording requests: %@", recordingError);
    } else {
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(__unused NSURLRequest * _Nonnull request) {
            return YES;
        } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
            NSCAssert(NO, @"Attempted to hit the live network at %@", request.URL.path);
            return nil;
        }];
        NSBundle *bundle = [NSBundle bundleForClass:self.class];
        NSURL *url = [bundle URLForResource:relativePath withExtension:nil];
        if (url) {
            NSError *stubError;
            [OHHTTPStubs stubRequestsUsingMocktailsAtPath:relativePath inBundle:bundle error:&stubError];
            NSCAssert(!stubError, @"Error stubbing requests: %@", stubError);
        } else {
            NSLog(@"No stubs found - all network access will raise an exception.");
        }
    }
}

- (void)tearDown {
    [super tearDown];
    [[SWHttpTrafficRecorder sharedRecorder] stopRecording];
    [OHHTTPStubs removeAllStubs];
}

@end
