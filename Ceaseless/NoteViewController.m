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
#import "PersonViewController.h"
#import "CeaselessLocalContacts.h"
#import "Name.h"
#import "AppUtils.h"

@interface NoteViewController ()

@property (nonatomic, strong) NSMutableArray *namesArray;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) UINavigationItem *item;
@property (strong, nonatomic) NSMutableOrderedSet *mutablePeopleSet;
@property (strong, nonatomic) UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, strong) UIButton *selectedButton;
@property (nonatomic, strong) NSArray *people;
@property (nonatomic, strong) NSArray *filteredPeople;
@property (nonatomic, strong) UISearchBar *searchField;
@property (nonatomic, strong) UIColor *appColor;
@property (strong, nonatomic) NSFetchRequest *searchFetchRequest;

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
    
    //initialize
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
        [self.notesTextView becomeFirstResponder];
	}

	if (peopleTagged.count > 0) {
		self.tagFriendsPlaceholderText.hidden = YES;
		self.mutablePeopleSet = [[NSMutableOrderedSet alloc] initWithOrderedSet: peopleTagged];
	} else  {
		self.tagFriendsPlaceholderText.hidden = NO;
	}
	
	[self layoutScrollView: self.personsTaggedView forGroup: self.mutablePeopleSet];
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Respond to touch and become first responder.

- (BOOL)canBecomeFirstResponder {
    if(self.currentNote && !self.selectedButton) {
        return NO; //don't show keyboard by default
    } else {
        return YES; // show keyboard by default for a blank note.
    }
}

#pragma mark - Update the displayed list of tagged people
- (void) layoutScrollView: (UIScrollView *) scrollView forGroup: (NSOrderedSet *) mutablePeopleSet {
    [self layoutScrollView:scrollView forGroup: mutablePeopleSet selectLast:NO];
}

- (void) layoutScrollView: (UIScrollView *) scrollView forGroup: (NSOrderedSet *) mutablePeopleSet selectLast: (BOOL) selectLast {
    // Remove existing buttons
    for (UIView *subview in scrollView.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            [subview removeFromSuperview];
        }
    }
    
    CGFloat maxWidth = [[UIScreen mainScreen] bounds].size.width - 16 - kPadding;
    CGFloat xPosition = kPadding;
    CGFloat yPosition = kPadding;
	int tagId = 0;
    
    for (PersonIdentifier *person in mutablePeopleSet) {
        
        // Copy the name associated with this person record
		NSString *name = [[CeaselessLocalContacts sharedCeaselessLocalContacts ]compositeNameForPerson: person];
        UIFont *font = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0f];
        
        // Create the button
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:name forState:UIControlStateNormal];
        [button.titleLabel setFont:font];
        [button setBackgroundColor:self.tokenColor];
        [button.layer setCornerRadius:4.0];
		[button setTag:tagId];
		++tagId;
		
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
    
    if (selectLast) {
        UIView *lastButton = scrollView.subviews.lastObject;
        if(lastButton && lastButton != self.searchField) {
            [self buttonSelected:lastButton];
        }
    }
    
    UIFont *font = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0f];
    
    // Create the textfield at the end of the buttons
    
    // Get the width and height of the name string given a font size
    NSString *placeholderName = @"Average Size";
    CGSize nameSize = [placeholderName sizeWithAttributes:@{NSFontAttributeName:font}];
    
    if ((xPosition + nameSize.width + kPadding) > maxWidth) {
        // Reset horizontal position to left edge of superview's frame
        xPosition = kPadding;
        
        // Set vertical position to a new 'line'
        yPosition += nameSize.height + kPadding;
    }
    
    // Create the button's frame
    CGRect searchFieldFrame = CGRectMake(xPosition, yPosition, nameSize.width + (kPadding * 2), nameSize.height);
    self.searchField.frame = searchFieldFrame;
    self.searchField.hidden = YES;
 
    // setting font color of search field
    for (UIView *subView in self.searchField.subviews) {
        for (UIView *secondLevelSubview in subView.subviews){
            if ([secondLevelSubview isKindOfClass:[UITextField class]]) {
                UITextField *searchBarTextField = (UITextField *)secondLevelSubview;
                
                //set font color here
                searchBarTextField.textColor = [UIColor whiteColor];
                break;
            }
        }
    }
    
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

	[self layoutScrollView: self.personsTaggedView forGroup: self.mutablePeopleSet];
    
	[self registerForKeyboardNotifications];
	return YES;
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	if ([[textView text] length] == 0) {
		textView.text = kPlaceHolderText;
		textView.textColor = [UIColor lightGrayColor];
	}
	[self unregisterForKeyboardNotifications];
	return YES;
}

