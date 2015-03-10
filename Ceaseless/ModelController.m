//
//  ModelController.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/2/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "ModelController.h"
#import "DataViewController.h"
#import "PersonPicker.h"
#import "NonMOPerson.h"
#import "AppDelegate.h"
#import "ScripturePicker.h"
#import "NonMOScripture.h"
#import "ScriptureViewController.h"
#import "PersonViewController.h"

/*
 A controller object that manages a simple model -- a collection of month names.
 
 The controller serves as the data source for the page view controller; it therefore implements pageViewController:viewControllerBeforeViewController: and pageViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.
 
 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 */


@interface ModelController ()

@property (readonly, strong, nonatomic) NSArray *personData;
@property (readonly, strong, nonatomic) NonMOScripture *scripture;
@property (strong, nonatomic) NSMutableArray *cardArray;

@end

@implementation ModelController

- (instancetype)init {
    self = [super init];
    if (self) {
        // Create the data model.
        // Initializes to app delegate card array
		ScripturePicker *scripturePicker = [[ScripturePicker alloc] init];
		_scripture = [scripturePicker requestDailyVerseReference];

		PersonPicker *personPicker = [[PersonPicker alloc] init];
		[personPicker loadContacts];
        
        // set local members to point to app delegate
		AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
        
        _cardArray = [[NSMutableArray alloc] initWithArray: appDelegate.peopleArray];
        [_cardArray insertObject: appDelegate.scripture atIndex: 0];

    }
    return self;
}

- (DataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard {
    // Return the data view controller for the given index.
    if (([self.cardArray count] == 0) || (index >= [self.cardArray count])) {
        return nil;
    }

    // Create a new view controller and pass suitable data.

    DataViewController *contentViewController;
    if ([self.cardArray[index] isMemberOfClass:[NonMOScripture class]]) {
        contentViewController = [[ScriptureViewController alloc] init];
    } else {
        contentViewController = [[PersonViewController alloc] init];
    }

    contentViewController.dataObject = self.cardArray[index];
	contentViewController.index = index;
    return contentViewController;
}

- (NSUInteger)indexOfViewController:(DataViewController *)viewController {
    // Return the index of the given data view controller.
    // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
    return [self.cardArray indexOfObject:viewController.dataObject];
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(DataViewController *)viewController];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(DataViewController *)viewController];
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.cardArray count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

#pragma mark -
#pragma mark Page Indicator

- (NSInteger) presentationCountForPageViewController: (UIPageViewController *) pageViewController
{
    return [self.cardArray count];
}

- (NSInteger) presentationIndexForPageViewController: (UIPageViewController *) pageViewController
{
    return 0;
}

@end
