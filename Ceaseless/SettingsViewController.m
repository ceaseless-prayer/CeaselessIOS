//
//  SettingsViewController.m
//  Ceaseless
//
//  Created by Lori Hill on 3/20/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "SettingsViewController.h"
#import "TaggedPersonPicker.h"
#import "PersonPicker.h"
#import "NonMOPerson.h"
#import "Person.h"
#import "PersonPicker.h"

@interface SettingsViewController ()

@property (nonatomic, strong) PersonPicker *personPicker;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	self.scrollView.delegate = self;
	self.personPicker = [[PersonPicker alloc] init];

	if ([[NSUserDefaults standardUserDefaults] stringForKey: @"CeaselessId"]) {
			//get the image and name from the Person
		Person *person = [self.personPicker getCeaselessContactFromCeaselessId:[[NSUserDefaults standardUserDefaults] stringForKey: @"CeaselessId"]];
		NonMOPerson *nonMOPerson = [self.personPicker getNonMOPersonForCeaselessContact: person];
		[self formatProfileForPerson: nonMOPerson];
	} else {
		self.placeholderText.hidden = NO;
		self.nameLabel.hidden = YES;
		self.profileImage.hidden = YES;
		self.selectMeButton.hidden = NO;
		self.profileImage.contentMode = UIViewContentModeScaleAspectFill;
		self.placeholderText.layer.cornerRadius = 6.0f;
	}

	if ([[NSUserDefaults standardUserDefaults] doubleForKey:@"DailyPersonCount"]) {
		self.peopleCount.text = [NSString stringWithFormat:@"%.f",[[NSUserDefaults standardUserDefaults] doubleForKey:@"DailyPersonCount"]];
		self.stepper.value = [[NSUserDefaults standardUserDefaults] doubleForKey:@"DailyPersonCount"];
	} else {
		self.peopleCount.text = @"3";
		self.stepper.value = 3;
	}
	NSLog (@"stepper is %@", self.peopleCount.text);

		//Set Color of Date Picker
	self.datePicker.datePickerMode = UIDatePickerModeTime;
	[self.datePicker setValue:[UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0f] forKeyPath:@"textColor"];
	SEL selector = NSSelectorFromString(@"setHighlightsToday:");
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDatePicker instanceMethodSignatureForSelector:selector]];
	BOOL no = NO;
	[invocation setSelector:selector];
	[invocation setArgument:&no atIndex:2];
	[invocation invokeWithTarget:self.datePicker];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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


	[self.personPicker updateCeaselessContactFromABRecord: abPerson];
	Person *person = [self.personPicker getCeaselessContactFromABRecord: abPerson];

	CFRelease(addressBook);

	NonMOPerson *nonMOPerson = [self.personPicker getNonMOPersonForCeaselessContact: person];
	[self formatProfileForPerson: nonMOPerson];

	[[NSUserDefaults standardUserDefaults] setObject: person.ceaselessId forKey: @"CeaselessId"];

	[taggedPersonPicker dismissViewControllerAnimated:YES completion:NULL];

}

- (void) formatProfileForPerson: (NonMOPerson *) person  {

	self.profileImage.image = person.profileImage;
	self.profileImage.contentMode = UIViewContentModeScaleAspectFit;
	self.profileImage.layer.cornerRadius = 6.0f;
	[self.profileImage setClipsToBounds:YES];

	self.backgroundImage.image = self.profileImage.image;
	self.backgroundImage.contentMode = UIViewContentModeScaleAspectFill;

	NSString *fullName = [NSString stringWithFormat: @"%@ %@", person.firstName, person.lastName];
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
	[[NSUserDefaults standardUserDefaults] setDouble: value forKey:@"DailyPersonCount"];


	NSLog (@"what is saved in dailyPersonCount %li", (long)[[NSUserDefaults standardUserDefaults] integerForKey:@"DailyPersonCount"]);
}
-(void)getSelection:(id)sender
{

	NSDateFormatter *timeFormatter = [[NSDateFormatter alloc]init];
	timeFormatter.dateFormat = @"HH:mm";

	NSString *timeString = [timeFormatter stringFromDate: [self.datePicker date]];
	NSLog (@"timeString is %@", timeString);
}
@end
