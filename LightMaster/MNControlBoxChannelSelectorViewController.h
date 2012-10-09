//
//  MNControlBoxChannelSelectorViewController.h
//  LightMaster
//
//  Created by James Adams on 10/9/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MNData.h"

@interface MNControlBoxChannelSelectorViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet MNData *data;
    
    IBOutlet NSTableView *controlBoxTableView;
    IBOutlet NSTableView *channelTableView;
    IBOutlet NSButton *chooseButton;
}

- (IBAction)chooseButtonPress:(id)sender;

@end
