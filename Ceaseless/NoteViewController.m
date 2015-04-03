//
//  NoteViewController.m
//  Ceaseless
//
//  Created by Lori Hill on 3/12/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//
#import "NoteViewController.h"
#import <AddressBook/AddressBook.h>
#import "AppDelegate.h"
#import "PersonIdentifier.h"
#import "PersonInfo.h"
#import "PersonPicker.h"
#import "CeaselessLocalContacts.h"
#import "Name.h"
#import "AppUtils.h"

@interface NoteViewController ()

@property (nonatomic, strong) NSMutableArray *namesArray;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) UINavigationItem *item;
@property (strong, nonatomic) NSMutableOrderedSet *mutablePeopleSet;
@property (nonatomic, strong) NSOrderedSet *abRecordIDs;
@property (strong, nonatomic) UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, strong) UIButton *selectedButton;
@property (nonatomic, strong) NSMutableOrderedSet *group;
@property (nonatomic, strong) NSArray *people;
@property (nonatomic, strong) NSMutableArray *filteredPeople;
@property (nonatomic, strong) UISearchBar *searchField;
@property (nonatomic, strong) UIColor *appColor;

@end

@implementation NoteViewController

static CGFloat const kPadding = 5.0;

NSString *const kPlaceHolderText = @"Enter note";

- (void)viewDidLoad {
	[super viewDidLoad];

	UIImage *backgroundImage = [AppUtils getDynamicBackgroundImage];
	if(backgroundImage != nil) {
		self.backgroundImageView.image = backgroundImage;
	}
	
	if (!self.tokenColor) {
		self.tokenColor = self.view.tintColor;
		self.tokenColor = [UIColor lightGrayColor];
	}

	if (!self.selectedTokenColor) {
		self.selectedTokenColor = [UIColor darkGrayColor];
	}

	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;

	if (self.addressBook == NULL) {
		self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
	}
		// Check whether we are authorized to access the user's address book data
	[self checkAddressBookAccess];

	self.namesArray = [NSMutableArray arrayWithCapacity: 1];
	self.mutablePeopleSet = [[NSMutableOrderedSet alloc] initWithCapacity: 1];

	self.notesTextView.delegate = self;
	self.contactsTableView.delegate = self;
	self.appColor = UIColorFromRGBWithAlpha(0x24292f , 0.4);


		//Add a searchBar, it will get positioned in the scrollview just past the last name
	self.searchField  = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
	self.searchField.searchBarStyle = UISearchBarStyleMinimal;
	[self.searchField setImage: [UIImage imageNamed: @"noImage"] forSearchBarIcon: UISearchBarIconSearch state:UIControlStateNormal];
	[[UISearchBar appearance] setPositionAdjustment:UIOffsetMake(-15, 0) forSearchBarIcon:UISearchBarIconSearch];


	self.searchField.delegate = self;
	self.searchField.backgroundColor = self.tokenColor;
	self.searchField.barTintColor = self.tokenColor;
	self.searchField.tintColor = [UIColor whiteColor];
	[self.searchField.layer setCornerRadius:4.0];


		// Add a tap gesture recognizer to our scrollView
	self.singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewTapped:)];
	self.singleTapGestureRecognizer.numberOfTapsRequired = 1;
	self.singleTapGestureRecognizer.enabled = YES;
	self.singleTapGestureRecognizer.cancelsTouchesInView = YES;
	self.singleTapGestureRecognizer.delegate = self;
	[self.personsTaggedView addGestureRecognizer:self.singleTapGestureRecognizer];

		//create navigation bar if there is no navigation controller
	if (!self.navigationController) {
		UINavigationBar *navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
		navBar.barTintColor = self.appColor;

		NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
												   [UIColor whiteColor], NSForegroundColorAttributeName,
												   [UIFont fontWithName:@"AvenirNext-Medium" size:16.0f],NSFontAttributeName,
												   nil];
		navBar.titleTextAttributes = navbarTitleTextAttributes;
		self.verticalSpaceTopToView.constant = 44;

		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelClick:)];

		self.item = [[UINavigationItem alloc] initWithTitle:@"Notes"];
		self.item.leftBarButtonItem = cancelButton;
		[navBar pushNavigationItem:self.item animated:NO];

		[self.view addSubview:navBar];

	}

	UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];

	if (!self.navigationController) {
		self.item.rightBarButtonItem = saveButton;
	} else {
		self.navigationItem.rightBarButtonItem = saveButton;
	}
