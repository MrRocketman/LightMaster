//
//  MNSequenceLibraryManagerViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MNData, MNSequenceControlBoxSelectorViewController, MNSequenceChannelGroupSelectorViewController, MNSequenceCommandClusterSelectorViewController, MNSequenceAudioClipSelectorViewController;

@interface MNSequenceLibraryManagerViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet MNData *data;
    __weak NSMutableDictionary *sequence;
    
    // General outlets
    IBOutlet NSTextField *descriptionTextField;
    IBOutlet NSTextField *startTimeTextField;
    IBOutlet NSTextField *endTimeTextField;
    
    // Control Boxes
    IBOutlet MNSequenceControlBoxSelectorViewController *sequenceControlBoxSelectorViewController;
    IBOutlet NSPopover *sequenceControlBoxSelectorPopover;
    IBOutlet NSTableView *controlBoxesTableView;
    IBOutlet NSButton *deleteControlBoxFromSequenceButton;
    IBOutlet NSButton *addControlBoxToSequenceButton;
    
    // Channel Groups
    IBOutlet MNSequenceChannelGroupSelectorViewController *sequenceChannelGroupSelectorViewController;
    IBOutlet NSPopover *sequenceChannelGroupSelectorPopover;
    IBOutlet NSTableView *channelGroupsTableView;
    IBOutlet NSButton *deleteChannleGroupFromSequenceButton;
    IBOutlet NSButton *addChannelGroupToSequenceButton;
    
    // Command Clusters
    IBOutlet MNSequenceCommandClusterSelectorViewController *sequenceCommandClusterSelectorViewController;
    IBOutlet NSPopover *sequenceCommandClusterSelectorPopover;
    IBOutlet NSTableView *commandClustersTableView;
    IBOutlet NSButton *deleteCommandClusterFromSequenceButton;
    IBOutlet NSButton *addCommandClusterToSequenceButton;
    
    // Audio Clips
    IBOutlet MNSequenceAudioClipSelectorViewController *sequenceAudioClipSelectorViewController;
    IBOutlet NSPopover *sequenceAudioClipSelectorPopover;
    IBOutlet NSTableView *audioClipsTableView;
    IBOutlet NSButton *deleteAudioClipFromSequenceButton;
    IBOutlet NSButton *addAudioClipToSequenceButton;
}

@property (weak) NSMutableDictionary *sequence;

- (void)updateContent;

- (IBAction)deleteControlBoxFromSequenceButtonPress:(id)sender;
- (IBAction)addControlBoxToSequenceButtonPress:(id)sender;

- (IBAction)deleteChannelGroupFromSequenceButtonPress:(id)sender;
- (IBAction)addChannelGroupToSequenceButtonPress:(id)sender;

- (IBAction)deleteCommandClusterFromSequenceButtonPress:(id)sender;
- (IBAction)addCommandClusterToSequenceButtonPress:(id)sender;

- (IBAction)deleteAudioClipFromSequenceButtonPress:(id)sender;
- (IBAction)addAudioClipToSequenceButtonPress:(id)sender;

@end
