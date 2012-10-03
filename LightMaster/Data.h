//
//  Data.h
//  LightMaster
//
//  Created by James Adams on 12/4/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// See 'Data Model Description'

#define PIXEL_TO_ZOOM_RATIO 1000

@interface Data : NSObject
{
    NSMutableDictionary *sequenceLibrary;
    NSMutableDictionary *controlBoxLibrary;
    NSMutableDictionary *commandClusterLibrary;
    NSMutableDictionary *soundLibrary;
    NSMutableDictionary *groupLibrary;
    NSMutableDictionary *effectLibrary;
    
    NSString *libraryFolder;
    
    NSMutableDictionary *currentSequence;
    float currentTime;
    float timeAtLeftEdgeOfTimelineView;
    float zoomLevel; // 0.01 = no zoom, 1.0 = full zoom
    BOOL currentTimeMarkerIsSelected;
}

@property(readonly) NSString *libraryFolder;
@property(readwrite, strong) NSMutableDictionary *currentSequence;
@property(readwrite) float currentTime;
@property(readwrite) float timeAtLeftEdgeOfTimelineView;
@property(readwrite) float zoomLevel;
@property(readwrite) BOOL currentTimeMarkerIsSelected;

//#pragma mark - Other Methods
- (int)timeToX:(float)time;
- (float)xToTime:(int)x;
- (int)widthForTimeInterval:(float)timeInterval;

//#pragma mark - Sequence Library Methods
// Getter Methods
- (float)versionNumberForSequenceLibrary;
- (NSMutableArray *)sequenceFilePaths;
- (NSString *)sequenceFilePathAtIndex:(int)index;
- (int)sequenceFilePathsCount;

// Setter Methods
- (void)setVersionNumberForSequenceLibraryTo:(float)newVersionNumber;
- (void)addSequenceFilePathToSequenceLibrary:(NSString *)filePath;

//#pragma mark - Sequence Methods
// Getter Methods
- (float)versionNumberForSequence:(NSMutableDictionary *)sequence;
- (NSString *)filePathForSequence:(NSMutableDictionary *)sequence;
- (NSMutableDictionary *)sequenceFromFilePath:(NSString *)filePath;
- (NSString *)descriptionForSequence:(NSMutableDictionary *)sequence;
- (float)startTimeForSequence:(NSMutableDictionary *)sequence;
- (float)endTimeForSequence:(NSMutableDictionary *)sequence;
- (NSMutableArray *)soundFilePathsForSequence:(NSMutableDictionary *)sequence;
- (int)soundFilePathsCountForSequence:(NSMutableDictionary *)sequence;
- (NSString *)soundFilePathAtIndex:(int)index forSequence:(NSMutableDictionary *)sequence;
- (NSMutableArray *)controlBoxFilePathsForSequence:(NSMutableDictionary *)sequence;
- (int)controlBoxFilePathsCountForSequence:(NSMutableDictionary *)sequence;
- (NSString *)controlBoxFilePathAtIndex:(int)index forSequence:(NSMutableDictionary *)sequence;
- (NSMutableArray *)groupFilePathsForSequence:(NSMutableDictionary *)sequence;
- (int)groupFilePathsCountForSequence:(NSMutableDictionary *)sequence;
- (NSString *)groupFilePathAtIndex:(int)index forSequence:(NSMutableDictionary *)sequence;
- (NSMutableArray *)commandClusterFilePathsForSequence:(NSMutableDictionary *)sequence;
- (int)commandClusterFilePathsCountForSequence:(NSMutableDictionary *)sequence;
- (NSString *)commandClusterFilePathAtIndex:(int)index forSequence:(NSMutableDictionary *)sequence;

// Setter Methods
- (void)setVersionNumber:(float)newVersionNumber forSequence:(NSMutableDictionary *)sequence;
- (NSString *)createSequenceAndReturnFilePath;
- (NSString *)createCopyOfSequenceAndReturnFilePath:(NSMutableDictionary *)sequence;
- (void)removeSequenceFromLibrary:(NSMutableDictionary *)sequence;
- (void)setDescription:(NSString *)description forSequence:(NSMutableDictionary *)sequence;
- (void)setStartTime:(float)startTIme forSequence:(NSMutableDictionary *)sequence;
- (void)setEndTime:(float)endTime forSequence:(NSMutableDictionary *)sequence;
- (void)addSoundFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;
- (void)removeSoundFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;
- (void)addControlBoxFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;
- (void)removeControlBoxFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;
- (void)addGroupFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;
- (void)removeGroupFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;
- (void)addCommandClusterFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;
- (void)removeCommandClusterFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;

