//
//  TTAVVideoComposition1ViewController.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/3/4.
//

#import "TTAVVideoComposition1ViewController.h"
#import "TTAVVideoCompositionTool.h"


@interface TTAVVideoComposition1ViewController ()<WPMediaPickerViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *transAnimationSegment;
@property (weak, nonatomic) IBOutlet UISwitch *HDRSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *bgmSwitch;
@property (weak, nonatomic) IBOutlet UIButton *import;
@property(nonatomic,strong) NSMutableArray *assets;
@property(nonatomic,strong) CALayer *gifLayer;
@property(nonatomic,copy) NSURL *fileUrl;


@end

@implementation TTAVVideoComposition1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.fileUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"gif" ofType:@"gif"]];
    [self setUpMediaPickerWithMediaType:WPMediaTypeVideo allowMultipleSelection:YES delegate:self];
    
//    AVAsset *a = [AVAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"wo2" ofType:@".MOV"]]];
//    CMTimeShow(a.duration);
    
}

- (IBAction)import:(id)sender {
    [self presentViewController:self.mediaPicker animated:YES completion:nil];
}

- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray<WPMediaAsset> *)assets
{
    self.assets = [NSMutableArray array];
    for (int i = 0; i < assets.count; i++) {
        PHAsset *phAsset = assets[i];
        PHImageManager *manager = [PHImageManager defaultManager];
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        [manager requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            [self.assets addObject:asset];
        }];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)export:(id)sender {
    self.title = @"正在导出...";
    __weak __typeof(self)weakSelf = self;
    self.outPath = [NSString stringWithFormat:@"%@/video1.MOV",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]];
    [[NSFileManager defaultManager] removeItemAtPath:self.outPath error:nil];
    
    [[[TTAVVideoExportTool alloc] init] exportComposition:weakSelf.composition videoComposition:weakSelf.videoComposition audioMix:weakSelf.audioMix byPath:self.outPath complete:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.title = @"导出成功";
        });
        [weakSelf saveVideoWithUrl:[NSURL fileURLWithPath:self.outPath]];
    }];
}

- (IBAction)composite:(id)sender {
    __weak __typeof(self)weakSelf = self;
    self.title = @"正在合成...";
    AVAsset *bgm = nil;
    if ([self.bgmSwitch isOn] == YES) {
        bgm = [AVAsset assetWithURL: [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"bgm" ofType:@"mp3"] ]];
    }
    
    [TTAVVideoCompositionTool compositeVideoWithAssetArray:self.assets transitionAnimation:self.transAnimationSegment.selectedSegmentIndex bgAudioAsset:bgm complete:^(AVMutableComposition * _Nonnull composition, AVVideoComposition * _Nonnull videoComposition, AVMutableAudioMix * _Nonnull audioMix, NSError * _Nonnull error) {
        self.title = @"已合成";
        weakSelf.composition = composition;
        weakSelf.videoComposition = videoComposition;
        weakSelf.audioMix = audioMix;
        [weakSelf playAssetWithComposition:composition videoComposition:videoComposition audioMix:audioMix];
    }];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
