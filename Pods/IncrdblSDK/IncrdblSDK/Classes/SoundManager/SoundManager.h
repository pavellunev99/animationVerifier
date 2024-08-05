//
//  SoundManager.h
//  Created by Anton on 6/20/13.
//  Copyright (c) 2013 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

/**
 
 Для инициализации нужно вызвать [SoundManager switchSounds:YES]; (SoundManager.switchSounds(true) in Swift)
  и добавить все звуковые файлы для дальнейшего использования, например
 
 NSURL* url = [[NSBundle mainBundle] URLForResource:@"sound1" withExtension:@"mp3"];
 
 [SoundManager addFile:url alias:@"sound1"];
 
 для дальнейшего проигрывания звука необходимо вызвать метод +(void)playSound:(NSString*)alias, например
 
 [SoundManager playSound:@"sound1"]; (SoundManagerюplaySound("sound1") in Swift)

 для отключения звука нужно вызвать [SoundManager switchSounds:NO]; (SoundManager.switchSounds(false) in Swift)
 
 если после этого нужно снова включить звук, то нужно повторить всю цепочку с [SoundManager switchSounds:YES] и добавлением файлов
 
 **/

#import <Foundation/Foundation.h>

@interface SoundManager : NSObject

-(instancetype)init NS_UNAVAILABLE;

+(void)switchSounds:(BOOL)on;
+(BOOL)isSoundSwitchedOn;
+(void)addFile:(NSURL*)url alias:(NSString*)alias; // alias необходим для проигрывания файла в дальнейшем
+(void)playSound:(NSString*)alias;
+(void)playSound:(NSString*)alias infinitely:(BOOL)infinitely;
+(void)stopSound:(NSString*)alias;
+(void)pauseSound:(NSString*)alias;
+(void)resumeSound:(NSString*)alias;

@end