//	[self listAll];

		//initialize
	self.group = [NSMutableOrderedSet orderedSet];
	NSOrderedSet *peopleTagged = [[NSOrderedSet alloc] init];


		//if there is a curent note display it
	if (self.currentNote) {

			//use the date for the title of the screen
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.timeStyle = NSDateFormatterNoStyle;
		dateFormatter.dateStyle = NSDateFormatterShortStyle;
		NSDate *date = [self.currentNote valueForKey: @"createDate"];

		if (!self.navigationController) {
			self.item.title = [dateFormatter stringFromDate:date];

		} else {
			self.navigationItem.title = [dateFormatter stringFromDate:date];
		}

		self.notesTextView.text = [self.currentNote valueForKey: @"text"];
		peopleTagged = [self.currentNote valueForKey: @"peopleTagged"];

	} else {
			//no note passed in, so add a new note

			//screen title is Add Note
		if (!self.navigationController) {
			self.item.title = @"Add Note";
		} else {
			self.navigationItem.title = @"Add Note";
		}

		if (self.personForNewNote) {
			peopleTagged = [[NSOrderedSet alloc] initWithObjects: self.personForNewNote, nil];

		}
		self.notesTextView.text = kPlaceHolderText;
		self.notesTextView.textColor = [UIColor lightGrayColor];

	}

	for (PersonIdentifier *personTagged in peopleTagged) {
        PersonInfo *info = personTagged.representativeInfo;
		ABRecordID abRecordID = [info.primaryAddressBookId.recordId intValue];
		NSNumber *number = [NSNumber numberWithInt:abRecordID];
		[self.group addObject:number];
	}
    
	self.abRecordIDs = [NSOrderedSet orderedSetWithOrderedSet: self.group];
	if (self.abRecordIDs.count > 0) {
		self.tagFriendsPlaceholderText.hidden = YES;
		[self updatePersonInfo:self.abRecordIDs];

	} else  {
		self.tagFriendsPlaceholderText.hidden = NO;
	}
	[self layoutScrollView: self.personsTaggedView forGroup: self.abRecordIDs];
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Respond to touch and become first responder.

- (BOOL)canBecomeFirstResponder
{
	return YES;
}
#pragma mark - Address Book access

	// Check the authorization status of our application for Address Book
- (void)checkAddressBookAccess
{
	switch (ABAddressBookGetAuthorizationStatus())
	{
			// Update our UI if the user has granted access to their Contacts
		case kABAuthorizationStatusAuthorized:
		[self accessGrantedForAddressBook];
		break;
			// Prompt the user for access to Contacts if there is no definitive answer
		case kABAuthorizationStatusNotDetermined :
		[self requestAddressBookAccess];
		break;
			// Display a message if the user has denied or restricted access to Contacts
		case kABAuthorizationStatusDenied:
		case kABAuthorizationStatusRestricted:
		{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Privacy Warning", @"Privacy Warning")
														message:NSLocalizedString(@"Permission was not granted for Contacts.", @"Permission was not granted for Contacts.")
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
											  otherButtonTitles:nil];
		[alert show];
		}
		break;
		default:
		break;
	}
}

	// Prompt the user for access to their Address Book data
- (void)requestAddressBookAccess
{
	NoteViewController* __weak weakSelf = self;

	ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error)
											 {
											 if (granted)
												 {
												 dispatch_async(dispatch_get_main_queue(), ^{
													 [weakSelf accessGrantedForAddressBook];

												 });
												 }
											 });
}

	// This method is called when the user has granted access to their address book data.
