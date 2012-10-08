//
//  MNCommandClusterLibraryManagerViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MNCommandClusterLibraryManagerViewController : NSViewController
{
    NSMutableDictionary __weak *commandCluster;
}

@property(readwrite, weak) NSMutableDictionary *commandCluster;

@end
