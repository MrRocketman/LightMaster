//
//  MNAppDelegate.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNAppDelegate.h"

@implementation MNAppDelegate

@synthesize data;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
//    timelineViewController = [[MNTimelineViewController alloc] init];
//    commandClusterEditorViewController = [[MNCommandClusterEditorViewController alloc] init];
//    librariesViewController = [[MNLibrariesViewController alloc] init];
//    toolbarViewController = [[MNToolbarViewController alloc] init];
}

#pragma mark - Menu Items

- (IBAction)newSequence:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewSequence" object:nil userInfo:nil];
}

- (IBAction)newControlBox:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewControlBox" object:nil userInfo:nil];
}

- (IBAction)newChannelGroup:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewChanelGroup" object:nil userInfo:nil];
}

- (IBAction)newCommandCluster:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewCommandCluster" object:nil userInfo:nil];
}

- (IBAction)newEffectCluster:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewEffectCluster" object:nil userInfo:nil];
}

- (IBAction)newAudioClip:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewAudioClip" object:nil userInfo:nil];
}

@end
