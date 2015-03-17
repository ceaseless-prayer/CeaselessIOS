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

@protocol TaggedPersonPickerDelegate;

// Important: TaggedPersonPicker view controllers must be used with a navigation controller
// in order to function properly.
@interface TaggedPersonPicker : UIViewController <ABPeoplePickerNavigationControllerDelegate,
                                                  ABNewPersonViewControllerDelegate,
                                                  UISearchBarDelegate,
												  UITableViewDataSource,
												  UITableViewDelegate,
												  UIKeyInput,
                                                  UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<TaggedPersonPickerDelegate> delegate;

// The Address Book to browse. All contacts returned will be from that ABAddressBook instance.
// If not set, a new ABAddressBookRef will be created the first time the property is accessed.
@property (nonatomic, readwrite) ABAddressBookRef addressBook;

// Color of tokens. Default is the global tintColor
@property (nonatomic, strong) UIColor *tokenColor;

// Color of selected token. Default is blackColor.
@property (nonatomic, strong) UIColor *selectedTokenColor;

@end

@protocol TaggedPersonPickerDelegate <NSObject>

// Called after the user has pressed Done.
// The delegate is responsible for dismissing the taggedPersonPicker.
// abRecordIDs - ordered set of NSNumbers representing ABRecordIDs selected
- (void)taggedPersonPickerDidFinish:(TaggedPersonPicker *)taggedPersonPicker
                    withABRecordIDs:(NSOrderedSet *)abRecordIDs;

// Called after the user has pressed Cancel.
// The delegate is responsible for dismissing the TaggedPersonPicker.
- (void)taggedPersonPickerDidCancel:(TaggedPersonPicker *)taggedPersonPicker;

@end
