//
//  TTAVVideoEncode.h
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/7/4.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTAVVideoEncode : NSObject

// 解码CMSampleBufferRef
- (void)encodeSmapleBuffer:(CMSampleBufferRef)sampleBuffer;

// 打开文件以写入编码后数据
- (void)openfile;

// 关闭文件
- (void)closefile;

@end

NS_ASSUME_NONNULL_END
