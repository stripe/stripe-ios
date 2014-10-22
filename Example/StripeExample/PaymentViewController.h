//
//  PaymentViewController.h
//  Stripe
//
//  Created by Alex MacCaw on 3/4/13.
//
//

#import <UIKit/UIKit.h>

@interface PaymentViewController : UIViewController

@property (nonatomic) NSDecimalNumber *amount;
- (IBAction)save:(id)sender;

@end
