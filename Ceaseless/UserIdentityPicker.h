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

#import <AddressBookUI/AddressBookUI.h>
#import "PersonIdentifier.h"
#import "CeaselessLocalContacts.h"

#define UIColorFromRGBWithAlpha(rgbValue,a) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:a]

@protocol UserIdentityPickerDelegate;

@interface UserIdentityPicker : UIViewController <ABNewPersonViewControllerDelegate,
												  UITableViewDataSource,
												  UITableViewDelegate>

@property (nonatomic, weak) id<UserIdentityPickerDelegate> delegate;

@property (nonatomic, readwrite) ABAddressBookRef addressBook;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong, nonatomic) CeaselessLocalContacts *ceaselessContacts;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@protocol UserIdentityPickerDelegate <NSObject>

// Called after the user has pressed Done.
// The delegate is responsible for dismissing the userIdentityPicker.
// abRecordIDs - ordered set of NSNumbers representing ABRecordIDs selected
- (void)userIdentityPickerDidFinish:(UserIdentityPicker *)userIdentityPicker
                    withPerson:(PersonIdentifier *)personIdentifier;

// Called after the user has pressed Cancel.
// The delegate is responsible for dismissing the userIdentityPicker.
- (void)userIdentityPickerDidCancel:(UserIdentityPicker *)userIdentityPicker;

@end
