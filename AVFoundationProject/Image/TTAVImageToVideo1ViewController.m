//
//  TTAVImageToVideo1ViewController.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/3/6.
//

#import "TTAVImageToVideo1ViewController.h"


@interface TTAVImageToVideo1ViewController ()<WPMediaPickerViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *bgmSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *transAnimationSeg;
@property (weak, nonatomic) IBOutlet UISwitch *HDRSwitch;
@property(nonatomic,strong) NSMutableArray *imageArray;

@end

@implementation TTAVImageToVideo1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpMediaPickerWithMediaType:WPMediaTypeImage allowMultipleSelection:YES delegate:self];
}
- (IBAction)import:(id)sender {
    [self presentViewController:self.mediaPicker animated:YES completion:nil];
}

- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray<WPMediaAsset> *)assets
{
    self.imageArray = [NSMutableArray array];
    for (int i = 0; i < assets.count; i++) {
        PHAsset *phAsset = assets[i];
        PHImageManager *manager = [PHImageManager defaultManager];
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        [manager requestImageDataAndOrientationForAsset:phAsset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, CGImagePropertyOrientation orientation, NSDictionary * _Nullable info) {
            UIImage *image = [UIImage imageWithData:imageData];
            [self.imageArray addObject:image];
        }];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)composite:(id)sender {
    __weak __typeof(self)weakSelf = self;
    self.title = @"正在合成...";
    AVAsset *bgm = nil;
    if ([self.bgmSwitch isOn] == YES) {
        bgm = [AVAsset assetWithURL: [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"bgm" ofType:@"mp3"] ]];
    }
    
    [TTAVVideoCompositionTool compositeImageWithImageArray:self.imageArray stayTime:3.0 transitionAnimation:self.transAnimationSeg.selectedSegmentIndex bgAudioAsset:bgm complete:^(AVMutableComposition * _Nonnull composition, AVVideoComposition * _Nonnull videoComposition, AVMutableAudioMix * _Nonnull audioMix, NSError * _Nonnull error) {
        self.title = @"已合成";
        weakSelf.composition = composition;
        weakSelf.videoComposition = videoComposition;
        weakSelf.audioMix = audioMix;
        weakSelf.title = @"正在导出...";
        __weak __typeof(self)weakSelf = self;
        self.outPath = [NSString stringWithFormat:@"%@/image1.MOV",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]];
        [[NSFileManager defaultManager] removeItemAtPath:weakSelf.outPath error:nil];
        [[[TTAVVideoExportTool alloc] init] exportComposition:self.composition videoComposition:weakSelf.videoComposition audioMix:audioMix byPath:weakSelf.outPath complete:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.title = @"导出成功";
                [weakSelf playAssetWithFilePath:self.outPath];
            });
        }];
    }];
}

- (IBAction)export:(id)sender {
    [self saveVideoWithUrl:[NSURL fileURLWithPath:self.outPath]];
}

@end
