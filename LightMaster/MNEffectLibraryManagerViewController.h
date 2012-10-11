//
//  MNEffectLibraryManagerViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MNData;

@interface MNEffectLibraryManagerViewController : NSViewController
{
    int effectIndex;
    IBOutlet MNData *data;
    
    IBOutlet NSTextField *descriptionTextField;
    IBOutlet NSTextView *scriptTextView;
    IBOutlet NSButton *compileButton;
}

@property() int effectIndex;

- (void)updateContent;

- (IBAction)compileButtonPress:(id)sender;

@end
