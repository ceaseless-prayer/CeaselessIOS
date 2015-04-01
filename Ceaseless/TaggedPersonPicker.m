/*
 * Copyright 2014 shrtlist.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "TaggedPersonPicker.h"

@interface TaggedPersonPicker () // Class extension
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UITableView *contactsTableView;
@property (nonatomic, weak) IBOutlet UISearchBar *searchField;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *doneButton;

@property (nonatomic, strong) NSMutableArray *filteredPeople;
@property (nonatomic, strong) NSMutableOrderedSet *group;
@property (nonatomic, strong) NSArray *people;
@property (nonatomic, strong) UIButton *selectedButton;
@end

@implementation TaggedPersonPicker

static CGFloat const kPadding = 5.0;

#pragma mark - View lifecycle methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.tokenColor)
    {
        self.tokenColor = self.view.tintColor;
	self.tokenColor = [UIColor lightGrayColor];

    }

    if (!self.selectedTokenColor)
    {
        self.selectedTokenColor = [UIColor darkGrayColor];
    }

		//Customized the searchBar
	self.searchField.searchBarStyle = UISearchBarStyleMinimal;

	self.searchField.backgroundColor = self.tokenColor;
	self.searchField.barTintColor = self.selectedTokenColor;
	self.searchField.tintColor = [UIColor whiteColor];
	[self.searchField.layer setCornerRadius:4.0];
    // Add a tap gesture recognizer to our scrollView
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewTapped:)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    singleTapGestureRecognizer.enabled = YES;
    singleTapGestureRecognizer.cancelsTouchesInView = YES;
    singleTapGestureRecognizer.delegate = self;
    [self.scrollView addGestureRecognizer:singleTapGestureRecognizer];

		// Check whether we are authorized to access the user's address book data
	if (self.addressBook == NULL)
		{
		self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
		}
	[self checkAddressBookAccess];
	[self layoutScrollView:self.scrollView forGroup:self.abRecordIDs];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Keep the keyboard up
//	self.searchField.hidden = YES;
    [self.searchField becomeFirstResponder];
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
    TaggedPersonPicker* __weak weakSelf = self;
    
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

#pragma mark - Target-action methods

// Action receiver for the clicking of Done button
- (IBAction)doneClick:(id)sender
{
	if ([self.group count] > self.maxCount) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
														message:NSLocalizedString(@"Please select only one name.", @"Please select only one name.")
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
											  otherButtonTitles:nil];
		[alert show];
	} else {
		NSOrderedSet *abRecordIDs = [NSOrderedSet orderedSetWithOrderedSet:self.group];
		[self.delegate taggedPersonPickerDidFinish:self withABRecordIDs:abRecordIDs];

	}

}

// Action receiver for the clicking of Cancel button
- (IBAction)cancelClick:(id)sender
{
//	[self.group removeAllObjects];
	[self.delegate taggedPersonPickerDidCancel:self];
}

// Action receiver for the selecting of name button
- (void)buttonSelected:(id)sender
{
	self.selectedButton = (UIButton *)sender;
	
	// Clear other button states
	for (UIView *subview in self.scrollView.subviews)
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
- (void)scrollViewTapped:(UITapGestureRecognizer *)gestureRecognizer
{
    // Clear button states
	for (UIView *subview in self.scrollView.subviews)
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
	if (indexPath.row == self.filteredPeople.count)
    {
        ABNewPersonViewController *newPersonViewController = [[ABNewPersonViewController alloc] init];
        newPersonViewController.newPersonViewDelegate = self;
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newPersonViewController];
        
        [self presentViewController:navController animated:YES completion:NULL];
	}
	else
    {
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

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar
{
	ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
    peoplePicker.addressBook = self.addressBook;
	peoplePicker.peoplePickerDelegate = self;
	
	// Show the people picker modally
	[self presentViewController:peoplePicker animated:YES completion:NULL];
}

#pragma mark - UIGestureRecognizer delegate protocol conformance

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    BOOL shouldReceiveTouch = NO;

    // Only receive touches on scrollView, not on subviews
    if (touch.view == self.scrollView)
    {
        shouldReceiveTouch = YES;
    }
    
    return shouldReceiveTouch;
}

#pragma mark - Add and remove a person to/from the group

- (void)addPersonToGroup:(ABRecordRef)abRecordRef
{
    ABRecordID abRecordID = ABRecordGetRecordID(abRecordRef);
    NSNumber *number = [NSNumber numberWithInt:abRecordID];

    [self.group addObject:number];
	self.abRecordIDs = [NSOrderedSet orderedSetWithOrderedSet:self.group];
	[self layoutScrollView: self.scrollView forGroup: self.abRecordIDs];
	[self.searchField becomeFirstResponder];

}

- (void)removePersonFromGroup:(ABRecordRef)abRecordRef
{
    ABRecordID abRecordID = ABRecordGetRecordID(abRecordRef);
    NSNumber *number = [NSNumber numberWithInt:abRecordID];
    
	[self.group removeObject:number];
	self.abRecordIDs = [NSOrderedSet orderedSetWithOrderedSet:self.group];
	[self layoutScrollView: self.scrollView forGroup: self.abRecordIDs];
	[self.searchField becomeFirstResponder];

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

	for (NSNumber *number in abRecordIDs)
    {
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
		[scrollView addSubview:button];
		
		// Calculate xPosition for the next button in the loop
		xPosition += button.frame.size.width + kPadding;
	}
    
    if (abRecordIDs.count > 0)
    {
        [self.doneButton setEnabled:YES];
    }
    else
    {
        [self.doneButton setEnabled:NO];
    }

	// Set the content size so it can be scrollable
    CGFloat height = yPosition + 30.0;
	[scrollView setContentSize:CGSizeMake([[UIScreen mainScreen] bounds].size.width - 16, height)];

}

#pragma mark - ABPeoplePickerNavigationControllerDelegate protocol conformance

// Displays the information of a selected person
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)picker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	[self addPersonToGroup:person];
    
	// Dismiss the people picker
	[picker dismissViewControllerAnimated:YES completion:NULL];
	
	// Dismiss the underlying search display controller
	self.searchDisplayController.active = NO;

    return NO;
}

// This should never get called since we dismiss the picker in the above method.
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{	
	return NO;
}

// Dismisses the people picker and shows the application when users tap Cancel. 
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
	// Dismiss the people picker
    [peoplePicker dismissViewControllerAnimated:YES completion:NULL];
	
//	// Dismiss the underlying search display controller
//	self.searchDisplayController.active = NO;
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

@end
