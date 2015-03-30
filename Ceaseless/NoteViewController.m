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
#import "PersonPicker.h"
#import "CeaselessLocalContacts.h"
#import "Name.h"

@interface NoteViewController ()

@property (nonatomic, strong) NSMutableArray *namesArray;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) UINavigationItem *item;
@property (strong, nonatomic) NSMutableSet *mutablePeopleSet;
@property (nonatomic, strong) NSOrderedSet *abRecordIDs;
@property (strong, nonatomic) UITapGestureRecognizer *singleTapGestureRecognizer;

@end

@implementation NoteViewController

NSString *const kPlaceHolderText = @"Enter note";

- (void)viewDidLoad {
    [super viewDidLoad];
	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;

	self.namesArray = [NSMutableArray arrayWithCapacity: 1];
	self.mutablePeopleSet = [[NSMutableSet alloc] initWithCapacity: 1];

	self.notesTextView.delegate = self;

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

	UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];

	if (!self.navigationController) {
		self.item.rightBarButtonItem = saveButton;
	} else {
		self.navigationItem.rightBarButtonItem = saveButton;
	}
//	[self listAll];
	if (self.currentNote) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.timeStyle = NSDateFormatterNoStyle;
		dateFormatter.dateStyle = NSDateFormatterShortStyle;
		NSDate *date = [self.currentNote valueForKey: @"createDate"];

		self.notesTextView.text = [self.currentNote valueForKey: @"text"];
		NSSet *peopleTagged = [self.currentNote valueForKey: @"peopleTagged"];

		NSMutableOrderedSet *group = [NSMutableOrderedSet orderedSet];

		for (Person *personTagged in peopleTagged) {
			CeaselessLocalContacts *ceaselessLocalContacts = [[CeaselessLocalContacts alloc] init];
			NonMOPerson *nonMOPerson = [ceaselessLocalContacts getNonMOPersonForCeaselessContact: personTagged];

			ABRecordID abRecordID = [nonMOPerson.addressBookId intValue];
			NSNumber *number = [NSNumber numberWithInt:abRecordID];
			[group addObject:number];
		}

		self.abRecordIDs = [NSOrderedSet orderedSetWithOrderedSet: group];

		if (self.abRecordIDs.count > 0) {
			self.tagFriendsPlaceholderText.hidden = YES;
			TaggedPersonPicker *taggedPersonPicker = [[TaggedPersonPicker alloc] init];
			[taggedPersonPicker layoutScrollView: self.personsTaggedView forGroup: self.abRecordIDs];
			[self updatePersonInfo:self.abRecordIDs];

		} else  {
			self.tagFriendsPlaceholderText.hidden = NO;
		}

		self.notesTextView.editable = YES;

	} else {
			//no note passed in, so add a new note

		if (!self.navigationController) {
			self.item.title = @"Add Note";
		} else {
			self.navigationItem.title = @"Add Note";
		}

		if (self.personForNewNote) {
			[self.mutablePeopleSet addObject: self.personForNewNote];
			NSString *personName = [NSString stringWithFormat: @"%@ %@", ((Name*)[self.personForNewNote.firstNames anyObject]).name, ((Name*) [self.personForNewNote.lastNames anyObject]).name];
			[self.namesArray addObject:personName];

		}
		self.tagFriendsPlaceholderText.hidden = NO;
		self.notesTextView.text = kPlaceHolderText;
		self.notesTextView.textColor = [UIColor lightGrayColor];

	}
    // Do any additional setup after loading the view.
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

#pragma mark - View lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
		// Check the segue identifier
	if ([[segue identifier] isEqualToString:@"ShowTaggedPersonPicker"])
		{
		UINavigationController *navController = segue.destinationViewController;
		TaggedPersonPicker *picker = (TaggedPersonPicker *)navController.topViewController;
		picker.title = @"Select contact to tag";
		picker.maxCount = 999;
		picker.abRecordIDs = self.abRecordIDs;
		picker.delegate = self;
		}
}

#pragma mark - Update Person info

- (void)updatePersonInfo:(NSOrderedSet *)abRecordIDs
{
	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);

	for (NSNumber *number in abRecordIDs)
		{
		ABRecordID abRecordID = [number intValue];

		ABRecordRef abPerson = ABAddressBookGetPersonWithRecordID(addressBook, abRecordID);

        CeaselessLocalContacts *ceaselessContacts = [CeaselessLocalContacts sharedCeaselessLocalContacts];
		[ceaselessContacts updateCeaselessContactFromABRecord: abPerson];
		Person *person = [ceaselessContacts getCeaselessContactFromABRecord: abPerson];
        [self.mutablePeopleSet addObject: person];
		}

	CFRelease(addressBook);

}

#pragma mark - TaggedPersonPickerDelegate protocol conformance

- (void)taggedPersonPickerDidFinish:(TaggedPersonPicker *)taggedPersonPicker
					withABRecordIDs:(NSOrderedSet *)abRecordIDs
{
	[self updatePersonInfo: abRecordIDs];
	if (abRecordIDs.count > 0) {
		self.tagFriendsPlaceholderText.hidden = YES;
		[taggedPersonPicker layoutScrollView: self.personsTaggedView forGroup: abRecordIDs];
		[self updatePersonInfo:abRecordIDs];

	} else  {
		self.tagFriendsPlaceholderText.hidden = NO;
	}

	[taggedPersonPicker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)taggedPersonPickerDidCancel:(TaggedPersonPicker *)taggedPersonPicker
{
	[taggedPersonPicker dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)saveButtonPressed:(id)sender {


	NSError *error = nil;

	Note *note = [self containsItem:[self.currentNote valueForKey: @"createDate"]];
	if (note) {
			//if the object is found, update its fields
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
	[self performSegueWithIdentifier:@"ShowTaggedPersonPicker" sender: self];
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