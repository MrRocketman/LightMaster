//
//  MNSynchronizedScrollView.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MNSynchronizedScrollView : NSScrollView
{
    NSScrollView *__weak synchronizedScrollView; // not retained
}

@property(readwrite, weak, nonatomic) IBOutlet NSScrollView *synchronizedScrollView;
//Scroll synchronization methods
- (void)stopSynchronizing;
- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification;

@end