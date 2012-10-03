//
//  LibraryViewController.h
//  LightMaster
//
//  Created by James Adams on 12/4/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Data.h"

@class ControlBoxSelectorViewController, GroupSelectorViewController, ChannelSelectorViewController, ChannelAndControlBoxSelectorViewController, SequenceSoundSelectorViewController, SequenceControlBoxSelectorViewController, SequenceGroupSelectorViewController, SequenceCommandClusterSelectorViewController;

enum
{
    kControlBoxLibrary,
    kCommandClusterLibrary,
    kEffectLibrary,
    kSoundLibrary,
    kGroupLibrary,
    kSequenceLibrary
};

@interface LibraryViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource, NSTextViewDelegate>
{
    Data *__weak data;
    
    // Library tabs
    IBOutlet NSButton *controlBoxesButton;
    IBOutlet NSButton *commandClustersButton;
    IBOutlet NSButton *effectsButton;
    IBOutlet NSButton *soundsButton;
    IBOutlet NSButton *groupsButton;
    IBOutlet NSButton *sequencesButton;
    
    // Library table view
    IBOutlet NSTableView *tableView;
    int selectedLibrary;
    int previouslySelectedRowsInMainTableView[6];
    
    IBOutlet NSView *detailViewWell;
    
    // Control Boxes
    IBOutlet NSScrollView *controlBoxDetailScrollView;
    IBOutlet NSButton *deleteControlBoxButton;
    IBOutlet NSTextField *controlBoxIDTextField;
    IBOutlet NSTextField *controlBoxDescriptionTextField;
    IBOutlet NSTableView *controlBoxChannelsTableView;
    IBOutlet NSButton *deleteChannelFromControlBoxButton;
    IBOutlet NSButton *addChannelToControlBoxButton;
    
    // Command Clusters
    IBOutlet NSScrollView *commandClusterDetailScrollView;
    IBOutlet NSButton *deleteCommandClusterButton;
    IBOutlet NSTextField *commandClusterDescriptionTextField;
    IBOutlet NSTextField *startTimeTextField;
    IBOutlet NSTextField *endTimeTextField;
    IBOutlet NSTextField *adjustCommandClusterByTextField;
    IBOutlet NSTextField *controlBoxDescriptionForCommandCluster;
    IBOutlet NSButton *selectControlBoxForCommandClusterButton;
    IBOutlet NSTextField *groupDescriptionForCommandCluster;
    IBOutlet NSButton *selectGroupForCommandClusterButton;
    IBOutlet NSTableView *commandsTableView;
    IBOutlet NSTextField *commandChannelInformationTextField;
    IBOutlet NSTextField *commandControlBoxInformationTextField;
    IBOutlet NSButton *selectChannelForCommandButton;
    IBOutlet NSButton *deleteCommandButton;
    IBOutlet NSButton *addCommandButton;
    IBOutlet NSPopover *controlBoxPopover;
    IBOutlet ControlBoxSelectorViewController *controlBoxSelectorViewController;
    IBOutlet NSPopover *groupPopover;
    IBOutlet GroupSelectorViewController *groupSelectorViewController;
    IBOutlet NSPopover *channelPopover;
    IBOutlet ChannelSelectorViewController *channelSelectorViewController;
    
    // Effects
    IBOutlet NSScrollView *effectDetailScrollView;
    IBOutlet NSButton *deleteEffectButton;
    IBOutlet NSTextField *effectDescriptionTextField;
    IBOutlet NSTextView *effectScriptTextView;
    IBOutlet NSButton *compileEffectButton;
    
    // Sounds
    IBOutlet NSScrollView *soundDetailsScrollView;
    IBOutlet NSButton *deleteSoundButton;
    IBOutlet NSTextField *soundDescriptionTextField;
    IBOutlet NSTextField *soundStartTimeTextField;
    IBOutlet NSTextField *soundEndTimeTextField;
    IBOutlet NSTextField *audioFilePathTextField;
    IBOutlet NSButton *selectAudioFileFromLibraryButton;
    IBOutlet NSButton *selectExternalAudioFileButton;
    NSOpenPanel *openPanel;
    
    // Groups
    IBOutlet NSScrollView *groupDetailScrollView;
    IBOutlet NSButton *deleteGroupButton;
    IBOutlet NSTextField *groupDescriptionTextField;
    IBOutlet NSTableView *groupItemsTableView;
    IBOutlet NSButton *deleteItemFromGroupButton;
    IBOutlet NSButton *addItemToGroupButton;
    IBOutlet NSPopover *channelAndControlBoxPopover;
    IBOutlet ChannelAndControlBoxSelectorViewController *channelAndControlBoxSelectorViewController;
    