- (void)accessGrantedForAddressBook
{
	_people = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(self.addressBook);

	self.group = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.abRecordIDs];

		// Create a filtered list that will contain people for the search results table.
	self.filteredPeople = [NSMutableArray array];
}
#pragma mark - Update Person info
- (void) layoutScrollView: (UIScrollView *) scrollView forGroup: (NSOrderedSet *) abRecordIDs
{
		// Remove existing buttons
	for (UIView *subview in scrollView.subviews)
		{
		if ([subview isKindOfClass:[UIButton class]])
			{
			[subview removeFromSuperview];
			}
		}

	CGFloat maxWidth = [[UIScreen mainScreen] bounds].size.width - 16 - kPadding;
	CGFloat xPosition = kPadding;
	CGFloat yPosition = kPadding;

	for (NSNumber *number in abRecordIDs) {
		ABRecordID abRecordID = [number intValue];
		ABRecordRef abPerson = ABAddressBookGetPersonWithRecordID(self.addressBook, abRecordID);

			// Copy the name associated with this person record
		NSString *name = (__bridge_transfer NSString *)ABRecordCopyCompositeName(abPerson);

		UIFont *font = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0f];

			// Create the button
		UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
		[button setTitle:name forState:UIControlStateNormal];
		[button.titleLabel setFont:font];
		[button setBackgroundColor:self.tokenColor];
		[button.layer setCornerRadius:4.0];
		[button setTag:abRecordID];
		[button addTarget:self action:@selector(buttonSelected:) forControlEvents:UIControlEventTouchUpInside];

			// Get the width and height of the name string given a font size
		CGSize nameSize = [name sizeWithAttributes:@{NSFontAttributeName:font}];

		if ((xPosition + nameSize.width + kPadding) > maxWidth) {
				// Reset horizontal position to left edge of superview's frame
			xPosition = kPadding;

				// Set vertical position to a new 'line'
			yPosition += nameSize.height + kPadding;
		}

			// Create the button's frame
		CGRect buttonFrame = CGRectMake(xPosition, yPosition, nameSize.width + (kPadding * 2), nameSize.height);
		[button setFrame:buttonFrame];

			// Add the button to its superview
		[scrollView addSubview:button];

			// Calculate xPosition for the next button in the loop
		xPosition += button.frame.size.width + kPadding;
	}

	UIFont *font = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0f];

		// Create the textfield at the end of the buttons

		// Get the width and height of the name string given a font size
	NSString *placeholderName = @"Average Size";
	CGSize nameSize = [placeholderName sizeWithAttributes:@{NSFontAttributeName:font}];

	if ((xPosition + nameSize.width + kPadding) > maxWidth)
		{
			// Reset horizontal position to left edge of superview's frame
		xPosition = kPadding;

			// Set vertical position to a new 'line'
		yPosition += nameSize.height + kPadding;
		}

		// Create the button's frame
	CGRect searchFieldFrame = CGRectMake(xPosition, yPosition, nameSize.width + (kPadding * 2), nameSize.height);
	self.searchField.frame = searchFieldFrame;
	self.searchField.hidden = YES;


		// Add the button to its superview
	[scrollView addSubview:self.searchField];

		// Set the content size so it can be scrollable
	CGFloat height = yPosition + 30.0;
	[scrollView setContentSize:CGSizeMake([[UIScreen mainScreen] bounds].size.width - 16, height)];

}

#pragma mark - TextView methods


- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
	if ([[textView text] isEqualToString:kPlaceHolderText]) {
		textView.text = @"";
		textView.textColor = [UIColor whiteColor];
	}

	return YES;
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	if ([[textView text] length] == 0) {
		textView.text = kPlaceHolderText;
		textView.textColor = [UIColor lightGrayColor];
	}
	return YES;
}
#pragma mark - UIGestureRecognizer delegate protocol conformance

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	BOOL shouldReceiveTouch = NO;

		// Only receive touches on scrollView, not on subviews
	if (touch.view == self.personsTaggedView)
		{
		shouldReceiveTouch = YES;
		}

	return shouldReceiveTouch;
}

#pragma mark - Update Person info

- (void)updatePersonInfo:(NSOrderedSet *)abRecordIDs
{
	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);

		//reset mutablePeople set with no objects
	self.mutablePeopleSet = [[NSMutableOrderedSet alloc] initWithCapacity: 1];

	for (NSNumber *number in abRecordIDs)
		{
		ABRecordID abRecordID = [number intValue];

		ABRecordRef abPerson = ABAddressBookGetPersonWithRecordID(addressBook, abRecordID);

        CeaselessLocalContacts *ceaselessContacts = [CeaselessLocalContacts sharedCeaselessLocalContacts];
		[ceaselessContacts updateCeaselessContactFromABRecord: abPerson];
		PersonIdentifier *person = [ceaselessContacts getCeaselessContactFromABRecord: abPerson];
			//TODO crash here when no first name or last name (business) - got here when selected a business to tag, should not happen when selecting from Ceaseless Persons instead of ABRecords
        [self.mutablePeopleSet addObject: person];
		}

	CFRelease(addressBook);

}

#pragma mark - Target-action methods

	// Action receiver for the selecting of name button
- (void)buttonSelected:(id)sender
{
	[self.searchField becomeFirstResponder];

	self.selectedButton = (UIButton *)sender;

		// Clear other button states
	for (UIView *subview in self.personsTaggedView.subviews)
		{
		if ([subview isKindOfClass:[UIButton class]] && subview != self.selectedButton)
			{
			((UIButton *)subview).backgroundColor = [UIColor lightGrayColor];
			}
		}

	if (self.selectedButton.backgroundColor == self.selectedTokenColor)
		{
		self.selectedButton.backgroundColor = self.tokenColor;
		}
	else
		{
		self.selectedButton.backgroundColor = self.selectedTokenColor;
		}

	[self becomeFirstResponder];

}

