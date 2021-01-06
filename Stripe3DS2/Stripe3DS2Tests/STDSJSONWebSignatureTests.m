//
//  STDSJSONWebSignatureTests.m
//  Stripe3DS2Tests
//
//  Created by Cameron Sabol on 4/2/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSString+JWEHelpers.h"
#import "STDSEllipticCurvePoint.h"
#import "STDSJSONWebSignature.h"

@interface STDSJSONWebSignatureTests : XCTestCase

@end

@implementation STDSJSONWebSignatureTests

- (void)testInitES256 {

    // generated a private ec key and certificate, plugged into jwt.io with default sample payload.
    // This certificate will expire in 2030 but as this test doesn't cover certificate validity
    // it shouldn't start failing
    STDSJSONWebSignature *jws = [[STDSJSONWebSignature alloc] initWithString:@"eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsIng1YyI6WyJNSUh3TUlHV0Fna0ErdEM1LzJxV1RqRXdDZ1lJS29aSXpqMEVBd0l3QURBZUZ3MHlNVEF4TURReU1UQTBNamxhRncwek1UQXhNREl5TVRBME1qbGFNQUF3V1RBVEJnY3Foa2pPUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVFSV3oram42NUJ0T012ZHlIS2N2akJlQlNEWkgycjFSVHdqbVlTaTlSL3pwQm51UTRFaU1uQ3FmTVBXaVpxQjRRZGJBZDBFN29INTBWcHVaMVAwODdHTUFvR0NDcUdTTTQ5QkFNQ0Ewa0FNRVlDSVFETTVRbHRDTFhEeEpvTG1EVXRqREgxZEJQVHBUVG1jS2pjOHlodVp1VHU2UUloQVBEU0cvN3plV09NdkhxNUpaWk8zd3JQeVBhTFlVNHBCcGpWTS95YzQ5MDciXX0.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.71MhQ7FJavv1nQ7Boujfp7K0iBEYFGSGLZ3osnL9KAY9scF95Hf7ZMQ8I1JSgnGl227UY96is80MlbTijOOxsg"];

    XCTAssertNotNil(jws, @"Failed to create jws object");

    XCTAssertEqual(jws.algorithm, STDSJSONWebSignatureAlgorithmES256, @"Parsed incorrect algorithm");

    NSData *digest = [@"eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsIng1YyI6WyJNSUh3TUlHV0Fna0ErdEM1LzJxV1RqRXdDZ1lJS29aSXpqMEVBd0l3QURBZUZ3MHlNVEF4TURReU1UQTBNamxhRncwek1UQXhNREl5TVRBME1qbGFNQUF3V1RBVEJnY3Foa2pPUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVFSV3oram42NUJ0T012ZHlIS2N2akJlQlNEWkgycjFSVHdqbVlTaTlSL3pwQm51UTRFaU1uQ3FmTVBXaVpxQjRRZGJBZDBFN29INTBWcHVaMVAwODdHTUFvR0NDcUdTTTQ5QkFNQ0Ewa0FNRVlDSVFETTVRbHRDTFhEeEpvTG1EVXRqREgxZEJQVHBUVG1jS2pjOHlodVp1VHU2UUloQVBEU0cvN3plV09NdkhxNUpaWk8zd3JQeVBhTFlVNHBCcGpWTS95YzQ5MDciXX0.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(jws.digest, digest, @"Parsed payload incorrectly.");
    NSData *signature = [@"71MhQ7FJavv1nQ7Boujfp7K0iBEYFGSGLZ3osnL9KAY9scF95Hf7ZMQ8I1JSgnGl227UY96is80MlbTijOOxsg" _stds_base64URLDecodedData];
    XCTAssertEqualObjects(jws.signature, signature, @"Parsed signature incorrectly.");
    NSData *payload = [@"eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0" _stds_base64URLDecodedData];
    XCTAssertEqualObjects(jws.payload, payload, @"Parsed payload incorrectly.");

    XCTAssertNotNil(jws.ellipticCurvePoint, @"Failed to parse elliptic curve point.");
    XCTAssertNotNil(jws.certificateChain, @"Must have certificate chain.");

    const unsigned char keyBytes[] = {0x11, 0x5b, 0x3f, 0xa3, 0x9f, 0xae, 0x41, 0xb4, 0xe3, 0x2f, 0x77, 0x21, 0xca, 0x72,
        0xf8, 0xc1, 0x78, 0x14, 0x83, 0x64, 0x7d, 0xab, 0xd5, 0x14, 0xf0, 0x8e, 0x66, 0x12, 0x8b,
        0xd4, 0x7f, 0xce, 0x90, 0x67, 0xb9, 0x0e, 0x04, 0x88, 0xc9, 0xc2, 0xa9, 0xf3, 0x0f, 0x5a,
        0x26, 0x6a, 0x07, 0x84, 0x1d, 0x6c, 0x07, 0x74, 0x13, 0xba, 0x07, 0xe7, 0x45, 0x69, 0xb9,
        0x9d, 0x4f, 0xd3, 0xce, 0xc6};
    size_t keyLength = sizeof(keyBytes)/2;
    NSData *coordinateX = [NSData dataWithBytes:keyBytes length:keyLength];
    NSData *coordinateY = [NSData dataWithBytes:keyBytes + keyLength length:keyLength];

    XCTAssertEqualObjects(jws.ellipticCurvePoint.x, coordinateX, @"Incorrect x-point.");
    XCTAssertEqualObjects(jws.ellipticCurvePoint.y, coordinateY, @"Incorrect y-point.");
}

- (void)testInitPS256 {

    // test jws strings generated from jwt.io
    STDSJSONWebSignature *jws = [[STDSJSONWebSignature alloc] initWithString:@"eyJhbGciOiJQUzI1NiIsIng1YyI6WyJNSUkiLCJNSUkyIl19.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.CDB63_lCSBlmrIfZBvn6w4rDKJgkmKhFe4mfR-xUnfxf9N0g4vZa0R9lFG5pjVkThq9CX-p-vM_64wG4bAC53VlXOk6DhjzN0LTCo1nB81rd8DgqMH4SkLFy3wP-Xe0akRmXE8iHmv63ip7d2LGQVCD38xwXOnoBUVANCrcsC0Iur1TTEXaEfT6ACwg3V1YTu-vygNdbhYZOC_Q9ESbaoPxOQfumXnD44m1EN_FV3d-uQJx1Rn6w3AkDw34P3KunLrwOMJt1mbkWzb66VDVsIxegc4N8TjJTzvxmCk841wUae3kZ97_HPIEfil3ewv80hZstEE2hcEXJbdBfsxsSqg"];

    XCTAssertNotNil(jws, @"Failed to create jws object");

    XCTAssertEqual(jws.algorithm, STDSJSONWebSignatureAlgorithmPS256, @"Parsed incorrect algorithm");

    NSData *digest = [@"eyJhbGciOiJQUzI1NiIsIng1YyI6WyJNSUkiLCJNSUkyIl19.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(jws.digest, digest, @"Parsed payload incorrectly.");
    NSData *signature = [@"CDB63_lCSBlmrIfZBvn6w4rDKJgkmKhFe4mfR-xUnfxf9N0g4vZa0R9lFG5pjVkThq9CX-p-vM_64wG4bAC53VlXOk6DhjzN0LTCo1nB81rd8DgqMH4SkLFy3wP-Xe0akRmXE8iHmv63ip7d2LGQVCD38xwXOnoBUVANCrcsC0Iur1TTEXaEfT6ACwg3V1YTu-vygNdbhYZOC_Q9ESbaoPxOQfumXnD44m1EN_FV3d-uQJx1Rn6w3AkDw34P3KunLrwOMJt1mbkWzb66VDVsIxegc4N8TjJTzvxmCk841wUae3kZ97_HPIEfil3ewv80hZstEE2hcEXJbdBfsxsSqg" _stds_base64URLDecodedData];
    XCTAssertEqualObjects(jws.signature, signature, @"Parsed signature incorrectly.");
    NSData *payload = [@"eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0" _stds_base64URLDecodedData];
    XCTAssertEqualObjects(jws.payload, payload, @"Parsed payload incorrectly.");

    XCTAssertNil(jws.ellipticCurvePoint, @"Should not create elliptic curve point.");

    NSArray<NSString *> *certChain = @[@"MII", @"MII2"];
    XCTAssertEqualObjects(jws.certificateChain, certChain, @"Failed to parse x5c correctly.");


}
@end
