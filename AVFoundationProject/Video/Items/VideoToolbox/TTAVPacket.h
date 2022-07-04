//
//  TTAVPacket.h
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/7/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTAVPacket : NSObject

@property (nonatomic, assign) uint8_t * buffer;

@property (nonatomic, assign) NSInteger size;

- (instancetype)initWithSize: (NSInteger)size;

@end

NS_ASSUME_NONNULL_END