- (void)registerForKeyboardNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
											   object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillBeHidden:)
												 name:UIKeyboardWillHideNotification
											   object:nil];


}
- (void)unregisterForKeyboardNotifications {
		//    LogMethod();
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIKeyboardWillShowNotification
												  object: nil];

	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIKeyboardWillHideNotification
												  object: nil];

}

#pragma mark - Keyboard methods

	// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShow:(NSNotification*)aNotification
{
	NSDictionary *info = [aNotification userInfo];
	NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

	CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

	self.verticalSpaceTextToBottomConstraint.constant = kbSize.height;

	[self.view setNeedsUpdateConstraints];

	[UIView animateWithDuration:animationDuration animations:^{
		[self.view layoutIfNeeded];
	}];
}

	// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
	NSDictionary *info = [aNotification userInfo];
	NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

	self.verticalSpaceTextToBottomConstraint.constant = 0;

	[self.view setNeedsUpdateConstraints];

	[UIView animateWithDuration:animationDuration animations:^{
		[self.view layoutIfNeeded];
	}];
}

#pragma mark - UIGestureRecognizer delegate protocol conformance

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	BOOL shouldReceiveTouch = NO;

    // Only receive touches on scrollView, not on subviews
    if (touch.view == self.personsTaggedView) {
        shouldReceiveTouch = YES;
    }

	return shouldReceiveTouch;
}

#pragma mark - Target-action methods

// Action receiver for the selecting of name button
- (void)buttonSelected:(id)sender {
	[self.searchField becomeFirstResponder];
    [self hideTagInput];
	self.selectedButton = (UIButton *)sender;

    [self resetAppearanceOfPeopleTagged];

	if (self.selectedButton.backgroundColor == self.selectedTokenColor) {
		//self.selectedButton.backgroundColor = self.tokenColor;
        // open up the person details.
        PersonViewController *personViewController = [[PersonViewController alloc]init];
        personViewController.dataObject = [self.mutablePeopleSet objectAtIndex:self.selectedButton.tag];
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"Note"
                                                                style: UIBarButtonItemStylePlain
                                                                    target:nil
                                                                    action:nil];
        
        [self.navigationItem setBackBarButtonItem:backItem];
        [self.navigationController pushViewController:personViewController animated:YES];
    } else {
		self.selectedButton.backgroundColor = self.selectedTokenColor;
    }

	[self becomeFirstResponder];
}

- (void) resetAppearanceOfPeopleTagged {
    // Clear other button states
    for (UIView *subview in self.personsTaggedView.subviews) {
        if ([subview isKindOfClass:[UIButton class]] && subview != self.selectedButton) {
            ((UIButton *)subview).backgroundColor = [UIColor lightGrayColor];
        }
    }
}

