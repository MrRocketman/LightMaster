//
//  MNData.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ORSSerialPort.h"
#import "ORSSerialPortManager.h"
#import "ENAPIPostRequest.h"
#import "ENAPIRequest.h"

// See 'MNData_Model_Description'

// This is how many pixels per second there are are a zoom level of 1
#define PIXEL_TO_ZOOM_RATIO 25
#define setBit(var, mask)   ((var) |= (uint16_t)(1 << mask))
#define clearBit(var, mask)   ((var) &= (uint16_t)~(1 << mask))

enum
{
    MNMouseDown,
    MNMouseDragged,
    MNMouseUp
};

enum
{
    MNBeat,
    MNTatum,
    MNSegment
};

@interface MNData : NSObject <ORSSerialPortDelegate, ENAPIPostRequestDelegate, ENAPIRequestDelegate>
{
    NSMutableDictionary *sequenceLibrary;
    NSMutableDictionary *controlBoxLibrary;
    NSMutableDictionary *commandClusterLibrary;
    NSMutableDictionary *audioClipLibrary;
    NSMutableDictionary *channelGroupLibrary;
    NSMutableDictionary *effectLibrary;
    
    NSString *libraryFolder;
    NSMutableDictionary *currentSequence;
    NSMutableArray *currentSequenceNSSounds;
    NSMutableArray *currentSequenceControlBoxes;
    NSMutableArray *currentSequenceCommandClusters;
    NSMutableArray *currentSequenceAudioClips;
    NSMutableArray *currentSequenceAudioAnalyses;
    NSMutableArray *currentSequenceChannelGroups;
    float currentTime;
    float timeAtLeftEdgeOfTimelineView;
    float zoomLevel; // 1.0 = no zoom, 10 = 10x zoom
    BOOL currentSequenceIsPlaying;
    BOOL loop;
    int mostRecentlySelectedCommandClusterIndex;
    
    ORSSerialPort *serialPort;
    ORSSerialPortManager *serialPortManager;
    BOOL previousChannelState[256][256]; // This represents all of the channels. They are accessed as follows: [controlBoxIndex][channelIndex]
    BOOL channelState[256][256]; // This represents all of the channels. They are accessed as follows: [controlBoxIndex][channelIndex]
    
    NSOpenPanel *openPanel;
    NSString *previousOpenPanelDirectory;
    
    int playlistIndexes[999];
    int numberOfPlaylistSongs;
    int currentPlaylistIndex;
    
    NSMutableArray *enRequests;
    BOOL shouldDrawSections;
    BOOL shouldDrawBars;
    BOOL shouldDrawBeats;
    BOOL shouldDrawTatums;
    BOOL shouldDrawSegments;
    BOOL shouldDrawTime;
    
    NSSound *emptySound;
    
    float autogenIntensity; // Must be between 0 and 1.0
    BOOL shouldAutosave;
}

@property() NSString *libraryFolder;
@property(strong) NSMutableDictionary *currentSequence;
@property() float currentTime;
@property() float timeAtLeftEdgeOfTimelineView;
@property() float zoomLevel;
@property() BOOL currentSequenceIsPlaying;
@property() int mostRecentlySelectedCommandClusterIndex;
@property() ORSSerialPort *serialPort;
@property() ORSSerialPortManager *serialPortManager;
@property() BOOL shouldDrawSections;
@property() BOOL shouldDrawBars;
@property() BOOL shouldDrawBeats;
@property() BOOL shouldDrawTatums;
@property() BOOL shouldDrawSegments;
@property() BOOL shouldDrawTime;
@property() float autogenIntensity;

