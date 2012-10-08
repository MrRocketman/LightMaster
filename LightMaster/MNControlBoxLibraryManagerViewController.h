//
//  MNControlBoxLibraryManagerViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MNControlBoxLibraryManagerViewController : NSViewController
{
    NSMutableDictionary __weak *controlBox;
}

@property(readwrite, weak) NSMutableDictionary *controlBox;

@end
