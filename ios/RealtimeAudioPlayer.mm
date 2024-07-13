//
//  AudioPlayer.m
//  nativeModuleIos
//
//  Created by Kislay Singh on 10/07/24.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RealtimeAudioPlayer, NSObject)

RCT_EXTERN_METHOD(initialize:(NSUInteger)bufferByteSize
                  sampleRate:(double)sampleRate
                  channels:(NSUInteger)channels)

RCT_EXTERN_METHOD(playAudioData:(NSString *)base64String
                   withResolver:(RCTPromiseResolveBlock)resolve
                   withRejecter:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

@end

