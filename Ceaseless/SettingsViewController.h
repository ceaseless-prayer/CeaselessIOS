//
//  SettingsViewController.h
//  Ceaseless
//
//  Created by Lori Hill on 3/20/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TaggedPersonPicker.h"

@interface SettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, TaggedPersonPickerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UITextField *placeholderText;
@property (weak, nonatomic) IBOutlet UIButton *profileNameButton;
@property (weak, nonatomic) IBOutlet UITableView *settingsTableView;
@property (strong, nonatomic) NSArray *settingsInfoArray;

@end