- (IBAction)saveButtonPressed:(id)sender {


	NSError *error = nil;

	Note *note = [self containsItem:[self.currentNote valueForKey: @"createDate"]];
	if (note) {
			//if the object is found, update its fields
		note.text = self.notesTextView.text;
		note.lastUpdatedDate = [NSDate date];
		note.peopleTagged = nil; 
//		[note addPeopleTagged: self.mutablePeopleSet];
		note.peopleTagged = [[NSOrderedSet alloc] initWithSet:[self.mutablePeopleSet set]];


	} else {
	Note *newNote = [NSEntityDescription insertNewObjectForEntityForName:@"Note" inManagedObjectContext:self.managedObjectContext];
		[newNote setValue: [NSDate date] forKey: @"createDate"];
		[newNote setValue: self.notesTextView.text forKey: @"text"];
		[newNote setValue: [NSDate date] forKey: @"lastUpdatedDate"];
//		[newNote addPeopleTagged: self.mutablePeopleSet];
		newNote.peopleTagged = [[NSOrderedSet alloc] initWithSet:[self.mutablePeopleSet set]];


		}
	if (![self.managedObjectContext save: &error]) {
		NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
	}

	[self listAll];
    
    // TODO this could be causing some memory/cleanup issues, which lead to erratic crashing.
    
	if (self.delegate) {
		[self.delegate noteViewControllerDidFinish:self];
	} else {
		[self performSegueWithIdentifier:@"UnwindAddNoteSegue" sender: self];

	}
}
- (Note*) containsItem: (NSDate *) createDate {

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note"
											  inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
	NSError *error = nil;

	NSPredicate *pred = [NSPredicate predicateWithFormat:@"createDate == %@", createDate];

	[fetchRequest setPredicate:pred];

		//    NSLog(@"entity retrieved is %@", entity);

	NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

	if (fetchedObjects == nil) {
			// Handle the error
		NSLog (@"fetch error");
	}

	if ([fetchedObjects count] == 0) {
			//        NSLog (@"no mediatItemUser objects fetched");
		return nil;
	} else {
			// if there is an object, need to return it
		return [fetchedObjects objectAtIndex:0];
	}

}

	// Action receiver for the clicking of Cancel button
- (IBAction)cancelClick:(id)sender
{
	if (self.delegate) {
		[self.delegate noteViewControllerDidCancel:self];
	} else {
		[self performSegueWithIdentifier:@"UnwindAddNoteSegue" sender: self];
	}
}

	// Action receiver for the clicking on personsTaggedView
- (IBAction)scrollViewTapped:(id)sender
{
	self.tagFriendsPlaceholderText.hidden = YES;
	[self.searchField becomeFirstResponder];
	self.searchField.hidden = NO;

}

#pragma mark - UIKeyInput protocol conformance

- (BOOL)hasText
{
	return NO;
}

- (void)insertText:(NSString *)text {}

- (void)deleteBackward
{
		// Cast tag value to ABRecordID type
	ABRecordID abRecordID = (ABRecordID)self.selectedButton.tag;
	ABRecordRef abPerson = ABAddressBookGetPersonWithRecordID(self.addressBook, abRecordID);

	[self removePersonFromGroup:abPerson];
}

#pragma mark - Add and remove a person to/from the group

- (void)addPersonToGroup:(ABRecordRef)abRecordRef
{
	ABRecordID abRecordID = ABRecordGetRecordID(abRecordRef);
	NSNumber *number = [NSNumber numberWithInt:abRecordID];

	[self.group addObject:number];
	self.abRecordIDs = [NSOrderedSet orderedSetWithOrderedSet:self.group];
	[self updatePersonInfo: self.abRecordIDs];
	[self layoutScrollView: self.personsTaggedView forGroup: self.abRecordIDs];
	[self.searchField becomeFirstResponder];

}

- (void)removePersonFromGroup:(ABRecordRef)abRecordRef
{
	ABRecordID abRecordID = ABRecordGetRecordID(abRecordRef);
	NSNumber *number = [NSNumber numberWithInt:abRecordID];

	[self.group removeObject:number];
	self.abRecordIDs = [NSOrderedSet orderedSetWithOrderedSet:self.group];
	[self updatePersonInfo: self.abRecordIDs];
	[self layoutScrollView: self.personsTaggedView forGroup: self.abRecordIDs];

	if (self.abRecordIDs.count > 0) {
		self.tagFriendsPlaceholderText.hidden = YES;
	} else  {
		self.tagFriendsPlaceholderText.hidden = NO;
	}

}

