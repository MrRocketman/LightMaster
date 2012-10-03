//
//  SynchronizedScrollView.h
//  
//
//  Created by James Adams on 12/16/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SynchronizedScrollView : NSScrollView 
{
    NSScrollView *__weak synchronizedScrollView; // not retained
}

@property(readwrite, weak, nonatomic) IBOutlet NSScrollView *synchronizedScrollView;
//Scroll synchronization methods
- (void)stopSynchronizing;
- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification;

@end
