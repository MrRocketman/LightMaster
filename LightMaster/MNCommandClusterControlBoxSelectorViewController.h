//
//  MNCommandClusterControlBoxSelectorViewController.h
//  LightMaster
//
//  Created by James Adams on 10/10/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MNData;

@interface MNCommandClusterControlBoxSelectorViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet MNData *data;
    
    IBOutlet NSTableView *controlBoxTableView;
    IBOutlet NSButton *chooseButton;
}

- (void)reload;

- (IBAction)chooseButtonPress:(id)sender;
- (void)setControlBoxIndex:(int)index;

@end