//#pragma mark - ControlBox Library Methods
// Getter Methods
- (float)versionNumberForControlBoxLibrary;
- (NSMutableArray *)controlBoxFilePaths;
- (NSString *)controlBoxFilePathAtIndex:(int)index;
- (int)controlBoxFilePathsCount;

// Setter Methods
- (void)setVersionNumberForControlBoxLibraryTo:(float)newVersionNumber;
- (void)addControlBoxFilePathToControlBoxLibrary:(NSString *)filePath;

//#pragma mark - ControlBox Methods
// Getter Methods
- (float)versionNumberForControlBox:(NSMutableDictionary *)controlBox;
- (NSString *)filePathForControlBox:(NSMutableDictionary *)controlBox;
- (NSMutableDictionary *)controlBoxFromFilePath:(NSString *)filePath;
- (NSString *)controlBoxIDForControlBox:(NSMutableDictionary *)controlBox;
- (NSString *)descriptionForControlBox:(NSMutableDictionary *)controlBox;
- (NSMutableArray *)controlBoxBeingUsedInSequenceFilePaths:(NSMutableDictionary *)controlBox;
- (int)controlBoxBeingUsedInSequenceFilePathsCount:(NSMutableDictionary *)controlBox;
- (NSString *)controlBox:(NSMutableDictionary *)controlBox beingUsedInSequenceFilePathAtIndex:(int)index;
- (NSMutableArray *)channelsForControlBox:(NSMutableDictionary *)controlBox;
- (int)channelsCountForControlBox:(NSMutableDictionary *)controlBox;
- (NSMutableDictionary *)channelAtIndex:(int)index forControlBox:(NSMutableDictionary *)controlBox;
- (NSNumber *)numberForChannel:(NSMutableDictionary *)channel;
- (NSString *)colorForChannel:(NSMutableDictionary *)channel;
- (NSString *)descriptionForChannel:(NSMutableDictionary *)channel;

// Setter Methods
- (void)setVersionNumber:(float)newVersionNumber forControlBox:(NSMutableDictionary *)controlBox;
- (NSString *)createControlBoxAndReturnFilePath;
- (NSString *)createCopyOfControlBoxAndReturnFilePath:(NSMutableDictionary *)controlBox;
- (void)removeControlBoxFromLibrary:(NSMutableDictionary *)controlBox;
- (void)setControlBoxID:(NSString *)ID forControlBox:(NSMutableDictionary *)controlBox;
- (void)setDescription:(NSString *)description forControlBox:(NSMutableDictionary *)controlBox;
- (int)addChannelAndReturnNewChannelIndexForControlBox:(NSMutableDictionary *)controlBox;
- (void)removeChannel:(NSMutableDictionary *)channel forControlBox:(NSMutableDictionary *)controlBox;
- (void)setNumber:(int)number forChannelAtIndex:(int)index whichIsPartOfControlBox:(NSMutableDictionary *)controlBox;
- (void)setColor:(NSString *)color forChannelAtIndex:(int)index whichIsPartOfControlBox:(NSMutableDictionary *)controlBox;
- (void)setDescription:(NSString *)description forChannelAtIndex:(int)index whichIsPartOfControlBox:(NSMutableDictionary *)controlBox;


//#pragma mark - CommandClusterLibrary Methods
// Getter Methods
- (float)versionNumberForCommandClusterLibrary;
- (NSMutableArray *)commandClusterFilePaths;
- (NSString *)commandClusterFilePathAtIndex:(int)index;
- (int)commandClusterFilePathsCount;

// Setter Methods
- (void)setVersionNumberForCommandClusterLibraryTo:(float)newVersionNumber;
- (void)addCommandClusterFilePathToCommandClusterLibrary:(NSString *)filePath;