- (IBAction)saveButtonPressed:(id)sender {

	NSError *error = nil;

	Note *note = [self containsItem:[self.currentNote valueForKey: @"createDate"]];
	if (note) {
			//if the object is found, update its fields
		note.text = self.notesTextView.text;
		note.lastUpdatedDate = [NSDate date];
		note.peopleTagged = nil;
		note.peopleTagged = [[NSOrderedSet alloc] initWithSet:[self.mutablePeopleSet set]];
	} else {
        Note *newNote = [NSEntityDescription insertNewObjectForEntityForName:@"Note" inManagedObjectContext:self.managedObjectContext];
		[newNote setValue: [NSDate date] forKey: @"createDate"];
		[newNote setValue: self.notesTextView.text forKey: @"text"];
		[newNote setValue: [NSDate date] forKey: @"lastUpdatedDate"];
		newNote.peopleTagged = [[NSOrderedSet alloc] initWithSet:[self.mutablePeopleSet set]];
    }
	if (![self.managedObjectContext save: &error]) {
		NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
	}

	[self listAll];
    
    // TODO this could be causing some memory/cleanup issues, which lead to erratic crashing.
    // if this came from the root view controller/page view controller/ person card
    // then we can pop back.
    if(self.navigationController.viewControllers.count == 2) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if(self.delegate) { // TODO still needed?
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
- (IBAction)cancelClick:(id)sender {
	if (self.delegate) {
		[self.delegate noteViewControllerDidCancel:self];
	} else {
		[self performSegueWithIdentifier:@"UnwindAddNoteSegue" sender: self];
	}
}

// Action receiver for the clicking on personsTaggedView
- (IBAction)scrollViewTapped:(id)sender {
	self.tagFriendsPlaceholderText.hidden = YES;
	[self.searchField becomeFirstResponder];
	self.searchField.hidden = NO;
    self.selectedButton = nil;
    [self resetAppearanceOfPeopleTagged];
}

- (void) hideTagInput {
    if(self.mutablePeopleSet.count == 0) {
        self.tagFriendsPlaceholderText.hidden = NO;
    }
    self.searchField.hidden = YES;
}

#pragma mark - UIKeyInput protocol conformance

- (BOOL)hasText {
	return NO;
}

- (void)insertText:(NSString *)text {}

- (void) deleteBackward {
	[self.mutablePeopleSet removeObjectAtIndex: self.selectedButton.tag];
	[self layoutScrollView: self.personsTaggedView forGroup: self.mutablePeopleSet selectLast: YES];

	if (self.mutablePeopleSet.count > 0) {
		self.tagFriendsPlaceholderText.hidden = YES;
	} else  {
		self.tagFriendsPlaceholderText.hidden = NO;
	}
    if(self.searchField.isFirstResponder) {
        self.searchField.hidden = YES;
    }
}
#pragma mark - Add and remove a person to/from the group of people tagged

- (void)addABPersonToCeaseless:(ABRecordRef)abRecordRef {
	ABRecordID abRecordID = ABRecordGetRecordID(abRecordRef);

	ABAddressBookRef addressBook = [AppUtils getAddressBookRef];

	ABRecordRef abPerson = ABAddressBookGetPersonWithRecordID(addressBook, abRecordID);

	CeaselessLocalContacts *ceaselessContacts = [CeaselessLocalContacts sharedCeaselessLocalContacts];
	[ceaselessContacts updateCeaselessContactFromABRecord: abPerson];
	PersonIdentifier *person = [ceaselessContacts getCeaselessContactFromABRecord: abPerson];

	CFRelease(addressBook);

	[self addCeaselessPersonToGroup: person];

}

- (void)addCeaselessPersonToGroup:(PersonIdentifier *) person {
	[self.mutablePeopleSet addObject: person];

	[self layoutScrollView: self.personsTaggedView forGroup: self.mutablePeopleSet];
	[self.searchField becomeFirstResponder];
    [self scrollViewTapped:self];
}

#pragma mark - UITableViewDataSource protocol conformance

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // do we have search text? if yes, are there search results? if yes, return number of results, otherwise, return 1 (add email row)
    // if there are no search results, the table is empty, so return 0
	return self.searchField.text.length > 0 ? MAX( 1, self.filteredPeople.count ) : 0 ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];

	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.backgroundColor = [UIColor clearColor];

		// If this is the last row in filteredPeople, take special action
	if (self.filteredPeople.count == indexPath.row) {
		cell.textLabel.text	= @"Add new contact";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
		PersonIdentifier *person = [self.filteredPeople objectAtIndex:indexPath.row];
		cell.textLabel.text = [[CeaselessLocalContacts sharedCeaselessLocalContacts ]compositeNameForPerson: person];
    }

	return cell;
}

