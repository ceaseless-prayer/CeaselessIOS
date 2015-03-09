//
//  ScriptureView.h
//  Ceaseless
//
//  Created by Lori Hill on 3/4/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScriptureView : UIView
@property (weak, nonatomic) IBOutlet UIView *cardView;
@property (weak, nonatomic) IBOutlet UIView *shadowView;
@property (weak, nonatomic) IBOutlet UITextView *scriptureTextView;
@property (weak, nonatomic) IBOutlet UILabel *scriptureReferenceLabel;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;

@end