#pragma mark - UITableViewDataSource protocol conformance

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
		// do we have search text? if yes, are there search results? if yes, return number of results, otherwise, return 1 (add email row)
		// if there are no search results, the table is empty, so return 0
	return self.searchField.text.length > 0 ? MAX( 1, self.filteredPeople.count ) : 0 ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];

	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.backgroundColor = [UIColor clearColor];


		// If this is the last row in filteredPeople, take special action
	if (self.filteredPeople.count == indexPath.row)
		{
		cell.textLabel.text	= @"Add new contact";
		cell.detailTextLabel.text = nil;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
	else
		{
		ABRecordRef abPerson = (__bridge ABRecordRef)([self.filteredPeople objectAtIndex:indexPath.row]);

		cell.textLabel.text = (__bridge_transfer NSString *)ABRecordCopyCompositeName(abPerson);
		cell.detailTextLabel.text = (__bridge_transfer NSString *)ABRecordCopyValue(abPerson, kABPersonOrganizationProperty);
		}

	return cell;
}

#pragma mark - UITableViewDelegate protocol conformance

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView setHidden:YES];

		// If this is the last row in filteredPeople, take special action
	if (indexPath.row == self.filteredPeople.count) {
		ABNewPersonViewController *newPersonViewController = [[ABNewPersonViewController alloc] init];
		newPersonViewController.newPersonViewDelegate = self;

		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newPersonViewController];

		[self presentViewController:navController animated:YES completion:NULL];
	} else {
		ABRecordRef abRecordRef = (__bridge ABRecordRef)([self.filteredPeople objectAtIndex:indexPath.row]);

		[self addPersonToGroup:abRecordRef];
	}

	self.searchField.text = nil;
}

#pragma mark - Update the filteredPeople array based on the search text.

- (void)filterContentForSearchText:(NSString *)searchText
{
		// First clear the filtered array.
	[self.filteredPeople removeAllObjects];

		// beginswith[cd] predicate
	NSPredicate *beginsPredicate = [NSPredicate predicateWithFormat:@"(SELF beginswith[cd] %@)", searchText];

	/*
	 Search the main list for people whose name OR organization matches searchText;
	 add items that match to the filtered array.
	 */

	for (id record in self.people)
		{
		ABRecordRef person = (__bridge ABRecordRef)record;

		NSString *compositeName = (__bridge_transfer NSString *)ABRecordCopyCompositeName(person);
		NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
		NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
		NSString *organization = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonOrganizationProperty);

			// Match by name or organization
		if ([beginsPredicate evaluateWithObject:compositeName] ||
			[beginsPredicate evaluateWithObject:firstName] ||
			[beginsPredicate evaluateWithObject:lastName] ||
			[beginsPredicate evaluateWithObject:organization])
			{
				// Add the matching person to filteredPeople
			[self.filteredPeople addObject:(__bridge id)person];
			}
		}
}

#pragma mark - UISearchBarDelegate protocol conformance

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	if (self.searchField.text.length > 0)
		{
		[self.contactsTableView setHidden:NO];
		[self filterContentForSearchText:self.searchField.text];
		[self.contactsTableView reloadData];
		}
	else
		{
		[self.contactsTableView setHidden:YES];
		}
}

#pragma mark - ABNewPersonViewControllerDelegate protocol conformance

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person
{
	if (person != NULL)
		{
		[self addPersonToGroup:person];
		}

	[newPersonView dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - listAll

- (void) listAll {
		// Test listing all tagData from the store

	NSError * error = nil;

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note"
											  inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];


	NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	for (id managedObject in fetchedObjects) {

		NSLog(@"create date: %@", [managedObject valueForKey: @"createDate"]);
		NSLog(@"text: %@", [managedObject valueForKey: @"text"]);
		NSLog(@"last update date: %@", [managedObject valueForKey: @"lastUpdatedDate"]);
		NSOrderedSet *peopleTagged = [managedObject valueForKey: @"peopleTagged"];
		for (PersonIdentifier *person in peopleTagged) {
			NSSet *firstNames = [person valueForKey: @"firstNames"];
			NSSet *lastNames = [person valueForKey: @"lastNames"];
			NSString *firstName = ((Name*)[firstNames anyObject]).name;
			NSLog (@"first Name is .......  %@", firstName);
			NSString *lastName = ((Name*)[lastNames anyObject]).name;
			NSLog (@"last Name is ......... %@", lastName);
//			NSLog(@"personTagged: %@ %@", firstName, lastName);
		}
	}
}

@end