//#pragma mark - CommandCluster Methods
// Getter Methods
- (float)versionNumberForCommandCluster:(NSMutableDictionary *)commandCluster;
- (NSString *)filePathForCommandCluster:(NSMutableDictionary *)commandCluster;
- (NSMutableDictionary *)commandClusterFromFilePath:(NSString *)filePath;
- (NSString *)descriptionForCommandCluster:(NSMutableDictionary *)commandCluster;
- (NSMutableArray *)commandClusterBeingUsedInSequenceFilePaths:(NSMutableDictionary *)commandCluster;
- (int)commandClusterBeingUsedInSequenceFilePathsCount:(NSMutableDictionary *)commandCluster;
- (NSString *)commandCluster:(NSMutableDictionary *)commandCluster beingUsedInSequenceFilePathAtIndex:(int)index;
- (NSString *)controlBoxFilePathForCommandCluster:(NSMutableDictionary *)commandCluster;
- (NSString *)groupFilePathForCommandCluster:(NSMutableDictionary *)commandCluster;
- (float)startTimeForCommandCluster:(NSMutableDictionary *)commandCluster;
- (float)endTimeForCommandCluster:(NSMutableDictionary *)commandCluster;
- (NSMutableArray *)commandsFromCommandCluster:(NSMutableDictionary *)commandCluster;
- (int)commandsCountForCommandCluster:(NSMutableDictionary *)commandCluster;
- (NSMutableDictionary *)commandAtIndex:(int)index fromCommandCluster:(NSMutableDictionary *)commandCluster;
- (float)startTimeForCommand:(NSMutableDictionary *)command;
- (float)endTimeForCommand:(NSMutableDictionary *)command;
- (int)channelIndexForCommand:(NSMutableDictionary *)command;
- (int)brightnessForCommand:(NSMutableDictionary *)command;
- (float)fadeInDurationForCommand:(NSMutableDictionary *)command;
- (float)fadeOutDurationForCommand:(NSMutableDictionary *)command;

// Setter Methods
- (void)setVersionNumber:(float)newVersionNumber forCommandCluster:(NSMutableDictionary *)commandCluster;
- (NSString *)createCommandClusterAndReturnFilePath;
- (NSString *)createCopyOfCommandClusterAndReturnFilePath:(NSMutableDictionary *)commandCluster;
- (void)removeCommandClusterFromLibrary:(NSMutableDictionary *)commandCluster;
- (void)setDescription:(NSString *)description forCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setControlBoxFilePath:(NSString *)filePath forCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setGroupFilePath:(NSString *)filePath forCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setStartTime:(float)time forCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setEndTime:(float)time forCommandcluster:(NSMutableDictionary *)commandCluster;
- (void)moveCluster:(NSMutableDictionary *)commandCluster byTime:(float)time;
- (int)createCommandAndReturnNewCommandIndexForCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)removeCommand:(NSMutableDictionary *)command fromCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setStartTime:(float)time forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setEndTime:(float)time forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)moveCommandAtIndex:(int)index byTime:(float)time whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setChannelIndex:(int)channelIndex forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setBrightness:(int)brightness forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setFadeInDuration:(int)fadeInDuration forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setFadeOutDuration:(int)fadeOutDuration forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;

//#pragma mark - SoundLibrary Methods
// Getter Methods
- (float)soundLibraryVersionNumber;
- (NSMutableArray *)soundFilePaths;
- (NSString *)soundFilePathAtIndex:(int)index;
- (int)soundFilePathsCount;

// Setter Methods
- (void)setVersionNumberForSoundLibraryTo:(float)newVersionNumber;
- (void)addSoundFilePathToSoundLibrary:(NSString *)filePath;

//#pragma mark - Sound Methods
// Getter Methods
- (float)versionNumberForSound:(NSMutableDictionary *)sound;
- (NSString *)filePathForSound:(NSMutableDictionary *)sound;
- (NSString *)descriptionForSound:(NSMutableDictionary *)sound;
- (NSMutableArray *)soundBeingUsedInSequenceFilePaths:(NSMutableDictionary *)sound;
- (int)soundBeingUsedInSequenceFilePathsCount:(NSMutableDictionary *)sound;
- (NSString *)sound:(NSMutableDictionary *)sound beingUsedInSequenceFilePathAtIndex:(int)index;
- (NSMutableDictionary *)soundFromFilePath:(NSString *)filePath;
- (NSString *)filePathToAudioFileForSound:(NSMutableDictionary *)sound;
- (float)startTimeForSound:(NSMutableDictionary *)sound;
- (float)endTimeForSound:(NSMutableDictionary *)sound;

// Setter Methods
- (void)setVersionNumber:(float)newVersionNumber forSound:(NSMutableDictionary *)sound;
- (NSString *)createSoundAndReturnFilePath;
- (NSString *)createCopyOfSoundAndReturnFilePath:(NSMutableDictionary *)sound;
- (void)setDescription:(NSString *)description forSound:(NSMutableDictionary *)sound;
- (void)removeSoundFromLibrary:(NSMutableDictionary *)sound;
- (void)setFilePathToAudioFile:(NSString *)filePath forSound:(NSMutableDictionary *)sound;
- (void)setStartTime:(float)time forSound:(NSMutableDictionary *)sound;
- (void)setEndTime:(float)time forSound:(NSMutableDictionary *)sound;

