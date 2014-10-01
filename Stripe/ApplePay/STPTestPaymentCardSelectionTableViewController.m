//
//  STPTestPaymentCardSelectionTableViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 9/30/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "STPTestPaymentCardSelectionTableViewController.h"
#import "STPTestCardStore.h"
#import "STPCard.h"

@interface STPTestPaymentCardSelectionTableViewController ()
@property(nonatomic)STPTestCardStore *store;
@end

@implementation STPTestPaymentCardSelectionTableViewController

- (instancetype)initWithCardStore:(STPTestCardStore *)store {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _store = store;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.store.allCards.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"
                                                            forIndexPath:indexPath];
    
    STPCard *card = self.store.allCards[indexPath.row];
    cell.textLabel.text = card.name;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.store.selectedCard = self.store.allCards[indexPath.row];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
