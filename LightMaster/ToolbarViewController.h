//
//  ToolbarViewController.h
//  LightMaster
//
//  Created by James Adams on 12/11/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Data.h"

@interface ToolbarViewController : NSViewController
{
    Data *__weak data;
    
    IBOutlet NSButton *rewindButton;
    IBOutlet NSButton *fastForwardButton;
    IBOutlet NSButton *skipBackButton;
    IBOutlet NSButton *playButton;
    IBOutlet NSButton *recordButton;
    IBOutlet NSTextField *currentTimeTextField;
}

@property(readwrite, weak) Data *data;

- (void)prepareForDisplay;

- (IBAction)rewindButtonPress:(id)sender;
- (IBAction)fastForwardButtonPress:(id)sender;
- (IBAction)skipBackButtonPress:(id)sender;
- (IBAction)playButtonPress:(id)sender;
- (IBAction)recordButtonPress:(id)sender;

@end
