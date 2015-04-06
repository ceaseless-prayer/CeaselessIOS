//
//  SettingsViewController.m
//  Ceaseless
//
//  Created by Lori Hill on 3/20/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "SettingsViewController.h"
#import "TaggedPersonPicker.h"
#import "CeaselessLocalContacts.h"
#import "PersonIdentifier.h"
#import "PersonInfo.h"
#import "PersonPicker.h"
#import "AppConstants.h"

@interface SettingsViewController ()

@property (nonatomic, strong) CeaselessLocalContacts *ceaselessContacts;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	self.scrollView.delegate = self;
    self.ceaselessContacts = [CeaselessLocalContacts sharedCeaselessLocalContacts];

	if ([[NSUserDefaults standardUserDefaults] stringForKey: @"CeaselessId"]) {
			//get the image and name from the Person
		PersonIdentifier *person = [_ceaselessContacts getCeaselessContactFromCeaselessId:[[NSUserDefaults standardUserDefaults] stringForKey: @"CeaselessId"]];
		[self formatProfileForPerson: person];
	} else {
		self.placeholderText.hidden = NO;
		self.nameLabel.hidden = YES;
		self.profileImage.hidden = YES;
		self.selectMeButton.hidden = NO;
		self.profileImage.contentMode = UIViewContentModeScaleAspectFill;
		self.placeholderText.layer.cornerRadius = 6.0f;
	}

	if ([[NSUserDefaults standardUserDefaults] doubleForKey:kDailyPersonCount]) {
		self.peopleCount.text = [NSString stringWithFormat:@"%.f",[[NSUserDefaults standardUserDefaults] doubleForKey:kDailyPersonCount]];
		self.stepper.value = [[NSUserDefaults standardUserDefaults] doubleForKey:kDailyPersonCount];
	} else {
		self.peopleCount.text = @"3";
		self.stepper.value = 3;
	}
	NSLog (@"stepper is %@", self.peopleCount.text);

	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"NotificationDate"]) {
		[self.datePicker setDate: [[NSUserDefaults standardUserDefaults] objectForKey:@"NotificationDate"] animated: NO];
	}

		//Set Color of Date Picker
	self.datePicker.datePickerMode = UIDatePickerModeTime;
	[self.datePicker setValue:[UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0f] forKeyPath:@"textColor"];
	SEL selector = NSSelectorFromString(@"setHighlightsToday:");
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDatePicker instanceMethodSignatureForSelector:selector]];
	BOOL no = NO;
	[invocation setSelector:selector];
	[invocation setArgument:&no atIndex:2];
	[invocation invokeWithTarget:self.datePicker];

	self.prayForCell.layer.cornerRadius = 6.0f;
	self.notificationsSelectorCell.layer.cornerRadius = 6.0f;

	NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
																	  attribute:NSLayoutAttributeLeading
																	  relatedBy:0
																		 toItem:self.view
																	  attribute:NSLayoutAttributeLeft
																	 multiplier:1.0
																	   constant:0];
	[self.view addConstraint:leftConstraint];

	NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
																	   attribute:NSLayoutAttributeTrailing
																	   relatedBy:0
																		  toItem:self.view
																	   attribute:NSLayoutAttributeRight
																	  multiplier:1.0
																		constant:0];
	[self.view addConstraint:rightConstraint];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
			// back button code
		[[NSUserDefaults standardUserDefaults] setObject:[self.datePicker date] forKey:@"NotificationDate"];
	}
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - View lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
		// Check the segue identifier
	if ([[segue identifier] isEqualToString:@"ShowSelectContact"]) {
		UINavigationController *navController = segue.destinationViewController;
		TaggedPersonPicker *picker = (TaggedPersonPicker *)navController.topViewController;
		picker.title = @"Select yourself";
		picker.maxCount = 1;
		picker.delegate = self;
	}
}

#pragma mark - TaggedPersonPickerDelegate protocol conformance

- (void)taggedPersonPickerDidFinish:(TaggedPersonPicker *)taggedPersonPicker
					withABRecordIDs:(NSOrderedSet *)abRecordIDs {

	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);


	NSNumber *number = [abRecordIDs firstObject];
	ABRecordID abRecordID = [number intValue];

	ABRecordRef abPerson = ABAddressBookGetPersonWithRecordID(addressBook, abRecordID);


	[_ceaselessContacts updateCeaselessContactFromABRecord: abPerson];
	PersonIdentifier *person = [_ceaselessContacts getCeaselessContactFromABRecord: abPerson];

	CFRelease(addressBook);

	[self formatProfileForPerson: person];

	[[NSUserDefaults standardUserDefaults] setObject: person.ceaselessId forKey: @"CeaselessId"];

	[taggedPersonPicker dismissViewControllerAnimated:YES completion:NULL];

}

- (void) formatProfileForPerson: (PersonIdentifier *) person {
    UIImage *personImage = [_ceaselessContacts getImageForPersonIdentifier:person];
    self.profileImage.image = personImage;
    self.profileImage.contentMode = UIViewContentModeScaleAspectFit;
    self.profileImage.layer.cornerRadius = 6.0f;
    [self.profileImage setClipsToBounds:YES];
    
    self.backgroundImageView.image = self.profileImage.image;
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    NSString *fullName = [_ceaselessContacts compositeNameForPerson:person];
    if (fullName) {
        self.nameLabel.text = fullName;
        self.nameLabel.hidden = NO;
        self.selectMeButton.hidden = YES;
    }
    
    if (self.profileImage.image) {
        self.placeholderText.hidden = YES;
        self.profileImage.hidden = NO;
    } else {
        self.placeholderText.hidden = NO;
        self.profileImage.hidden = YES;
        self.profileImage.contentMode = UIViewContentModeScaleAspectFill;
        self.placeholderText.layer.cornerRadius = 6.0f;
    }
}

- (void)taggedPersonPickerDidCancel:(TaggedPersonPicker *)taggedPersonPicker {
	[taggedPersonPicker dismissViewControllerAnimated:YES completion:NULL];

}

- (IBAction)stepperChanged:(UIStepper*)sender {
	
	double value = [sender value];

	[self.peopleCount setText:[NSString stringWithFormat:@"%d", (int)value]];
	[[NSUserDefaults standardUserDefaults] setDouble: value forKey:kDailyPersonCount];


	NSLog (@"what is saved in dailyPersonCount %li", (long)[[NSUserDefaults standardUserDefaults] integerForKey:kDailyPersonCount]);
}

@end
