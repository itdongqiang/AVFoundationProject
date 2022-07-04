//
//  TTAVVideoDecoder.h
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/7/4.
//

#import <Foundation/Foundation.h>
#import "TTAVPacket.h"
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TTAVVideoDecoder;

@protocol TTAVVideoDecoderDelegate <NSObject>

- (void)onBufferDecoded: (TTAVVideoDecoder *)decoder buffer: (CVPixelBufferRef)buffer;

@end

@interface TTAVVideoDecoder : NSObject

@property (nonatomic, weak) id<TTAVVideoDecoderDelegate> delegate;

- (void)decode: (TTAVPacket *)packet;

@end

NS_ASSUME_NONNULL_END
