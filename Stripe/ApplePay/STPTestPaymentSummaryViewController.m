//
//  STPTestPaymentSummaryViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 9/8/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 && defined(STRIPE_ENABLE_APPLEPAY)

#import "STPTestPaymentSummaryViewController.h"
#import "STPTestPaymentCardSelectionTableViewController.h"
#import "PKPayment+STPTestKeys.h"
#import "STPTestCardStore.h"
#import "STPCard.h"

NSString * const STPTestPaymentAuthorizationSummaryItemIdentifier = @"STPTestPaymentAuthorizationSummaryItemIdentifier";

@interface STPTestPaymentSummaryItemCell : UITableViewCell
@end

@interface STPTestPaymentSummaryViewController()<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *payButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) PKPaymentRequest *paymentRequest;
@property (nonatomic) STPTestCardStore *store;
@end

@implementation STPTestPaymentSummaryViewController

- (instancetype)initWithPaymentRequest:(PKPaymentRequest *)paymentRequest {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        _paymentRequest = paymentRequest;
        _store = [STPTestCardStore new];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[STPTestPaymentSummaryItemCell class] forCellReuseIdentifier:STPTestPaymentAuthorizationSummaryItemIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (IBAction)makePayment:(id)sender {
    self.payButton.hidden = YES;
    [self.activityIndicator startAnimating];
    
    PKPayment *payment = [PKPayment new];
    payment.stp_testCardNumber = self.store.selectedCard.number;

    PKPaymentAuthorizationViewController *auth = (PKPaymentAuthorizationViewController *)self;

    [self.activityIndicator startAnimating];
    [self.delegate paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)auth
                                  didAuthorizePayment:payment
                                           completion:^(PKPaymentAuthorizationStatus status) {
                                               [self.activityIndicator stopAnimating];
                                               [self.delegate paymentAuthorizationViewControllerDidFinish:auth];
                                           }];
}

- (void)cancel:(id)sender {
    [self.delegate paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)self];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Cards";
    }
    return @"Payment";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    return self.paymentRequest.paymentSummaryItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:STPTestPaymentAuthorizationSummaryItemIdentifier forIndexPath:indexPath];
    [self configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            STPCard *card = self.store.selectedCard;
            cell.textLabel.text = [card.name uppercaseString];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"**** **** **** %@", card.last4];
        }
        return;
    }
    PKPaymentSummaryItem *item = self.paymentRequest.paymentSummaryItems[indexPath.row];
    cell.textLabel.text = [item.label uppercaseString];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", item.amount.stringValue, self.paymentRequest.currencyCode];
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            STPTestPaymentCardSelectionTableViewController *controller = [[STPTestPaymentCardSelectionTableViewController alloc] initWithCardStore:self.store];
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
}

@end

@implementation STPTestPaymentSummaryItemCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
}

@end


#endif
