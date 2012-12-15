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
    
    IBOutlet NSPopUpButton *serialPortsPopUpButton;
    
    IBOutlet NSButton *rewindButton;
    IBOutlet NSButton *fastForwardButton;
    IBOutlet NSButton *skipBackButton;
    IBOutlet NSButton *playButton;
    IBOutlet NSButton *loopButton;
    IBOutlet NSTextField *currentTimeTextField;
}

- (IBAction)serialPortSelection:(id)sender;

- (IBAction)rewindButtonPress:(id)sender;
- (IBAction)fastForwardButtonPress:(id)sender;
- (IBAction)skipBackButtonPress:(id)sender;
- (IBAction)playButtonPress:(id)sender;
- (IBAction)loopButtonPress:(id)sender;

- (IBAction)sectionsCheckboxPress:(id)sender;
- (IBAction)barsCheckboxPress:(id)sender;
- (IBAction)beatsCheckboxPress:(id)sender;
- (IBAction)tatumsCheckboxPress:(id)sender;
- (IBAction)segmentsCheckboxPress:(id)sender;
- (IBAction)timeCheckboxPress:(id)sender;

@end
