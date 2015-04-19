//
//  SettingsViewController.h
//  Ceaseless
//
//  Created by Lori Hill on 3/20/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TaggedPersonPicker.h"
#import "GAITrackedViewController.h"

@interface SettingsViewController : GAITrackedViewController <UIScrollViewDelegate, TaggedPersonPickerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UITextField *placeholderText;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *selectMeButton;

@property (weak, nonatomic) IBOutlet UIView *prayForCell;
@property (weak, nonatomic) IBOutlet UILabel *peopleCount;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;

@property (weak, nonatomic) IBOutlet UIView *notificationsSelectorCell;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

- (IBAction)stepperChanged:(id)sender;

@end
