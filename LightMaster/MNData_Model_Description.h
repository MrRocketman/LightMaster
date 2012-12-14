// All file paths are relative to the  ~/Library/Application\ Support/LightMaster/'specific library' folder!

/************* Data Model ********************
 *sequenceLibrary (NSMutableDictionary)
    *versionNumber (NSNumber)
    *sequenceFilePaths (NSMutableArray)
        *sequenceFilePath (NSString)
 
    *sequence (NSMutableDictionary)
        *versionNumber (NSNumber)
        *filePath (NSString)
        *description (NSString)
        *startTime (NSNumber) float in seconds
        *endTime (NSNumber) float in seconds
        *audioClipFilePaths (NSMutableArray)
        *controlBoxFilePaths (NSMutableArray)
        *channGroupFilePaths (NSMutableArray)
        *commandClusterFilePaths (NSMutableArray)
        *effectFilePaths (NSMutableArray)
 
 
 
 *controlBoxLibrary (NSMutableDictionary)
    *versionNumber (NSNumber)
    *controlBoxFilesPaths (NSMutableArray)
        *controlBoxFilePath (NSString)
 
    *controlBox (NSMutableDictionary)
        *versionNumber (NSNumber)
        *filePath (NSString)
        *beingUsedInSequenceFilePaths (NSMutableArray)
        *controlBoxID (NSString) (the ID that the control box has been programmed to respond to)
        *description (NSString)
        *channels (NSMutableArray)
            *channel (NSMutableDictionary)
                *number (NSNumber)
                *color (NSString) (pop up box)
                *description (NSString)
 
 
 
 *channelGroupLibrary (NSMutableDictionary)
    *versionNumber (NSNumber)
    *channelGroupFilePaths (NSMutableArray)
        *channelGroupFilePath (NSString)
 
    *channelGroup (NSMutableDictionary)
        *versionNumber (NSNumber)
        *filePath (NSString)
        *beingUsedInSequenceFilePaths (NSMutableArray)
        *description (NSString)
        *items (NSMutableArray)
            *itemData (NSMutableDictionary)
                *channelIndex (NSNumber)
                *controlBoxFilePath (NSString)
 
 
 
 *commandClusterLibrary (NSMutableDictionary)
    *versionNumber (NSNumber)
    *commandClusterFilePaths (NSMutableArray)
        *commandClusterFilePath (NSString)
 
    *commandCluster (NSMutableDictionary)
        *versionNumber (NSNumber)
        *filePath (NSString)
        *beingUsedInSequenceFilePaths (NSMutableArray)
        *description (NSString)
        *controlBoxFilePath (NSString)
        *channelGroupFilePath (NSString)
        *startTime (NSNumber) (float in seconds)
        *endTime (NSNumber)
        *commands (NSMutableArray)
            *command (NSMutableDictionary)
                *startTime (NSNumber) (float in seconds)
                *endTime (NSNumber) (float in seconds)
                *channelIndex (NSNumber) (channelIndex can also be though of as itemData index when the command is for a channelGroup, it is the channel number (graphically and the one that gets sent out for the command))
                *brightness (NSNumber) (int 0-100)
                *fadeInDuration (NSNumber) (float in seconds)
                *fadeOutDuration (NSNumber) (float in seconds)
 
 
 
 *effectLibrary (NSMutableDictionary)
    *versionNumber (NSNumber)
    *effectsFilePaths (NSMutableArray)
        *effectFilepath (NSString)
 
    *effect (NSMutableDictionary) - These create command clusters when they are "compiled"
        *versionNumber (NSNumber)
        *filePath (NSString)
        *description (NSString)
        *parameters (NSString)
        *script (NSString)
 
 
 
 *audioClipLibrary (NSMutableDictionary)
    *versionNumber (NSNumber)
    *audioClipFilePaths (NSMutableArray)
        *audioClipFilePath (NSString)
 
    *audioClip (NSMutableDictionary)
        *versionNumber (NSNumber)
        *filePath (NSString)
        *beingUsedInSequenceFilePaths (NSMutableArray)
        *description (NSString)
        *filePathToAudioFile (NSString)
        *startTime (NSNumber) float
        *endTime (NSNumber) float
        *seekTime (NSNumber) float // allows portions of an audio clip to be used by starting somewhere in the file
        *uploadProgress (NSNumber) float 0-.99 means it's uploading. 1.0 or greater means it's been uploaded. Less than 0 means it hasn't been uploaded.
        *audioSummary (NSDictionary)
            *audioAnalysis (NSDictionary) This is stored automatically with the filePath of the audioClip just with a different path extension
 
 
 *************** End Data Model *****************/
