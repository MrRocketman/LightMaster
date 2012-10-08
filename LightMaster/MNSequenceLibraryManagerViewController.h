//
//  MNSequenceLibraryManagerViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MNSequenceLibraryManagerViewController : NSViewController
{
    NSMutableDictionary __weak *sequence;
}

@property(readwrite, weak) NSMutableDictionary *sequence;

@end
