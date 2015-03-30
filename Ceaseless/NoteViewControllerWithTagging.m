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
#import "Person.h"
#import "CeaselessLocalContacts.h"
#import "Name.h"
#import "UIView+SubviewConstaints.h"

@interface NoteViewController () < UISearchResultsUpdating, UISearchControllerDelegate>

@property (nonatomic, strong) NSMutableArray *namesArray;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) UINavigationItem *item;
@property (strong, nonatomic) NSMutableSet *mutablePeopleSet;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *filteredPeople;
@property (nonatomic, strong) NSMutableOrderedSet *group;
@property (nonatomic, strong) NSArray *people;
@property (nonatomic, strong) UIButton *selectedButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *saveButton;





@end

@implementation NoteViewController

static CGFloat const kPadding = 5.0;

NSString *const kPlaceHolderText = @"Enter note";

- (void)viewDidLoad {
    [super viewDidLoad];
	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;

	self.namesArray = [NSMutableArray arrayWithCapacity: 1];
	self.mutablePeopleSet = [[NSMutableSet alloc] initWithCapacity: 1];

	self.notesTextView.delegate = self;
	self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneClick:)];
		//create navigation bar if there is no navigation controller
	if (!self.navigationController) {
		UINavigationBar *navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
		navBar.barTintColor = UIColorFromRGBWithAlpha(0x24292f , 0.4);
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
		//if there is a note, just display it and set the right bar button to "Edit"
//	[self listAll];
	if (self.currentNote) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.timeStyle = NSDateFormatterNoStyle;
		dateFormatter.dateStyle = NSDateFormatterShortStyle;
		NSDate *date = [self.currentNote valueForKey: @"createDate"];

		self.notesTextView.text = [self.currentNote valueForKey: @"text"];
		NSSet *peopleTagged = [self.currentNote valueForKey: @"peopleTagged"];
		NSMutableSet *namesSet = [[NSMutableSet alloc] initWithCapacity: [peopleTagged count]];
		for (Person *personTagged in peopleTagged) {
			NSString *personName = [NSString stringWithFormat: @"%@ %@", ((Name*)[personTagged.firstNames anyObject]).name, ((Name*) [personTagged.lastNames anyObject]).name];
			[namesSet addObject: personName];
			[self.namesArray addObject:personName];
		}
		NSString *allNamesString = [[namesSet allObjects] componentsJoinedByString:@", "];
		self.personsTaggedView.text = allNamesString;
		self.personsTaggedView.editable = NO;
		self.notesTextView.editable = NO;
//		self.tagFriendsButton.enabled = NO;

		UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editMode:)];

		if (!self.navigationController) {
			self.item.title = [dateFormatter stringFromDate:date];
			self.item.rightBarButtonItem = editButton;
		} else {
			self.navigationItem.title = [dateFormatter stringFromDate:date];
			self.navigationItem.rightBarButtonItem = editButton;
		}

	} else {
			//no note passed in, so add a new note, set right bar button to "Save"

		self.saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];

		if (!self.navigationController) {
			self.item.title = @"Add Note";
			self.item.rightBarButtonItem = self.saveButton;
		} else {
			self.navigationItem.title = @"Add Note";
			self.navigationItem.rightBarButtonItem = self.saveButton;
		}

		if (self.personForNewNote) {
			[self.mutablePeopleSet addObject: self.personForNewNote];
			NSString *personName = [NSString stringWithFormat: @"%@ %@", ((Name*)[self.personForNewNote.firstNames anyObject]).name, ((Name*) [self.personForNewNote.lastNames anyObject]).name];
			self.personsTaggedView.text = personName;
			[self.namesArray addObject:personName];

		}
		self.notesTextView.text = kPlaceHolderText;
		self.notesTextView.textColor = [UIColor lightGrayColor];
         // if this is a new note, the first thing we want to do is take the note.
//        [self.notesTextView becomeFirstResponder];
	}
	//searchController for tagging people cannot be set up in IB, so set it up here
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	self.searchController.searchResultsUpdater = self;
	self.searchController.dimsBackgroundDuringPresentation = NO;
	self.searchController.searchBar.barTintColor = UIColorFromRGBWithAlpha(0x24292f , 0.4);
	self.searchController.searchBar.tintColor = [UIColor whiteColor];
	self.searchController.searchBar.delegate = self;
	self.searchController.delegate = self;
	CGRect newRect = CGRectMake(self.searchView.frame.origin.x, self.searchView.frame.origin.y, self.searchView.frame.size.width, self.searchView.frame.size.height);
	self.searchController.searchBar.frame = newRect;

	[self.searchView addSubview: self.searchController.searchBar];
