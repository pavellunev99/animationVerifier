//
//  SoundPlayer.h
//
//  Created by Anton on 21/05/14.
//  Copyright (c) 2014 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

extern NSNotificationName const NSNotificationSoundPlayerFinished;

@interface SoundPlayer : NSObject
@property (nonatomic,assign) Boolean isInfinitePlayback;
@property (nonatomic,assign) Boolean isNeedRelease;
@property (nonatomic,assign) AudioFileID playbackFile;
-(instancetype)initWithURL:(NSURL*)url;
-(instancetype)initWithFileId:(AudioFileID)fileId;
-(void)dispose;
-(void)play;
-(void)pause;
-(void)unpause;
-(void)stop;
-(void)setVolume:(float)volume;
+(instancetype)playWithFileId:(AudioFileID)fileId;

@end
