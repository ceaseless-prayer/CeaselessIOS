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

//		//done Button on toolbar above keyboard
//	UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
//	[keyboardToolbar sizeToFit];
//	UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
//									  initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
//									  target:nil action:nil];
//	UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
//									  initWithBarButtonSystemItem:UIBarButtonSystemItemDone
//									  target:self action:@selector(doneButtonPressed:)];
//	keyboardToolbar.items = @[flexBarButton, doneBarButton];
//	keyboardToolbar.tintColor = [UIColor whiteColor];
//	self.personsTaggedView.inputAccessoryView = keyboardToolbar;
//	self.notesTextView.inputAccessoryView = keyboardToolbar;



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
		self.tagFriendsButton.enabled = NO;

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

		UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];

		if (!self.navigationController) {
			self.item.title = @"Add Note";
			self.item.rightBarButtonItem = saveButton;
		} else {
			self.navigationItem.title = @"Add Note";
			self.navigationItem.rightBarButtonItem = saveButton;
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
        [self.notesTextView becomeFirstResponder];
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
	self.tagFriendsButton.enabled = YES;
		//bring up keyboard and move cursor to text view
	[self.notesTextView becomeFirstResponder];

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
//- (IBAction)doneButtonPressed:(id)sender {
//
//		//sender is UIBarButtonItem
//
//	if ([self.personsTaggedView isFirstResponder]) {  //comments entered, Done pressed
//		[self.personsTaggedView resignFirstResponder];
//
//	} else {
//		if ([self.notesTextView isFirstResponder]) { //location was entered, Done was pressed
//			[self.notesTextView resignFirstResponder];
//		}
//	}
//}
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
	if ([[segue identifier] isEqualToString:@"ShowTaggedPersonPicker"]) {
		UINavigationController *navController = segue.destinationViewController;
		TaggedPersonPicker *picker = (TaggedPersonPicker *)navController.topViewController;
		picker.delegate = self;
    }
}

#pragma mark - Update Person info

- (void)updatePersonInfo:(NSOrderedSet *)abRecordIDs
{
	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);

	for (NSNumber *number in abRecordIDs) {
		ABRecordID abRecordID = [number intValue];

		ABRecordRef abPerson = ABAddressBookGetPersonWithRecordID(addressBook, abRecordID);

		PersonPicker *personPicker = [[PersonPicker alloc] init];
		
		[personPicker updateCeaselessContactFromABRecord: abPerson];
		Person *person = [personPicker getCeaselessContactFromABRecord: abPerson];
        [self.mutablePeopleSet addObject: person];

		NSString *name = (__bridge_transfer NSString *)ABRecordCopyCompositeName(abPerson);

        [self.namesArray addObject:name];
    }

	CFRelease(addressBook);

	NSString *namesString = [self.namesArray componentsJoinedByString:@", "];

	self.personsTaggedView.text = namesString;
}

#pragma mark - TaggedPersonPickerDelegate protocol conformance

- (void)taggedPersonPickerDidFinish:(TaggedPersonPicker *)taggedPersonPicker
					withABRecordIDs:(NSOrderedSet *)abRecordIDs {
	[self updatePersonInfo:abRecordIDs];

	[taggedPersonPicker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)taggedPersonPickerDidCancel:(TaggedPersonPicker *)taggedPersonPicker {
	[taggedPersonPicker dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)saveButtonPressed:(id)sender {


	NSError *error = nil;

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