#pragma mark - Other Methods
// Other Methods
- (int)timeToX:(float)time; // Converts the time to a zoom factored x coordinate
- (float)xToTime:(int)x;
- (int)widthForTimeInterval:(float)timeInterval;
- (int)trackItemsCount;
- (void)convertRBCFile;
- (void)loadOpenPanel;
- (void)playPlaylistOfSequenceIndexes:(NSUInteger *)indexes indexCount:(int)count;
- (void)playNextPlaylistItem;
- (void)stopPlaylist;
- (void)autogenCurrentSequence; // Uses loudness to determine number of channels to use. Randomly creates commands. Assigns boxes to either beats, tatums, or segments for duration of song.
- (void)autogenv2ForCurrentSequence;
// Quick access to data
- (NSMutableDictionary *)controlBoxForCurrentSequenceAtIndex:(int)i;
- (NSMutableDictionary *)commandClusterForCurrentSequenceAtIndex:(int)i;
- (NSMutableDictionary *)audioClipForCurrentSequenceAtIndex:(int)i;
- (NSDictionary *)audioAnalysisForCurrentSequenceAtIndex:(int)i;
- (NSMutableDictionary *)channelGroupForCurrentSequenceAtIndex:(int)i;
// File Name Methods
- (NSString *)nextAvailableSequenceFileName;
- (NSString *)nextAvailableControlBoxFileName;
- (NSString *)nextAvailableCommandClusterFileName;
- (NSString *)nextAvailableAudioClipFileName;
- (NSString *)nextAvailableChannelGroupFileName;
- (NSString *)nextAvailableEffectFileName;
- (void)setFilePath:(NSString *)filePath forDictionary:(NSMutableDictionary *)dictionary;

#pragma mark - SerialPort

- (void)sendStringToSerialPort:(NSString *)text;

#pragma mark - Sequence Library Methods
// Management Methods
- (NSString *)createSequenceAndReturnFilePath;
- (NSString *)createCopyOfSequenceAndReturnFilePath:(NSMutableDictionary *)sequence;
- (void)removeSequenceFromLibrary:(NSMutableDictionary *)sequence;

// Getter Methods
- (float)versionNumberForSequenceLibrary;
- (NSMutableArray *)sequenceFilePaths;
- (NSString *)sequenceFilePathAtIndex:(int)index;
- (int)sequenceFilePathsCount;

// Setter Methods
- (void)setVersionNumberForSequenceLibraryTo:(float)newVersionNumber;
- (void)addSequenceFilePathToSequenceLibrary:(NSString *)filePath;

#pragma mark - Sequence Methods
// Getter Methods
- (float)versionNumberForSequence:(NSMutableDictionary *)sequence;
- (NSString *)filePathForSequence:(NSMutableDictionary *)sequence;
- (NSMutableDictionary *)sequenceFromFilePath:(NSString *)filePath;
- (NSString *)descriptionForSequence:(NSMutableDictionary *)sequence;
- (float)startTimeForSequence:(NSMutableDictionary *)sequence;
- (float)endTimeForSequence:(NSMutableDictionary *)sequence;
- (NSMutableArray *)audioClipFilePathsForSequence:(NSMutableDictionary *)sequence;
- (int)audioClipFilePathsCountForSequence:(NSMutableDictionary *)sequence;
- (NSString *)audioClipFilePathAtIndex:(int)index forSequence:(NSMutableDictionary *)sequence;
- (NSMutableArray *)controlBoxFilePathsForSequence:(NSMutableDictionary *)sequence;
- (int)controlBoxFilePathsCountForSequence:(NSMutableDictionary *)sequence;
- (NSString *)controlBoxFilePathAtIndex:(int)index forSequence:(NSMutableDictionary *)sequence;
- (NSMutableArray *)channelGroupFilePathsForSequence:(NSMutableDictionary *)sequence;
- (int)channelGroupFilePathsCountForSequence:(NSMutableDictionary *)sequence;
- (NSString *)channelGroupFilePathAtIndex:(int)index forSequence:(NSMutableDictionary *)sequence;
- (NSMutableArray *)commandClusterFilePathsForSequence:(NSMutableDictionary *)sequence;
- (int)commandClusterFilePathsCountForSequence:(NSMutableDictionary *)sequence;
- (NSString *)commandClusterFilePathAtIndex:(int)index forSequence:(NSMutableDictionary *)sequence;

// Setter Methods
- (void)setVersionNumber:(float)newVersionNumber forSequence:(NSMutableDictionary *)sequence;
- (void)setDescription:(NSString *)description forSequence:(NSMutableDictionary *)sequence;
- (void)setStartTime:(float)startTIme forSequence:(NSMutableDictionary *)sequence;
- (void)setEndTime:(float)endTime forSequence:(NSMutableDictionary *)sequence;
- (void)addAudioClipFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;
- (void)removeAudioClipFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;
- (void)addControlBoxFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;
- (void)removeControlBoxFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;
- (void)addChannelGroupFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;
- (void)removeChannelGroupFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;
- (void)addCommandClusterFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;
- (void)removeCommandClusterFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence;

