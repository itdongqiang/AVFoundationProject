//
//  TTAVVideoFileReader.h
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/7/4.
//

#import <Foundation/Foundation.h>
#import "TTAVPacket.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTAVVideoFileReader : NSObject

- (instancetype)initWithH264File: (NSString *)file;

- (TTAVPacket*)nextPacket;

@end

NS_ASSUME_NONNULL_END
