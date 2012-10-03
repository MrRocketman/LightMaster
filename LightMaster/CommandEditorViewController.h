//
//  CommandEditorViewController.h
//  LightMaster
//
//  Created by James Adams on 12/4/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Data.h"

@interface CommandEditorViewController : NSViewController
{
    Data *__weak data;
}

@property(readwrite, weak) Data *data;

- (void)prepareForDisplay;

@end
