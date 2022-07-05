//
//  TTAVBaseViewController.h
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/3/6.
//

#import <UIKit/UIKit.h>
#import <WPMediaPicker/WPMediaPicker.h>
#import "TTAVVideoExportTool.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "TTAVVideoCompositionTool.h"
#import "TTAVCaptureSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTAVBaseViewController : UIViewController
@property(nonatomic,strong) WPNavigationMediaPickerViewController * mediaPicker;
@property(nonatomic,strong) AVMutableVideoComposition *videoComposition;
@property(nonatomic,strong) AVMutableComposition *composition;
@property(nonatomic,strong) AVAudioMix *audioMix;
@property(nonatomic,copy) NSString* outPath;

- (void)setUpMediaPickerWithMediaType:(WPMediaType)type allowMultipleSelection:(BOOL)allowMultipleSelection delegate:(id)delegate;

- (void)saveVideoWithUrl:(NSURL *)url;

- (void)playAssetWithComposition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix;

- (void)playAssetWithFilePath:(NSString *)path;

// 模拟器不支持运行检查
- (BOOL)checkDeviceTypeInvalid;

@end

NS_ASSUME_NONNULL_END
