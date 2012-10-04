//
//  MNAppDelegate.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MNData.h"
#import "MNTimelineViewController.h"
#import "MNCommandClusterEditorViewController.h"
#import "MNLibrariesViewController.h"
#import "MNToolbarViewController.h"

@interface MNAppDelegate : NSObject <NSApplicationDelegate>
{
    MNData *data;
    
    IBOutlet MNTimelineViewController *timelineViewController;
    IBOutlet MNCommandClusterEditorViewController *commandClusterEditorViewController;
    IBOutlet MNLibrariesViewController *librariesViewController;
    IBOutlet MNToolbarViewController *toolbarViewController;
}

@property (assign) IBOutlet NSWindow *window;
@property(readwrite, strong) MNData *data;

// Menu Items
- (IBAction)newSequence:(id)sender;
- (IBAction)newControlBox:(id)sender;
- (IBAction)newChannelGroup:(id)sender;
- (IBAction)newCommandCluster:(id)sender;
- (IBAction)newEffectCluster:(id)sender;
- (IBAction)newAudioClip:(id)sender;

@end