#pragma mark - ControlBox Library Methods
// Management Methods
- (NSString *)createControlBoxAndReturnFilePath;
- (NSString *)createCopyOfControlBoxAndReturnFilePath:(NSMutableDictionary *)controlBox;
- (void)removeControlBoxFromLibrary:(NSMutableDictionary *)controlBox;

// Getter Methods
- (float)versionNumberForControlBoxLibrary;
- (NSMutableArray *)controlBoxFilePaths;
- (NSString *)controlBoxFilePathAtIndex:(int)index;
- (int)controlBoxFilePathsCount;

// Setter Methods
- (void)setVersionNumberForControlBoxLibraryTo:(float)newVersionNumber;
- (void)addControlBoxFilePathToControlBoxLibrary:(NSString *)filePath;

#pragma mark - ControlBox Methods
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
- (void)setControlBoxID:(NSString *)ID forControlBox:(NSMutableDictionary *)controlBox;
- (void)setDescription:(NSString *)description forControlBox:(NSMutableDictionary *)controlBox;
- (int)addChannelAndReturnNewChannelIndexForControlBox:(NSMutableDictionary *)controlBox;
- (void)removeChannel:(NSMutableDictionary *)channel forControlBox:(NSMutableDictionary *)controlBox;
- (void)setNumber:(int)number forChannelAtIndex:(int)index whichIsPartOfControlBox:(NSMutableDictionary *)controlBox;
- (void)setColor:(NSString *)color forChannelAtIndex:(int)index whichIsPartOfControlBox:(NSMutableDictionary *)controlBox;
- (void)setDescription:(NSString *)description forChannelAtIndex:(int)index whichIsPartOfControlBox:(NSMutableDictionary *)controlBox;

#pragma mark - ChannelGroupLibrary Methods
// Managment Methods
- (NSString *)createChannelGroupAndReturnFilePath;
- (NSString *)createCopyOfChannelGroupAndReturnFilePath:(NSMutableDictionary *)channelGroup;
- (void)removeChannelGroupFromLibrary:(NSMutableDictionary *)channelGroup;

// Getter Methods
- (float)channelGroupLibraryVersionNumber;
- (NSMutableArray *)channelGroupFilePaths;
- (NSString *)channelGroupFilePathAtIndex:(int)index;
- (int)channelGroupFilePathsCount;

// Setter Methods
- (void)setVersionNumberForChannelGroupLibraryTo:(float)newVersionNumber;
- (void)addChannelGroupFilePathToChannelGroupLibrary:(NSString *)filePath;

#pragma mark - ChannelGroup Methods
// Getter Methods
- (float)versionNumberForChannelGroup:(NSMutableDictionary *)channelGroup;
- (NSString *)filePathForChannelGroup:(NSMutableDictionary *)channelGroup;
- (NSMutableDictionary *)channelGroupFromFilePath:(NSString *)filePath;
- (NSString *)descriptionForChannelGroup:(NSMutableDictionary *)channelGroup;
- (NSMutableArray *)channelGroupBeingUsedInSequenceFilePaths:(NSMutableDictionary *)channelGroup;
- (int)channelGroupBeingUsedInSequenceFilePathsCount:(NSMutableDictionary *)channelGroup;
- (NSString *)channelGroup:(NSMutableDictionary *)channelGroup beingUsedInSequenceFilePathAtIndex:(int)index;
- (NSMutableArray *)itemsForChannelGroup:(NSMutableDictionary *)channelGroup;
- (int)itemsCountForChannelGroup:(NSMutableDictionary *)channelGroup;
- (NSMutableDictionary *)itemDataAtIndex:(int)index forChannelGroup:(NSMutableDictionary *)channelGroup;
- (NSString *)controlBoxFilePathForItemData:(NSMutableDictionary *)itemData;
- (int)channelIndexForItemData:(NSMutableDictionary *)itemData;

// Setter Methods
- (void)setVersionNumber:(float)newVersionNumber forChannelGroup:(NSMutableDictionary *)channelGroup;
- (void)setDescription:(NSString *)description forChannelGroup:(NSMutableDictionary *)channelGroup;
- (int)createItemDataAndReturnNewItemIndexForChannelGroup:(NSMutableDictionary *)channelGroup;
- (void)removeItemData:(NSMutableDictionary *)itemData forChannelGroup:(NSMutableDictionary *)channelGroup;
- (void)setControlBoxFilePath:(NSString *)filePath forItemDataAtIndex:(int)index whichIsPartOfChannelGroup:(NSMutableDictionary *)channelGroup;
- (void)setChannelIndex:(int)channelIndex forItemDataAtIndex:(int)index whichIsPartOfChannelGroup:(NSMutableDictionary *)channelGroup;

