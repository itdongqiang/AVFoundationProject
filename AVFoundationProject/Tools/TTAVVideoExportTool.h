//
//  TTAVVideoExportTool.h
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/3/5.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


typedef void (^ExportVideoCompleteBlock)(void);

@interface TTAVVideoExportTool : NSObject

- (void)exportComposition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix  byPath:(NSString *)path complete:(ExportVideoCompleteBlock)complete;

@end

NS_ASSUME_NONNULL_END
