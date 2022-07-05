//
//  TTAVBaseViewController.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/3/6.
//

#import "TTAVBaseViewController.h"

@interface TTAVBaseViewController ()

@end

@implementation TTAVBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setUpMediaPickerWithMediaType:(WPMediaType)type allowMultipleSelection:(BOOL)allowMultipleSelection delegate:(id)delegate{
    WPMediaPickerOptions *option = [[WPMediaPickerOptions alloc] init];
    option.filter = type;
    option.allowCaptureOfMedia = NO;
    option.allowMultipleSelection = allowMultipleSelection;
    WPNavigationMediaPickerViewController * mediaPicker = [[WPNavigationMediaPickerViewController alloc] initWithOptions:option];
    mediaPicker.delegate = delegate;
    self.mediaPicker = mediaPicker;
}

- (void)playAssetWithComposition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix{
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc]init];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:composition];
    playerItem.videoComposition = videoComposition;
    playerItem.audioMix = audioMix;
    playerViewController.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    playerViewController.view.frame = self.view.frame;
    [playerViewController.player play];
    [self presentViewController:playerViewController animated:YES completion:nil];
}

- (void)playAssetWithFilePath:(NSString *)path{
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc]init];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:path]];
    playerViewController.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    playerViewController.view.frame = self.view.frame;
    [playerViewController.player play];
    [self presentViewController:playerViewController animated:YES completion:nil];
}

-(void)saveVideoWithUrl:(NSURL *)url{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        //写入图片到相册
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.title = @"已存入相册";
        });
    }];
}

- (BOOL)checkDeviceTypeInvalid {
    self.title = TARGET_IPHONE_SIMULATOR == 1 ? @"当前功能不支持模拟器" : @"";
    return TARGET_IPHONE_SIMULATOR == 1;
}

@end
