//
//  MNAppDelegate.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "MNData.h"
#include "MNTimelineViewController.h"
#include "MNCommandClusterEditorViewController.h"
#include "MNLibrariesViewController.h"
#include "MNToolbarViewController.h"

@interface MNAppDelegate : NSObject <NSApplicationDelegate>
{
    MNData *data;
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
