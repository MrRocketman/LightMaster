//
//  MNLibrariesViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MNControlBoxLibraryManagerViewController, MNCommandClusterLibraryManagerViewController, MNEffectClusterLibraryManagerViewController, MNAudioClipLibraryManagerViewController, MNChannelGroupLibraryManagerViewController, MNSequenceLibraryManagerViewController;

#define NUMBER_OF_LIBRARIES 6

enum
{
    kSequenceLibrary,
    kControlBoxLibrary,
    kChannelGroupLibrary,
    kCommandClusterLibrary,
    kEffectClusterLibrary,
    kAudioClipLibrary
};

@interface MNLibrariesViewController : NSViewController
{
    IBOutlet NSButton *sequenceLibraryButton;
    IBOutlet NSButton *controlBoxLibraryButton;
    IBOutlet NSButton *channelGroupLibraryButton;
    IBOutlet NSButton *commandClusterLibraryButton;
    IBOutlet NSButton *effectClusterLibraryButton;
    IBOutlet NSButton *audioClipLibraryButton;
    
    // Library Data Selection
    IBOutlet NSTableView *libraryDataSelectionTableView;
    IBOutlet NSButton *addLibraryDataButton;
    IBOutlet NSButton *deleteLibraryDataButton;
    
    // Library Content
    IBOutlet NSScrollView *libraryContentScrollView;
    IBOutlet MNSequenceLibraryManagerViewController *sequenceLibraryManagerViewController;
    IBOutlet MNControlBoxLibraryManagerViewController *controlBoxLibraryManagerViewController;
    IBOutlet MNChannelGroupLibraryManagerViewController *channelGroupLibraryManagerViewController;
    IBOutlet MNCommandClusterLibraryManagerViewController *commandClusterLibraryManagerViewController;
    IBOutlet MNEffectClusterLibraryManagerViewController *effectClusterLibraryManagerViewController;
    IBOutlet MNAudioClipLibraryManagerViewController *audioClipLibraryManagerViewController;
    int selectedLibrary;
}

- (void)displayLibrary:(int)library;
- (IBAction)addLibraryDataButtonPress:(id)sender;
- (IBAction)deleteLibraryDataButtonPress:(id)sender;

@end
