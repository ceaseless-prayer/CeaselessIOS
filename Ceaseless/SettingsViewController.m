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
@property (nonatomic, strong) NonMOPerson *nonMOPerson;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	self.settingsTableView.delegate = self;
	self.settingsTableView.dataSource = self;
	self.personPicker = [[PersonPicker alloc] init];
	self.nonMOPerson = [[NonMOPerson alloc] init];

	if ([[NSUserDefaults standardUserDefaults] stringForKey: @"CeaselessId"]) {
			//get the image and name from the Person
		[self formatProfileForPerson: self.nonMOPerson];
	} else {
		self.placeholderText.hidden = NO;
		self.profileImage.hidden = YES;
		self.profileNameButton.enabled = YES;
	}

	self.profileImage.layer.cornerRadius = 6.0f;
	[self.profileImage setClipsToBounds:YES];
	self.profileImage.contentMode = UIViewContentModeScaleAspectFill;
	self.placeholderText.layer.cornerRadius = 6.0f;

	self.settingsInfoArray = [[NSArray alloc] initWithObjects: @"Pray For Daily", @"Notification time", nil];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.settingsInfoArray count];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	cell.textLabel.text = [self.settingsInfoArray objectAtIndex: indexPath.row];

}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
		// Return NO if you do not want the specified item to be editable.
	return NO;
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

//	NSString *name = (__bridge_transfer NSString *)ABRecordCopyCompositeName(abPerson);

	CFRelease(addressBook);

//	self.nonMOPerson = newMethod;
	[self formatProfileForPerson: person];

	[[NSUserDefaults standardUserDefaults] setObject: person.ceaselessId forKey: @"CeaselessId"];

	[taggedPersonPicker dismissViewControllerAnimated:YES completion:NULL];

}

- (void) formatProfileForPerson: (NonMOPerson *) person  {

	self.profileImage.image = person.profileImage;
	self.profileImage.contentMode = UIViewContentModeScaleAspectFit;
	self.backgroundImage.image = self.profileImage.image;
	self.backgroundImage.contentMode = UIViewContentModeScaleAspectFill;

	NSString *fullName = [NSString stringWithFormat: @"%@ %@", person.firstName, person.lastName];
	if (fullName) {
		[self.profileNameButton setTitle: fullName forState:UIControlStateNormal];
		self.profileNameButton.enabled = NO;
	}

	if (self.profileImage.image) {
		self.placeholderText.hidden = YES;
		self.profileImage.hidden = NO;
	} else {
		self.placeholderText.hidden = NO;
		self.profileImage.hidden = YES;
	}
}


- (void)taggedPersonPickerDidCancel:(TaggedPersonPicker *)taggedPersonPicker {
	[taggedPersonPicker dismissViewControllerAnimated:YES completion:NULL];

}
@end