#pragma mark - CommandClusterLibrary Methods
// Management Methods
- (NSString *)createCommandClusterAndReturnFilePath;
- (NSString *)createCopyOfCommandClusterAndReturnFilePath:(NSMutableDictionary *)commandCluster;
- (void)removeCommandClusterFromLibrary:(NSMutableDictionary *)commandCluster;
- (void)splitMostRecentlySelectedCommandClusterAtCurrentTime:(NSNotification *)aNotifcation;
- (int)splitCommandClusterForCurrentSequenceAtIndex:(int)commandClusterIndex atTime:(float)time;

// Getter Methods
- (float)versionNumberForCommandClusterLibrary;
- (NSMutableArray *)commandClusterFilePaths;
- (NSString *)commandClusterFilePathAtIndex:(int)index;
- (int)commandClusterFilePathsCount;

// Setter Methods
- (void)setVersionNumberForCommandClusterLibraryTo:(float)newVersionNumber;
- (void)addCommandClusterFilePathToCommandClusterLibrary:(NSString *)filePath;

#pragma mark - CommandCluster Methods
// Getter Methods
- (float)versionNumberForCommandCluster:(NSMutableDictionary *)commandCluster;
- (NSString *)filePathForCommandCluster:(NSMutableDictionary *)commandCluster;
- (NSMutableDictionary *)commandClusterFromFilePath:(NSString *)filePath;
- (NSString *)descriptionForCommandCluster:(NSMutableDictionary *)commandCluster;
- (NSMutableArray *)commandClusterBeingUsedInSequenceFilePaths:(NSMutableDictionary *)commandCluster;
- (int)commandClusterBeingUsedInSequenceFilePathsCount:(NSMutableDictionary *)commandCluster;
- (NSString *)commandCluster:(NSMutableDictionary *)commandCluster beingUsedInSequenceFilePathAtIndex:(int)index;
- (NSString *)controlBoxFilePathForCommandCluster:(NSMutableDictionary *)commandCluster;
- (NSString *)channelGroupFilePathForCommandCluster:(NSMutableDictionary *)commandCluster;
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
- (void)setDescription:(NSString *)description forCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setControlBoxFilePath:(NSString *)filePath forCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setChannelGroupFilePath:(NSString *)filePath forCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setStartTime:(float)time forCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setEndTime:(float)time forCommandcluster:(NSMutableDictionary *)commandCluster;
- (void)moveCommandCluster:(NSMutableDictionary *)commandCluster byTime:(float)time;
- (void)moveCommandCluster:(NSMutableDictionary *)commandCluster toStartTime:(float)startTime;
- (int)createCommandAndReturnNewCommandIndexForCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)removeCommand:(NSMutableDictionary *)command fromCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setStartTime:(float)time forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setEndTime:(float)time forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)moveCommandAtIndex:(int)index byTime:(float)time whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)moveCommandAtIndex:(int)index toStartTime:(float)startTime whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setChannelIndex:(int)channelIndex forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setBrightness:(int)brightness forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setFadeInDuration:(int)fadeInDuration forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)setFadeOutDuration:(int)fadeOutDuration forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster;

#pragma mark - EffectLibrary Methods
// Management Methods
- (NSString *)createEffectAndReturnFilePath;
- (NSString *)createCopyOfEffectAndReturnFilePath:(NSMutableDictionary *)effect;
- (void)removeEffectFromLibrary:(NSMutableDictionary *)effect;

// Getter Methods
- (float)versionNumberForEffectLibrary;
- (NSMutableArray *)effectFilePaths;
- (NSString *)effectFilePathAtIndex:(int)index;
- (int)effectFilePathsCount;

// Setter Methods
- (void)setVersionNumberForEffectLibraryTo:(float)newVersionNumber;
- (void)addEffectFilePathToEffectLibrary:(NSString *)filePath;

#pragma mark - Effect Methods
// Getter Methods
- (float)versionNumberforEffect:(NSMutableDictionary *)effect;
- (NSString *)filePathForEffect:(NSMutableDictionary *)effect;
- (NSMutableDictionary *)effectFromFilePath:(NSString *)filePath;
- (NSString *)descriptionForEffect:(NSMutableDictionary *)effect;
- (NSString *)parametersForEffect:(NSMutableDictionary *)effect;
- (NSString *)scriptForEffect:(NSMutableDictionary *)effect;

