//
//  TTAVVideoExportTool.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/3/5.
//

#import "TTAVVideoExportTool.h"

@interface TTAVVideoExportTool ()
@property (nonatomic , strong)AVAssetExportSession *exportSession;

@end

@implementation TTAVVideoExportTool

- (void)exportComposition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix  byPath:(NSString *)path  complete:(ExportVideoCompleteBlock)complete{
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    [manager removeItemAtPath:path error:nil];
    self.exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHEVCHighestQuality];
    self.exportSession.shouldOptimizeForNetworkUse = YES;
    self.exportSession.videoComposition = videoComposition;
    self.exportSession.audioMix = audioMix;
    self.exportSession.outputURL = [NSURL fileURLWithPath:path];
    self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        switch (self.exportSession.status) {
            case AVAssetExportSessionStatusCompleted:
                if (complete) {
                    complete();
                }
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"%@",self.exportSession.error);
                break;
            case AVAssetExportSessionStatusCancelled:
                break;
            default:
                break;
        }
    }];
}

@end