//#pragma mark - GroupLibrary Methods
// Getter Methods
- (float)groupLibraryVersionNumber;
- (NSMutableArray *)groupFilePaths;
- (NSString *)groupFilePathAtIndex:(int)index;
- (int)groupFilePathsCount;

// Setter Methods
- (void)setVersionNumberForGroupLibraryTo:(float)newVersionNumber;
- (void)addGroupFilePathToGroupLibrary:(NSString *)filePath;

//#pragma mark - Group Methods
// Getter Methods
- (float)versionNumberForGroup:(NSMutableDictionary *)group;
- (NSString *)filePathForGroup:(NSMutableDictionary *)group;
- (NSMutableDictionary *)groupFromFilePath:(NSString *)filePath;
- (NSString *)descriptionForGroup:(NSMutableDictionary *)group;
- (NSMutableArray *)groupBeingUsedInSequenceFilePaths:(NSMutableDictionary *)group;
- (int)groupBeingUsedInSequenceFilePathsCount:(NSMutableDictionary *)group;
- (NSString *)group:(NSMutableDictionary *)group beingUsedInSequenceFilePathAtIndex:(int)index;
- (NSMutableArray *)itemsForGroup:(NSMutableDictionary *)group;
- (int)itemsCountForGroup:(NSMutableDictionary *)group;
- (NSMutableDictionary *)itemDataAtIndex:(int)index forGroup:(NSMutableDictionary *)group;
- (NSString *)controlBoxFilePathForItemData:(NSMutableDictionary *)itemData;
- (int)channelIndexForItemData:(NSMutableDictionary *)itemData;

// Setter Methods
- (void)setVersionNumber:(float)newVersionNumber forGroup:(NSMutableDictionary *)group;
- (NSString *)createGroupAndReturnFilePath;
- (NSString *)createCopyOfGroupAndReturnFilePath:(NSMutableDictionary *)group;
- (void)removeGroupFromLibrary:(NSMutableDictionary *)group;
- (void)setDescription:(NSString *)description forGroup:(NSMutableDictionary *)group;
- (int)createItemDataAndReturnNewItemIndexForGroup:(NSMutableDictionary *)group;
- (void)removeItemData:(NSMutableDictionary *)itemData forGroup:(NSMutableDictionary *)group;
- (void)setControlBoxFilePath:(NSString *)filePath forItemDataAtIndex:(int)index whichIsPartOfGroup:(NSMutableDictionary *)group;
- (void)setChannelIndex:(int)channelIndex forItemDataAtIndex:(int)index whichIsPartOfGroup:(NSMutableDictionary *)group;

//#pragma mark - EffectLibrary Methods
// Getter Methods
- (float)versionNumberForEffectLibrary;
- (NSMutableArray *)effectFilePaths;
- (NSString *)effectFilePathAtIndex:(int)index;
- (int)effectFilePathsCount;

// Setter Methods
- (void)setVersionNumberForEffectLibraryTo:(float)newVersionNumber;
- (void)addEffectFilePathToEffectLibrary:(NSString *)filePath;

//#pragma mark - Effect Methods
// Getter Methods
- (float)versionNumberforEffect:(NSMutableDictionary *)effect;
- (NSString *)filePathForEffect:(NSMutableDictionary *)effect;
- (NSMutableDictionary *)effectFromFilePath:(NSString *)filePath;
- (NSString *)descriptionForEffect:(NSMutableDictionary *)effect;
- (NSString *)parametersForEffect:(NSMutableDictionary *)effect;
- (NSString *)scriptForEffect:(NSMutableDictionary *)effect;

// Setter Methods
- (void)setVersionNumber:(float)newVersionNumber forEffect:(NSMutableDictionary *)effect;
- (NSString *)createEffectAndReturnFilePath;
- (NSString *)createCopyOfEffectAndReturnFilePath:(NSMutableDictionary *)effect;
- (void)removeEffectFromLibrary:(NSMutableDictionary *)effect;
- (void)setDescription:(NSString *)description forEffect:(NSMutableDictionary *)effect;
- (void)setParameters:(NSString *)parameters forEffect:(NSMutableDictionary *)effect;
- (void)setScript:(NSString *)script forEffect:(NSMutableDictionary *)effect;

@end
