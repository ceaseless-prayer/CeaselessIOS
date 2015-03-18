//
//  NoteViewController.h
//  Ceaseless
//
//  Created by Lori Hill on 3/12/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TaggedPersonPicker.h"
#import "Note.h"
#import "Person.h"

#define UIColorFromRGBWithAlpha(rgbValue,a) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:a]

@protocol NoteViewControllerDelegate;

@interface NoteViewController : UIViewController <TaggedPersonPickerDelegate, UITextViewDelegate>

@property (nonatomic, weak) id<NoteViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UITextView *personsTaggedView;
@property (weak, nonatomic) IBOutlet UITextView *notesTextView;
@property (weak, nonatomic) IBOutlet UIButton *tagFriendsButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceTopToView;

@property (strong, nonatomic) Note *currentNote;
@property (strong, nonatomic) Person *personForNewNote;

- (IBAction)saveButtonPressed:(id)sender;

@end

@protocol NoteViewControllerDelegate <NSObject>

	// Called after the user has pressed Done.
	// The delegate is responsible for dismissing the NoteViewController.
- (void)noteViewControllerDidFinish:(NoteViewController *)noteViewController;

	// Called after the user has pressed Cancel.
	// The delegate is responsible for dismissing the NoteViewController.
- (void)noteViewControllerDidCancel:(NoteViewController *)noteViewController;

@end