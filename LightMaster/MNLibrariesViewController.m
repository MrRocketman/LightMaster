//
//  MNLibrariesViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNLibrariesViewController.h"
#import "MNSequenceLibraryManagerViewController.h"
#import "MNControlBoxLibraryManagerViewController.h"
#import "MNChannelGroupLibraryManagerViewController.h"
#import "MNCommandClusterLibraryManagerViewController.h"
#import "MNEffectClusterLibraryManagerViewController.h"
#import "MNAudioClipLibraryManagerViewController.h"

@interface MNLibrariesViewController ()

// External Notifications
- (void)selectCommandCluster:(NSNotification *)aNotification;
- (void)selectCommand:(NSNotification *)aNotification;
- (void)selectAudioClip:(NSNotification *)aNotification;

// Menu Items
- (void)newSequence:(NSNotification *)aNotification;
- (void)newControlBox:(NSNotification *)aNotification;
- (void)newChannelGroup:(NSNotification *)aNotification;
- (void)newAudioClip:(NSNotification *)aNotification;
- (void)newEffectCluster:(NSNotification *)aNotification;
- (void)newCommandCluster:(NSNotification *)aNotification;

- (void)removeLibraryContentView:(int)library;
- (void)addLibraryContentView:(int)library;
- (void)selectLibraryInTabList:(int)library;
- (IBAction)libraryButtonPress:(id)sender;
- (NSButton *)buttonForLibraryIndex:(int)library;
- (NSViewController *)libraryForIndex:(int)library;

@end

@implementation MNLibrariesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // External Notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectCommandCluster:) name:@"SelectCommandCluster" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectCommand:) name:@"SelectCommand" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectAudioClip:) name:@"SelectSound" object:nil];
        
        // Menu Items
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newSequence:) name:@"NewSequence" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newControlBox:) name:@"NewControlBox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newChannelGroup:) name:@"NewGroup" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newAudioClip:) name:@"NewSound" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newEffectCluster:) name:@"NewEffect" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCommandCluster:) name:@"NewCommandCluster" object:nil];
    }
    
    return self;
}

- (void)awakeFromNib
{
    // Select the sequences tab in the library
    [self displayLibrary:kSequenceLibrary];
}

#pragma mark - Library Managment Methods

- (NSButton *)buttonForLibraryIndex:(int)library
{
    if(library == kSequenceLibrary)
        return sequenceLibraryButton;
    else if(library == kControlBoxLibrary)
        return controlBoxLibraryButton;
    else if(library == kChannelGroupLibrary)
        return channelGroupLibraryButton;
    else if(library == kCommandClusterLibrary)
        return commandClusterLibraryButton;
    else if(library == kEffectClusterLibrary)
        return effectClusterLibraryButton;
    else if(library == kAudioClipLibrary)
        return audioClipLibraryButton;
    
    return nil;
}

- (void)selectLibraryInTabList:(int)library
{
    selectedLibrary = library;
    
    // Toggle the buttons on and off
    for(int i = 0; i < NUMBER_OF_LIBRARIES; i ++)
    {
        // Deselect all other libraries
        if(i != library)
        {
            [[self buttonForLibraryIndex:i] setState:NSOffState];
        }
        // Select the library
        else
        {
            [[self buttonForLibraryIndex:i] setState:NSOnState];
        }
    }
    
    [libraryDataSelectionTableView deselectAll:nil];
//    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
}

- (IBAction)libraryButtonPress:(id)sender
{
    [self displayLibrary:(int)[sender tag]];
}

- (void)removeLibraryContentView:(int)library
{
    //            previouslySelectedRowsInMainTableView[kSequenceLibrary] = (int)[tableView selectedRow];
    [[self libraryForIndex:library].view removeFromSuperview];
}

- (void)addLibraryContentView:(int)library
{
    NSViewController *theLibrary = [self libraryForIndex:library];
    
    [libraryContentScrollView.documentView setFrame:theLibrary.view.frame];
    [libraryContentScrollView.documentView addSubview:theLibrary.view];
    [libraryContentScrollView scrollPoint:NSMakePoint(0, 0)];
    //            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInMainTableView[kSequenceLibrary]] byExtendingSelection:NO];
    //            [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
}

- (NSViewController *)libraryForIndex:(int)library
{
    if(library == kSequenceLibrary)
        return sequenceLibraryManagerViewController;
    else if(library == kControlBoxLibrary)
        return controlBoxLibraryManagerViewController;
    else if(library == kChannelGroupLibrary)
        return channelGroupLibraryManagerViewController;
    else if(library == kCommandClusterLibrary)
        return commandClusterLibraryManagerViewController;
    else if(library == kEffectClusterLibrary)
        return effectClusterLibraryManagerViewController;
    else if(library == kAudioClipLibrary)
        return audioClipLibraryManagerViewController;
    
    return nil;
}

- (void)displayLibrary:(int)library
{
    // Remove the old content
    [self removeLibraryContentView:selectedLibrary];
    
    // Select the new tab
    [self selectLibraryInTabList:library];
    
    // Display the new content
    [self addLibraryContentView:selectedLibrary];
    
    // Reload the library selection table view
    [libraryDataSelectionTableView reloadData];
}

- (IBAction)addLibraryDataButtonPress:(id)sender
{
    
}

- (IBAction)deleteLibraryDataButtonPress:(id)sender
{
    
}

#pragma mark - Private Methods

// External Notifications
- (void)selectCommandCluster:(NSNotification *)aNotification
{
    
}

- (void)selectCommand:(NSNotification *)aNotification
{
    
}

- (void)selectAudioClip:(NSNotification *)aNotification
{
    
}

// Menu Items
- (void)newSequence:(NSNotification *)aNotification
{
    
}

- (void)newControlBox:(NSNotification *)aNotification
{
    
}

- (void)newChannelGroup:(NSNotification *)aNotification
{
    
}

- (void)newAudioClip:(NSNotification *)aNotification
{
    
}

- (void)newEffectCluster:(NSNotification *)aNotification
{
    
}

- (void)newCommandCluster:(NSNotification *)aNotification
{
    
}

@end
