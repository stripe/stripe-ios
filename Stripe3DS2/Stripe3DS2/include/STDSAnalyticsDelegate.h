//
//  STDSAnalyticsDelegate.h
//  Stripe3DS2
//
//  Created by Kenneth Ackerson on 8/21/24.
//

NS_ASSUME_NONNULL_BEGIN

@protocol STDSAnalyticsDelegate <NSObject>

- (void)didReceiveChallengeResponseWithTransactionID:(NSString *)transactionID flow:(NSString *)type;

- (void)cancelButtonTappedWithTransactionID:(NSString *)transactionID;

- (void)OTPSubmitButtonTappedWithTransactionID:(NSString *)transactionID;

- (void)OOBContinueButtonTappedWithTransactionID:(NSString *)transactionID;

- (void)OOBDidEnterBackground:(NSString *)transactionID;
- (void)OOBWillEnterForeground:(NSString *)transactionID;

@end

NS_ASSUME_NONNULL_END
