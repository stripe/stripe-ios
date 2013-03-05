//
//  SettingsViewController.h
//  Stripe
//
//  Created by Alex MacCaw on 3/4/13.
//
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableViewCell *paymentCell;

@end
