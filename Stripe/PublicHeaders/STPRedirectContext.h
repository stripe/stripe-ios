//
//  STPRedirectContext.h
//  Stripe
//
//  Created by Brian Dorfman on 3/29/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPBlocks.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Possible states for the redirect context to be in
 */
typedef NS_ENUM(NSUInteger, STPRedirectContextState) {
    /**
     Initialized, but redirect not started.
     */
    STPRedirectContextStateNotStarted,

    /**
      Redirect is in progress.
     */
    STPRedirectContextStateInProgress,

    /**
     Redirect has been cancelled programmatically before completing.
     */
    STPRedirectContextStateCancelled,

    /**
     Redirect has completed.
     */
    STPRedirectContextStateCompleted
};

/**
 A callback run when the context believes the redirect action has been completed.

 @param sourceID The stripe id of the source.
 @param clientSecret The client secret of the source.
 @param error An error if one occured. Note that a lack of an error does not 
 mean that the action was completed successfully, the presence of one confirms 
 that it was not. Currently the only possible error the context can know about 
 is if SFSafariViewController fails its initial load (like the user has no 
 internet connection, or servers are down).
 */
typedef void (^STPRedirectContextCompletionBlock)(NSString *sourceID, NSString *clientSecret, NSError *error);

/**
 This is a helper class for handling redirect sources.

 Init an instance with the redirect flow source you want to handle,
 then choose a redirect method. The context will fire the completion handler
 when the redirect completes.

 Due to the nature of iOS, very little concrete information can be gained
 during this process, as all actions take place in either the Safari app
 or the sandboxed SFSafariViewController class. The context attempts to 
 detect when the user has completed the necessary redirect action by listening
 for both app foregrounds and url callbacks received in the app delegate.
 However, it is possible the when the redirect is "completed", the user may
 have not actually completed the necessary actions to authorize the charge.

 You can use `STPAPIClient` to listen for state changes on the source
 object as a way to identify whether the user action succeeded or not.
 @see `[STPAPIClient startPollingSourceWithId:clientSecret:timeout:completion:]`

 You should not use either this class, nor `STPAPIClient`, as a way
 to determine when you should charge the source. Use Stripe webhooks on your
 backend server to listen for source state changes and to make the charge.
 */
NS_EXTENSION_UNAVAILABLE("Redirect based sources are not available in extensions")
@interface STPRedirectContext : NSObject

/**
 The current state of the context.
 */
@property (nonatomic, readonly) STPRedirectContextState state;

/**
 Initializer for context.

 @note You must ensure that the returnURL set up in the created source
 correctly goes to your app so that users can be returned once
 they complete the redirect in the web broswer.

 @param source The source that needs user redirect action to be taken.
 @param completion A block to fire when the action is believed to have 
 been completed.

 @return Nil if the specified source is not a redirect-flow source. Otherwise 
 a new context object.

 @note Firing of the completion block does not necessarily mean the user 
 successfully performed the redirect action. You should listen for source status
 change webhooks on your backend to determine the result of a redirect.
 */
- (nullable instancetype)initWithSource:(STPSource *)source
                             completion:(STPRedirectContextCompletionBlock)completion;

/**
 Use `initWithSource:completion:`
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 Starts a redirect flow.

 You must ensure that your app delegate listens for  the `returnURL` that you
 set on your source object, and forwards it to the Stripe SDK so that the
 context can be notified when the redirect is completed and dismiss the
 view controller. See `[Stripe handleStripeURLCallbackWithURL:]`

 The context will listen for both received URLs and app open notifications
 and fire its completion block when either the URL is received, or the next
 time the app is foregrounded.

 If the app is running on iOS 9+ it will initiate the flow by presenting
 a SFSafariViewController instance from the pass in view controller.
 Otherwise, if the app is running on iOS 8 it will initiate the flow by
 bouncing the user out to the Safari app. If you want more manual control 
 over the redirect method, you can use 
 `startSafariViewControllerRedirectFlowFromViewController` 
 or `startSafariAppRedirectFlow`
 
 If the source supports a native app, and that app is is installed on the user's
 device, this call will do a direct app-to-app redirect instead of showing
 a web url. 

 @note This method does nothing if the context is not in the 
 `STPRedirectContextStateNotStarted` state.

 @param presentingViewController The view controller to present the Safari
 view controller from.
 */
- (void)startRedirectFlowFromViewController:(UIViewController *)presentingViewController;

/**
 Starts a redirect flow by presenting an SFSafariViewController in your app
 from the passed in view controller.

 You must ensure that your app delegate listens for  the `returnURL` that you
 set on your source object, and forwards it to the Stripe SDK so that the
 context can be notified when the redirect is completed and dismiss the
 view controller. See `[Stripe handleStripeURLCallbackWithURL:]`

 The context will listen for both received URLs and app open notifications 
 and fire its completion block when either the URL is received, or the next
 time the app is foregrounded.

 @note This method does nothing if the context is not in the 
 `STPRedirectContextStateNotStarted` state.

 @param presentingViewController The view controller to present the Safari 
 view controller from.
 */
- (void)startSafariViewControllerRedirectFlowFromViewController:(UIViewController *)presentingViewController NS_AVAILABLE_IOS(9_0);

/**
 Starts a redirect flow by calling `openURL` to bounce the user out to
 the Safari app.

 The context will listen for app open notifications and fire its completion
 block the next time the user re-opens the app (either manually or via url)

 @note This method does nothing if the context is not in the 
  `STPRedirectContextStateNotStarted` state.
 */
- (void)startSafariAppRedirectFlow;

/**
 Dismisses any presented views and stops listening for any
 app opens or callbacks. The completion block will not be fired.
 */
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