// Setter Methods
- (void)setVersionNumber:(float)newVersionNumber forEffect:(NSMutableDictionary *)effect;
- (void)setDescription:(NSString *)description forEffect:(NSMutableDictionary *)effect;
- (void)setParameters:(NSString *)parameters forEffect:(NSMutableDictionary *)effect;
- (void)setScript:(NSString *)script forEffect:(NSMutableDictionary *)effect;

#pragma mark - AudioClipLibrary Methods
// Management Methods
- (NSString *)createAudioClipAndReturnFilePath;
- (NSString *)createCopyOfAudioClipAndReturnFilePath:(NSMutableDictionary *)audioClip;
- (void)removeAudioClipFromLibrary:(NSMutableDictionary *)audioClip;

// Getter Methods
- (float)audioClipLibraryVersionNumber;
- (NSMutableArray *)audioClipFilePaths;
- (NSString *)audioClipFilePathAtIndex:(int)index;
- (int)audioClipFilePathsCount;

// Setter Methods
- (void)setVersionNumberForAudioClipLibraryTo:(float)newVersionNumber;
- (void)addAudioClipFilePathToAudioClipLibrary:(NSString *)filePath;

#pragma mark - AudioClip Methods
// Getter Methods
- (float)versionNumberForAudioClip:(NSMutableDictionary *)audioClip;
- (NSString *)filePathForAudioClip:(NSMutableDictionary *)audioClip;
- (NSString *)descriptionForAudioClip:(NSMutableDictionary *)audioClip;
- (NSMutableArray *)audioClipBeingUsedInSequenceFilePaths:(NSMutableDictionary *)audioClip;
- (int)audioClipBeingUsedInSequenceFilePathsCount:(NSMutableDictionary *)audioClip;
- (NSString *)audioClip:(NSMutableDictionary *)audioClip beingUsedInSequenceFilePathAtIndex:(int)index;
- (NSMutableDictionary *)audioClipFromFilePath:(NSString *)filePath;
- (NSString *)filePathToAudioFileForAudioClip:(NSMutableDictionary *)audioClip;
- (float)startTimeForAudioClip:(NSMutableDictionary *)audioClip;
- (float)endTimeForAudioClip:(NSMutableDictionary *)audioClip;
- (float)endFadeTimeForAudioClip:(NSMutableDictionary *)audioClip;
- (float)seekTimeForAudioClip:(NSMutableDictionary *)audioClip;
- (float)uploadProgressForAudioClip:(NSMutableDictionary *)audioClip;
- (NSDictionary *)audioSummaryForAudioClip:(NSMutableDictionary *)audioClip;
- (NSDictionary *)audioAnalysisForAudioClip:(NSMutableDictionary *)audioClip;

// Setter Methods
- (void)setVersionNumber:(float)newVersionNumber forAudioClip:(NSMutableDictionary *)audioClip;
- (void)setDescription:(NSString *)description forAudioClip:(NSMutableDictionary *)audioClip;
- (void)setFilePathToAudioFile:(NSString *)filePath forAudioClip:(NSMutableDictionary *)audioClip;
- (void)setStartTime:(float)time forAudioClip:(NSMutableDictionary *)audioClip;
- (void)setEndTime:(float)time forAudioClip:(NSMutableDictionary *)audioClip;
- (void)setEndFadeTime:(float)time forAudioClip:(NSMutableDictionary *)audioClip;
- (void)moveAudioClip:(NSMutableDictionary *)audioClip byTime:(float)time;
- (void)moveAudioClip:(NSMutableDictionary *)audioClip toStartTime:(float)startTime;
- (void)setSeekTime:(float)time forAudioClip:(NSMutableDictionary *)audioClip;
- (void)updateAudioAnalysisForAudioClip:(NSMutableDictionary *)audioClip;
- (void)setUploadProgress:(float)uploadProgress ForAudioClip:(NSMutableDictionary *)audioClip;
- (void)setAudioSummary:(NSDictionary *)audioSummary forAudioClip:(NSMutableDictionary *)audioClip;
- (void)setAudioAnalysis:(NSDictionary *)audioAnalysis forAudioClip:(NSMutableDictionary *)audioClip;

@end