//	[self.searchView setDynamicViewConstraintsForSubview: self.searchController.searchBar];
//	self.definesPresentationContext = YES;

	self.tableView.delegate = self;

		// Add a tap gesture recognizer to our scrollView
	UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(personsTaggedViewTapped:)];
	singleTapGestureRecognizer.numberOfTapsRequired = 1;
	singleTapGestureRecognizer.enabled = YES;
	singleTapGestureRecognizer.cancelsTouchesInView = YES;
	singleTapGestureRecognizer.delegate = self;
	[self.personsTaggedView addGestureRecognizer:singleTapGestureRecognizer];

	if (self.addressBook == NULL)
		{
		self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
		}

		// Check whether we are authorized to access the user's address book data
	[self checkAddressBookAccess];
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

	self.group = [NSMutableOrderedSet orderedSet];

		// Create a filtered list that will contain people for the search results table.
	self.filteredPeople = [NSMutableArray array];
}
#pragma mark - Target-action methods

	// Action receiver for the selecting of name button
- (void)buttonSelected:(id)sender
{
	self.selectedButton = (UIButton *)sender;

		// Clear other button states
	for (UIView *subview in self.personsTaggedView.subviews)
		{
		if ([subview isKindOfClass:[UIButton class]] && subview != self.selectedButton)
			{
			((UIButton *)subview).backgroundColor = self.tokenColor;
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

	// Action receiver when scrollView is tapped
- (void)personsTaggedViewTapped:(UITapGestureRecognizer *)gestureRecognizer
{
		// Clear button states
	for (UIView *subview in self.personsTaggedView.subviews)
		{
		if ([subview isKindOfClass:[UIButton class]])
			{
			((UIButton *)subview).backgroundColor = self.tokenColor;
			}
		}
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
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) editMode: (id) sender {
	UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
	if (!self.navigationController) {
		self.item.title = @"Add Note";
		self.item.rightBarButtonItem = saveButton;
	} else {
		self.navigationItem.title = @"Add Note";
		self.navigationItem.rightBarButtonItem = saveButton;
	}
	self.personsTaggedView.editable = YES;
	self.notesTextView.editable = YES;
//	self.tagFriendsButton.enabled = YES;
		//bring up keyboard and move cursor to text view
	[self.notesTextView becomeFirstResponder];

}

#pragma mark -
#pragma mark === UISearchResultsUpdating ===
#pragma mark -

- (void)willPresentSearchController:(UISearchController *)searchController {
	if (!self.navigationController) {
		self.item.rightBarButtonItem = self.doneButton;
	} else {
		self.navigationItem.rightBarButtonItem = self.doneButton;
	}
	self.tableView.hidden = NO;
	[self.notesTextView resignFirstResponder];
	[self.tableView becomeFirstResponder];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSString *searchString = searchController.searchBar.text;
	[self searchForText:searchString];
	[self.tableView reloadData];
}

- (void)searchForText:(NSString *)searchText
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
- (void)willDismissSearchController:(UISearchController *)searchController {
	if (!self.navigationController) {
		self.item.rightBarButtonItem = self.saveButton;
	} else {
		self.navigationItem.rightBarButtonItem = self.saveButton;
	}
	self.tableView.hidden = YES;
	[self.tableView resignFirstResponder];
}


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

#pragma mark - UITableViewDataSource protocol conformance

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
		// do we have search text? if yes, are there search results? if yes, return number of results, otherwise, return 1 (add email row)
		// if there are no search results, the table is empty, so return 0
	return self.searchController.searchBar.text.length > 0 ? MAX( 1, self.filteredPeople.count ) : 0 ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];

	cell.accessoryType = UITableViewCellAccessoryNone;

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

	ABRecordRef abRecordRef = (__bridge ABRecordRef)([self.filteredPeople objectAtIndex:indexPath.row]);

	[self addPersonToGroup:abRecordRef];

	self.searchController.searchBar.text = nil;
}

#pragma mark - Add and remove a person to/from the group

- (void)addPersonToGroup:(ABRecordRef)abRecordRef
{
	ABRecordID abRecordID = ABRecordGetRecordID(abRecordRef);
	NSNumber *number = [NSNumber numberWithInt:abRecordID];

	[self.group addObject:number];
	[self layoutPersonsTaggedView];
}

- (void)removePersonFromGroup:(ABRecordRef)abRecordRef
{
	ABRecordID abRecordID = ABRecordGetRecordID(abRecordRef);
	NSNumber *number = [NSNumber numberWithInt:abRecordID];

	[self.group removeObject:number];
	[self layoutPersonsTaggedView];
}

#pragma mark - Update Person info

- (void) layoutPersonsTaggedView
{
		// Remove existing buttons
	for (UIView *subview in self.personsTaggedView.subviews)
		{
		if ([subview isKindOfClass:[UIButton class]])
			{
			[subview removeFromSuperview];
			}
		}

	CGFloat maxWidth = self.personsTaggedView.frame.size.width - kPadding;
	CGFloat xPosition = kPadding;
	CGFloat yPosition = kPadding;

	for (NSNumber *number in self.group)
		{
		ABRecordID abRecordID = [number intValue];
		ABRecordRef abPerson = ABAddressBookGetPersonWithRecordID(self.addressBook, abRecordID);

			// Copy the name associated with this person record
		NSString *name = (__bridge_transfer NSString *)ABRecordCopyCompositeName(abPerson);

		UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

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

		if ((xPosition + nameSize.width + kPadding) > maxWidth)
			{
				// Reset horizontal position to left edge of superview's frame
			xPosition = kPadding;

				// Set vertical position to a new 'line'
			yPosition += nameSize.height + kPadding;
			}

			// Create the button's frame
		CGRect buttonFrame = CGRectMake(xPosition, yPosition, nameSize.width + (kPadding * 2), nameSize.height);
		[button setFrame:buttonFrame];

			// Add the button to its superview
		[self.personsTaggedView addSubview:button];

			// Calculate xPosition for the next button in the loop
		xPosition += button.frame.size.width + kPadding;
		}

	if (self.group.count > 0)
		{
		[self.doneButton setEnabled:YES];
		}
	else
		{
		[self.doneButton setEnabled:NO];
		}

		// Set the content size so it can be scrollable
	CGFloat height = yPosition + 30.0;
	[self.personsTaggedView setContentSize:CGSizeMake([self.personsTaggedView bounds].size.width, height)];

	[self.searchController.searchBar becomeFirstResponder];
}
#pragma mark - View lifecycle

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//		// Check the segue identifier
//	if ([[segue identifier] isEqualToString:@"ShowTaggedPersonPicker"]) {
//		UINavigationController *navController = segue.destinationViewController;
//		TaggedPersonPicker *picker = (TaggedPersonPicker *)navController.topViewController;
//		picker.delegate = self;
//    }
//}

#pragma mark - Update Person info

- (void)updatePersonInfo:(NSOrderedSet *)abRecordIDs
{
	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);

	for (NSNumber *number in abRecordIDs) {
		ABRecordID abRecordID = [number intValue];

		ABRecordRef abPerson = ABAddressBookGetPersonWithRecordID(addressBook, abRecordID);

        CeaselessLocalContacts *ceaselessContacts = [CeaselessLocalContacts sharedCeaselessLocalContacts];
		[ceaselessContacts updateCeaselessContactFromABRecord: abPerson];
		Person *person = [ceaselessContacts getCeaselessContactFromABRecord: abPerson];
        [self.mutablePeopleSet addObject: person];

		NSString *name = (__bridge_transfer NSString *)ABRecordCopyCompositeName(abPerson);

        [self.namesArray addObject:name];
    }

	CFRelease(addressBook);

	NSString *namesString = [self.namesArray componentsJoinedByString:@", "];

	self.personsTaggedView.text = namesString;
}