#pragma mark - UITableViewDelegate protocol conformance

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.contactsBlurBackground.hidden = YES;

		// If this is the last row in filteredPeople, take special action
	if (indexPath.row == self.filteredPeople.count) {
		ABNewPersonViewController *newPersonViewController = [[ABNewPersonViewController alloc] init];
		newPersonViewController.newPersonViewDelegate = self;

		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newPersonViewController];

		[self presentViewController:navController animated:YES completion:NULL];
	} else {
		PersonIdentifier *person = [self.filteredPeople objectAtIndex:indexPath.row];
		[self addCeaselessPersonToGroup: person];
	}

	self.searchField.text = nil;
}

#pragma mark - Update the filteredPeople array based on the search text.

- (void)filterContentForSearchText:(NSString *)searchText
{

	NSString *predicateFormat = @"(representativeInfo.primaryFirstName.name BEGINSWITH[cd] %@ OR representativeInfo.primaryLastName.name BEGINSWITH[cd] %@ OR  (representativeInfo.primaryFirstName.name BEGINSWITH[cd] %@ AND representativeInfo.primaryLastName.name BEGINSWITH[cd] %@))";

	NSString *searchFirst = searchText;
	NSString *searchLast = searchText;

	if ([searchText containsString: @" "]) {
		NSArray *substrings = [searchText componentsSeparatedByString:@" "];
		if ([searchText hasSuffix: @" "]) {
			searchText = [substrings objectAtIndex:0];
			searchFirst = [substrings objectAtIndex:0];
			searchLast = searchFirst;
		} else {
			searchFirst = [substrings objectAtIndex:0];
				//when there is a first name and last name change operator to "AND" to return just that person
			searchLast = [substrings objectAtIndex:1];
		}
	}

	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, searchText, searchText, searchFirst, searchLast];

	[self.searchFetchRequest setPredicate:predicate];

				// Add the matching person to filteredPeople
	NSError *error = nil;
	self.filteredPeople = [self.managedObjectContext executeFetchRequest:self.searchFetchRequest error:&error];
}

#pragma mark - UISearchBarDelegate protocol conformance

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	if (self.searchField.text.length > 0) {
		[self.contactsBlurBackground setHidden:NO];
		[self filterContentForSearchText:self.searchField.text];
		[self.contactsTableView reloadData];
    } else {
		[self.contactsBlurBackground setHidden:YES];
    }
}

#pragma mark - ABNewPersonViewControllerDelegate protocol conformance

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person
{
	if (person != NULL) {
		[self addABPersonToCeaseless: person];
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
            PersonInfo *info = person.representativeInfo;
			NSString *firstName = info.primaryFirstName.name;
			NSLog (@"first Name is .......  %@", firstName);
            NSString *lastName = info.primaryLastName.name;
			NSLog (@"last Name is ......... %@", lastName);
		}
	}
}

- (NSFetchRequest *)searchFetchRequest
{
	if (_searchFetchRequest != nil)
  {
  return _searchFetchRequest;
  }

	_searchFetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"PersonIdentifier" inManagedObjectContext:self.managedObjectContext];
	[_searchFetchRequest setEntity:entity];

		// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor1 = [NSSortDescriptor sortDescriptorWithKey:@"representativeInfo.primaryLastName.name" ascending:YES selector: @selector(caseInsensitiveCompare:)];
	NSSortDescriptor *sortDescriptor2 = [NSSortDescriptor sortDescriptorWithKey:@"representativeInfo.primaryFirstName.name" ascending:YES selector: @selector(caseInsensitiveCompare:)];
	NSArray *sortDescriptors = @[sortDescriptor1, sortDescriptor2];
	[_searchFetchRequest setSortDescriptors:sortDescriptors];

	return _searchFetchRequest;
}
@end