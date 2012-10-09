//
//  MNSequenceAudioClipViewController.h
//  LightMaster
//
//  Created by James Adams on 10/8/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MNData.h"

@interface MNSequenceAudioClipSelectorViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>
{
    IBOutlet MNData *data;
    
    IBOutlet NSTableView *tableView;
    IBOutlet NSTextField *beingUsedLabel;
    IBOutlet NSButton *addButton;
    IBOutlet NSButton *addCopyButton;
}

- (IBAction)addButtonPress:(id)sender;
- (IBAction)addCopyButtonPress:(id)sender;

- (void)reload;
- (void)setSelectedAudioClipFilePath:(NSString *)selectedAudioClipFilePath;

@end
