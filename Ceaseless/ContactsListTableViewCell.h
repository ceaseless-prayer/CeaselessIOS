//
//  ContactsListTableViewCell.h
//  Ceaseless
//
//  Created by Lori Hill on 3/24/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactsListTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *personImageView;
@property (weak, nonatomic) IBOutlet UILabel *placeholderLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameLabelTrailingConstraint;
@property (weak, nonatomic) IBOutlet UISwitch *rowSwitch;
@property (nonatomic,copy) void (^onSwitchChange)(UITableViewCell *cell);

- (IBAction)switchChanged:(id)sender;

@end
