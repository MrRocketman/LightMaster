//
//  MNLibrariesViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MNControlBoxLibraryManagerViewController, MNCommandClusterLibraryManagerViewController, MNEffectLibraryManagerViewController, MNAudioClipLibraryManagerViewController, MNChannelGroupLibraryManagerViewController, MNSequenceLibraryManagerViewController, MNData;

#define NUMBER_OF_LIBRARIES 6

enum
{
    kSequenceLibrary,
    kControlBoxLibrary,
    kChannelGroupLibrary,
    kCommandClusterLibrary,
    kEffectLibrary,
    kAudioClipLibrary
};

@interface MNLibrariesViewController : NSViewController
{
    IBOutlet MNData *data;
    int selectedLibrary;
    
    // Tab bar
    IBOutlet NSButton *sequenceLibraryButton;
    IBOutlet NSButton *controlBoxLibraryButton;
    IBOutlet NSButton *channelGroupLibraryButton;
    IBOutlet NSButton *commandClusterLibraryButton;
    IBOutlet NSButton *effectLibraryButton;
    IBOutlet NSButton *audioClipLibraryButton;
    NSArray *tabBarButtons;
    
    // Library Data Selection
    IBOutlet NSTableView *libraryDataSelectionTableView;
    IBOutlet NSButton *addLibraryDataButton;
    IBOutlet NSButton *importButton;
    IBOutlet NSButton *deleteLibraryDataButton;
    IBOutlet NSButton *exportButton;
    IBOutlet NSButton *playPlaylistButton;
    BOOL playingPlaylist;
    int previouslySelectedRowsInLibraryDataSelectionTableView[NUMBER_OF_LIBRARIES];
    NSOpenPanel *openPanel;
    NSString *previousOpenPanelDirectory;
    
    // Library Content
    IBOutlet NSScrollView *libraryContentScrollView;
    IBOutlet MNSequenceLibraryManagerViewController *sequenceLibraryManagerViewController;
    IBOutlet MNControlBoxLibraryManagerViewController *controlBoxLibraryManagerViewController;
    IBOutlet MNChannelGroupLibraryManagerViewController *channelGroupLibraryManagerViewController;
    IBOutlet MNCommandClusterLibraryManagerViewController *commandClusterLibraryManagerViewController;
    IBOutlet MNEffectLibraryManagerViewController *effectLibraryManagerViewController;
    IBOutlet MNAudioClipLibraryManagerViewController *audioClipLibraryManagerViewController;
    NSArray *libraries;
}

- (void)displayLibrary:(int)library;
- (IBAction)addLibraryDataButtonPress:(id)sender;
- (IBAction)deleteLibraryDataButtonPress:(id)sender;
- (IBAction)playPlaylistButtonPress:(id)sender;
- (IBAction)importButtonPress:(id)sender;
- (IBAction)exportButtonPress:(id)sender;

@end
