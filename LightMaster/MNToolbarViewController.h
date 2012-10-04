//
//  MNToolbarViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MNData.h"

@interface MNToolbarViewController : NSViewController
{
    IBOutlet MNData *data;
    
    IBOutlet NSButton *rewindButton;
    IBOutlet NSButton *fastForwardButton;
    IBOutlet NSButton *skipBackButton;
    IBOutlet NSButton *playButton;
    IBOutlet NSButton *recordButton;
    IBOutlet NSTextField *currentTimeTextField;
}


- (IBAction)rewindButtonPress:(id)sender;
- (IBAction)fastForwardButtonPress:(id)sender;
- (IBAction)skipBackButtonPress:(id)sender;
- (IBAction)playButtonPress:(id)sender;
- (IBAction)recordButtonPress:(id)sender;

@end