//#pragma mark - TaggedPersonPickerDelegate protocol conformance
//
//- (void)taggedPersonPickerDidFinish:(TaggedPersonPicker *)taggedPersonPicker
//					withABRecordIDs:(NSOrderedSet *)abRecordIDs {
//	[self updatePersonInfo:abRecordIDs];
//
//	[taggedPersonPicker dismissViewControllerAnimated:YES completion:NULL];
//}
//
//- (void)taggedPersonPickerDidCancel:(TaggedPersonPicker *)taggedPersonPicker {
//	[taggedPersonPicker dismissViewControllerAnimated:YES completion:NULL];
//}

- (IBAction)saveButtonPressed:(id)sender {


	NSError *error = nil;

	NSOrderedSet *abRecordIDs = [NSOrderedSet orderedSetWithOrderedSet:self.group];
	[self updatePersonInfo:abRecordIDs];


    // TODO should we create a key for the note besides the date?
    // Date is sufficient for now since the same person cannot simultaneously
    // create two notes, but could this result in two notes with the same "id"?
	Note *note = [self containsItem:[self.currentNote valueForKey: @"createDate"]];
	if (note) {
        //if the object is found, update its fields
//		[note setValue: self.notesTextView.text forKey: @"text"];
//		[note setValue: [NSDate date] forKey: @"lastUpdatedDate"];
		note.text = self.notesTextView.text;
		note.lastUpdatedDate = [NSDate date];
		[note addPeopleTagged: self.mutablePeopleSet];


	} else {
        Note *newNote = [NSEntityDescription insertNewObjectForEntityForName:@"Note" inManagedObjectContext:self.managedObjectContext];
		[newNote setValue: [NSDate date] forKey: @"createDate"];
		[newNote setValue: self.notesTextView.text forKey: @"text"];
		[newNote setValue: [NSDate date] forKey: @"lastUpdatedDate"];
		[newNote addPeopleTagged: self.mutablePeopleSet];
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
#pragma mark - Target-action methods

	// Action receiver for the clicking of Done button
- (IBAction)doneClick:(id)sender
{

	[self.delegate noteViewControllerDidFinish:self];
}

	// Action receiver for the clicking of Cancel button
- (IBAction)cancelClick:(id)sender
{
	[self.group removeAllObjects];

	if (self.delegate) {
		[self.delegate noteViewControllerDidCancel:self];
	} else {
		[self performSegueWithIdentifier:@"UnwindAddNoteSegue" sender: self];
	}
}
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
		NSSet *peopleTagged = [managedObject valueForKey: @"peopleTagged"];
		for (Person *person in peopleTagged) {
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