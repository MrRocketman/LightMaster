//
//  MNSequenceLibraryManagerViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MNData, MNSequenceControlBoxSelectorViewController, MNSequenceChannelGroupSelectorViewController, MNSequenceCommandClusterSelectorViewController, MNSequenceEffectClusterSelectorViewController, MNSequenceAudioClipViewController;

@interface MNSequenceLibraryManagerViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet MNData *data;
    __weak NSMutableDictionary *sequence;
    
    // General outlets
    __weak NSTextField *descriptionTextField;
    __weak NSTextField *startTimeTextField;
    __weak NSTextField *endTimeTextField;
    
    // Control Boxes
    __weak MNSequenceControlBoxSelectorViewController *sequenceControlBoxSelectorViewController;
    __weak NSPopover *sequenceControlBoxSelectorPopover;
    __weak NSTableView *controlBoxesTableView;
    __weak NSButton *deleteControlBoxFromSequenceButton;
    __weak NSButton *addControlBoxToSequenceButton;
    
    // Channel Groups
    __weak MNSequenceChannelGroupSelectorViewController *sequenceChannelGroupSelectorViewController;
    __weak NSPopover *sequenceChannelGroupSelectorPopover;
    __weak NSTableView *channelGroupsTableView;
    __weak NSButton *deleteChannleGroupFromSequenceButton;
    __weak NSButton *addChannelGroupToSequenceButton;
    
    // Command Clusters
    __weak NSTableView *commandClustersTableView;
    __weak NSButton *deleteCommandClusterFromSequenceButton;
    __weak NSButton *addCommandClusterToSequenceButton;
    
    // Effect Clusters
    __weak NSTableView *effectClustersTableView;
    __weak NSButton *deleteEffectClusterFromSequenceButton;
    __weak NSButton *addEffectClusterToSequenceButton;
    
    // Audio Clips
    __weak NSTableView *audioClipsTableView;
    __weak NSButton *deleteAudioClipFromSequenceButton;
    __weak NSButton *addAudioClipToSequenceButton;
}

@property(weak) NSMutableDictionary *sequence;

@property (weak) IBOutlet NSTextField *descriptionTextField;
@property (weak) IBOutlet NSTextField *startTimeTextField;
@property (weak) IBOutlet NSTextField *endTimeTextField;

@property (weak) IBOutlet MNSequenceControlBoxSelectorViewController *sequenceControlBoxSelectorViewController;
@property (weak) IBOutlet NSPopover *sequenceControlBoxSelectorPopover;
@property (weak) IBOutlet NSTableView *controlBoxesTableView;
@property (weak) IBOutlet NSButton *deleteControlBoxFromSequenceButton;
@property (weak) IBOutlet NSButton *addControlBoxToSequenceButton;

@property (weak) IBOutlet MNSequenceChannelGroupSelectorViewController *sequenceChannelGroupSelectorViewController;
@property (weak) IBOutlet NSPopover *sequenceChannelGroupSelectorPopover;
@property (weak) IBOutlet NSTableView *channelGroupsTableView;
@property (weak) IBOutlet NSButton *deleteChannleGroupFromSequenceButton;
@property (weak) IBOutlet NSButton *addChannelGroupToSequenceButton;

@property (weak) IBOutlet NSTableView *commandClustersTableView;
@property (weak) IBOutlet NSButton *deleteCommandClusterFromSequenceButton;
@property (weak) IBOutlet NSButton *addCommandClusterToSequenceButton;

@property (weak) IBOutlet NSTableView *effectClustersTableView;
@property (weak) IBOutlet NSButton *deleteEffectClusterFromSequenceButton;
@property (weak) IBOutlet NSButton *addEffectClusterToSequenceButton;

@property (weak) IBOutlet NSTableView *audioClipsTableView;
@property (weak) IBOutlet NSButton *deleteAudioClipFromSequenceButton;
@property (weak) IBOutlet NSButton *addAudioClipToSequenceButton;


- (IBAction)deleteControlBoxFromSequenceButtonPress:(id)sender;
- (IBAction)addControlBoxToSequenceButtonPress:(id)sender;

- (IBAction)deleteChannelGroupFromSequenceButtonPress:(id)sender;
- (IBAction)addChannelGroupToSequenceButtonPress:(id)sender;

- (IBAction)deleteCommandClusterFromSequenceButtonPress:(id)sender;
- (IBAction)addCommandClusterToSequenceButtonPress:(id)sender;

- (IBAction)deleteEffectClusterFromSequenceButtonPress:(id)sender;
- (IBAction)addEffectClusterToSequenceButtonPress:(id)sender;

- (IBAction)deleteAudioClipFromSequenceButtonPress:(id)sender;
- (IBAction)addAudioClipToSequenceButtonPress:(id)sender;

- (void)updateContent;

@end