    // Sequences
    IBOutlet NSScrollView *sequenceDetailScrollView;
    IBOutlet NSButton *deleteSequenceButton;
    IBOutlet NSButton *loadSequenceButton;
    IBOutlet NSTextField *sequenceDescriptionTextField;
    IBOutlet NSTextField *sequenceStartTimeTextField;
    IBOutlet NSTextField *sequenceEndTimeTextField;
    IBOutlet NSTableView *sequenceSoundsTableView;
    IBOutlet NSButton *deleteSoundFromSequenceButton;
    IBOutlet NSButton *addSoundToSequenceButton;
    IBOutlet NSTableView *sequenceControlBoxesTableView;
    IBOutlet NSButton *deleteControlBoxFromSequenceButton;
    IBOutlet NSButton *addControlBoxToSequenceButton;
    IBOutlet NSTableView *sequenceGroupsTableView;
    IBOutlet NSButton *deleteGroupFromSequenceButton;
    IBOutlet NSButton *addGroupToSequenceButton;
    IBOutlet NSTableView *sequenceCommandClusterTableView;
    IBOutlet NSButton *deleteCommandClusterFromSequenceButton;
    IBOutlet NSButton *addCommandClusterToSequenceButton;
    IBOutlet NSPopover *sequenceSoundPopover;
    IBOutlet SequenceSoundSelectorViewController *sequenceSoundSelectorViewController;
    IBOutlet NSPopover *sequenceControlBoxPopover;
    IBOutlet SequenceControlBoxSelectorViewController *sequenceControlBoxSelectorViewController;
    IBOutlet NSPopover *sequenceGroupPopover;
    IBOutlet SequenceGroupSelectorViewController *sequenceGroupSelectorViewController;
    IBOutlet NSPopover *sequenceCommandClusterPopover;
    IBOutlet SequenceCommandClusterSelectorViewController *sequenceCommandClusterSelectorViewController;
}

@property(readwrite, weak) Data *data;

- (void)prepareForDisplay;

// Menu Buttons
- (void)newSequence:(NSNotification *)notificaiton;
- (void)newControlBox:(NSNotification *)notification;
- (void)newGroup:(NSNotification *)notification;
- (void)newSound:(NSNotification *)notification;
- (void)newEffect:(NSNotification *)notification;
- (void)newCommandCluster:(NSNotification *)notification;

- (IBAction)toggleButtonPress:(id)sender;

// ControlBox
- (IBAction)deleteControlBoxButtonPress:(id)sender;
- (IBAction)deleteChannelFromControlBoxButtonPress:(id)sender;
- (IBAction)addChannelToControlBoxButtonPress:(id)sender;

// Command Cluster
- (IBAction)deleteCommandClusterButtonPress:(id)sender;
- (IBAction)selectControlBoxForCommandClusterButtonPress:(id)sender;
- (IBAction)selectGroupForCommandClusterButtonPress:(id)sender;
- (IBAction)selectChannelForCommandButtonPress:(id)sender;
- (IBAction)deleteCommandButtonPress:(id)sender;
- (IBAction)addCommandButtonPress:(id)sender;

// Effect
- (IBAction)deleteEffectButtonPress:(id)sender;
- (IBAction)compileEffectButtonPress:(id)sender;

// Sound
- (IBAction)deleteSoundButtonPress:(id)sender;
- (IBAction)selectExternalAudioFileButtonPress:(id)sender;
- (IBAction)selectAudioFileFromLibrary:(id)sender;
- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void  *)contextInfo;

// Group
- (IBAction)deleteGroupButtonPress:(id)sender;
- (IBAction)deleteItemFromGroupButtonPress:(id)sender;
- (IBAction)addItemToGroupButtonPress:(id)sender;

// Sequence
- (IBAction)deleteSequenceButtonPress:(id)sender;
- (IBAction)loadSequenceButtonPress:(id)sender;
- (IBAction)deleteSoundFromSequenceButtonPress:(id)sender;
- (IBAction)addSoundToSequenceButtonPress:(id)sender;
- (IBAction)deleteControlBoxFromSequenceButtonPress:(id)sender;
- (IBAction)addControlBoxToSequenceButtonPress:(id)sender;
- (IBAction)deleteGroupFromSequenceButtonPress:(id)sender;
- (IBAction)addGroupToSequenceButtonPress:(id)sender;
- (IBAction)deleteCommandClusterFromSequenceButtonPress:(id)sender;
- (IBAction)addCommandClustertoSequenceButtonPress:(id)sender;

@end
