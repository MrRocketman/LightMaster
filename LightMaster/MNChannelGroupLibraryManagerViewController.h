//
//  MNChannelGroupLibraryManagerViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MNChannelGroupLibraryManagerViewController : NSViewController
{
    NSMutableDictionary __weak *channelGroup;
}

@property(readwrite, weak) NSMutableDictionary *channelGroup;

@end
