//
//  MNLibrariesViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNLibrariesViewController.h"

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

- (void)selectLibraryInTabList:(int)library;
- (IBAction)libraryButtonPress:(id)sender;
- (NSButton *)buttonForLibraryIndex:(int)library;

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
    
//    [tableView deselectAll:nil];
//    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
}

- (IBAction)libraryButtonPress:(id)sender
{
    [self displayLibrary:(int)[sender tag]];
}

- (void)displayLibrary:(int)library
{
    [self selectLibraryInTabList:library];
    
    // Remove the old view
    /*switch (selectedLibrary)
    {
        case kControlBoxLibrary:
            previouslySelectedRowsInMainTableView[kControlBoxLibrary] = (int)[tableView selectedRow];
            [controlBoxDetailScrollView removeFromSuperview];
            break;
        case kCommandClusterLibrary:
            previouslySelectedRowsInMainTableView[kCommandClusterLibrary] = (int)[tableView selectedRow];
            [commandClusterDetailScrollView removeFromSuperview];
            break;
        case kEffectLibrary:
            previouslySelectedRowsInMainTableView[kEffectLibrary] = (int)[tableView selectedRow];
            [effectDetailScrollView removeFromSuperview];
            break;
        case kSoundLibrary:
            previouslySelectedRowsInMainTableView[kSoundLibrary] = (int)[tableView selectedRow];
            [soundDetailsScrollView removeFromSuperview];
            break;
        case kGroupLibrary:
            previouslySelectedRowsInMainTableView[kGroupLibrary] = (int)[tableView selectedRow];
            [groupDetailScrollView removeFromSuperview];
            break;
        case kSequenceLibrary:
            previouslySelectedRowsInMainTableView[kSequenceLibrary] = (int)[tableView selectedRow];
            [sequenceDetailScrollView removeFromSuperview];
            break;
        default:
            break;
    }
    
    // Toggle the buttons and set the new selcted library
    [self toggleButtonsOffBesides:sender];
    [tableView reloadData];
    
    // Add the new library
    NSRect newFrame = NSMakeRect(0, 0, detailViewWell.frame.size.width, detailViewWell.frame.size.height);
    switch (selectedLibrary)
    {
        case kControlBoxLibrary:
            [controlBoxDetailScrollView setFrame:newFrame];
            [detailViewWell addSubview:controlBoxDetailScrollView];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInMainTableView[kControlBoxLibrary]] byExtendingSelection:NO];
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
            break;
        case kCommandClusterLibrary:
            [commandClusterDetailScrollView setFrame:newFrame];
            [detailViewWell addSubview:commandClusterDetailScrollView];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInMainTableView[kCommandClusterLibrary]] byExtendingSelection:NO];
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
            break;
        case kEffectLibrary:
            [effectDetailScrollView setFrame:newFrame];
            [detailViewWell addSubview:effectDetailScrollView];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInMainTableView[kEffectLibrary]] byExtendingSelection:NO];
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
            break;
        case kSoundLibrary:
            [soundDetailsScrollView setFrame:newFrame];
            [detailViewWell addSubview:soundDetailsScrollView];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInMainTableView[kSoundLibrary]] byExtendingSelection:NO];
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
            break;
        case kGroupLibrary:
            [groupDetailScrollView setFrame:newFrame];
            [detailViewWell addSubview:groupDetailScrollView];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInMainTableView[kGroupLibrary]] byExtendingSelection:NO];
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
            break;
        case kSequenceLibrary:
            [sequenceDetailScrollView setFrame:newFrame];
            [detailViewWell addSubview:sequenceDetailScrollView];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInMainTableView[kSequenceLibrary]] byExtendingSelection:NO];
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
            break;
        default:
            break;
    }*/
}

- (IBAction)addLibraryDateButtonPress:(id)sender
{
    
}

- (IBAction)deleteLibraryDateButtonPress:(id)sender
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
