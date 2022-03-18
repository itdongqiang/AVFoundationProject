//
//  TTAVLivePhotoToVideoViewController.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/3/7.
//

#import "TTAVLivePhotoToVideoViewController.h"

@interface TTAVLivePhotoToVideoViewController ()<WPMediaPickerViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *photoTypeSeg;

@end

@implementation TTAVLivePhotoToVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpMediaPickerWithMediaType:WPMediaTypeAll allowMultipleSelection:NO delegate:self];
}
- (IBAction)import:(id)sender {
    [self presentViewController:self.mediaPicker animated:YES completion:nil];
}

- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray<WPMediaAsset> *)assets
{
    [self dismissViewControllerAnimated:YES completion:nil];
    PHAsset *asset = [assets firstObject];
    self.outPath = [NSString stringWithFormat:@"%@/livePhoto.MOV",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]];
    NSURL *fileUrl = [NSURL fileURLWithPath:self.outPath];
    [[NSFileManager defaultManager] removeItemAtPath:self.outPath error:nil];
    if (self.photoTypeSeg.selectedSegmentIndex == 0) {
        PHLivePhotoRequestOptions* options = [PHLivePhotoRequestOptions new];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        options.networkAccessAllowed = YES;
        [[PHImageManager defaultManager] requestLivePhotoForAsset:asset targetSize:[UIScreen mainScreen].bounds.size contentMode:PHImageContentModeDefault options:options resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
            if(livePhoto){
                NSArray* assetResources = [PHAssetResource assetResourcesForLivePhoto:livePhoto];
                PHAssetResource* videoResource = nil;
                for(PHAssetResource* resource in assetResources){
                    if (resource.type == PHAssetResourceTypePairedVideo) {
                        videoResource = resource;
                        break;
                    }
                }
                if(videoResource){
                    [[PHAssetResourceManager defaultManager] writeDataForAssetResource:videoResource toFile:fileUrl options:nil completionHandler:^(NSError * _Nullable error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self playAssetWithFilePath:self.outPath];
                        });
                    }];
                }
            }
        }];
    } else{
        PHImageManager *manager = [PHImageManager defaultManager];
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        [manager requestImageDataAndOrientationForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, CGImagePropertyOrientation orientation, NSDictionary * _Nullable info) {
            
            CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
            CFRetain(imageSource);
            
            NSUInteger numberOfFrames = CGImageSourceGetCount(imageSource);
            NSLog(@"numberOfFrames%lu", numberOfFrames);
            
            NSDictionary *imageProperties = CFBridgingRelease(CGImageSourceCopyProperties(imageSource, NULL));
            NSDictionary *gifProperties = [imageProperties objectForKey:(NSString *)kCGImagePropertyGIFDictionary];
            
            
            NSTimeInterval totalDuratoin = 0;//开辟空间
            NSTimeInterval *frameDurations = (NSTimeInterval *)malloc(numberOfFrames  * sizeof(NSTimeInterval));
            //读取循环次数
            NSUInteger loopCount = [gifProperties[(NSString *)kCGImagePropertyGIFLoopCount] unsignedIntegerValue];
            //创建所有图片的数值
            NSMutableArray *images = [NSMutableArray arrayWithCapacity:numberOfFrames];
            
            NSNull *aNull = [NSNull null];
            for (NSUInteger i = 0; i < numberOfFrames; ++i) {
                //读取每张的显示时间,添加到数组中,并计算总时间
                [images addObject:aNull];
                NSTimeInterval frameDuration = [self getGifFrameDelayImageSourceRef:imageSource index:i];
                frameDurations[i] = frameDuration;
                NSLog(@"%f", frameDuration);
                totalDuratoin += frameDuration;
            }
            //CFTimeInterval start = CFAbsoluteTimeGetCurrent();
            // Load first frame
            NSUInteger num = numberOfFrames;
            for (int i=0; i<num; i++) {
                //替换读取到的每一张图片
                CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, i, NULL);
                [images replaceObjectAtIndex:i withObject:[UIImage imageWithCGImage:image scale:1.0 orientation:UIImageOrientationUp]];
                CFRelease(image);
            }
            
            NSLog(@"loopCount%lu", (unsigned long)loopCount);
            NSLog(@"imageCount%lu", (unsigned long)images.count);
            NSLog(@"frameDuration%.f", totalDuratoin);
            
            //释放资源,创建子队列
            CFRelease(imageSource);
            
            __weak __typeof(self)weakSelf = self;
            self.title = @"正在合成...";
            [TTAVVideoCompositionTool compositeImageWithImageArray:images stayTime:frameDurations[0] transitionAnimation:TransitionAnimationNone bgAudioAsset:nil complete:^(AVMutableComposition * _Nonnull composition, AVMutableVideoComposition * _Nonnull videoComposition, AVMutableAudioMix * _Nonnull audioMix, NSError * _Nonnull error) {
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
        }];
    }
}

//获取当前ref的时间
- (NSTimeInterval)getGifFrameDelayImageSourceRef:(CGImageSourceRef)imageSource index:(NSUInteger)index
{
    NSTimeInterval frameDuration = 0;
    CFDictionaryRef theImageProperties;
    if ((theImageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, NULL))) {
        CFDictionaryRef gifProperties;
        if (CFDictionaryGetValueIfPresent(theImageProperties, kCGImagePropertyGIFDictionary, (const void **)&gifProperties)) {
            const void *frameDurationValue;
            if (CFDictionaryGetValueIfPresent(gifProperties, kCGImagePropertyGIFUnclampedDelayTime, &frameDurationValue)) {
                frameDuration = [(__bridge NSNumber *)frameDurationValue doubleValue];
                if (frameDuration <= 0) {
                    if (CFDictionaryGetValueIfPresent(gifProperties, kCGImagePropertyGIFDelayTime, &frameDurationValue)) {
                        frameDuration = [(__bridge NSNumber *)frameDurationValue doubleValue];
                    }
                }
            }
        }
        CFRelease(theImageProperties);
    }
    if (frameDuration < 0.02 - FLT_EPSILON) {
        frameDuration = 0.1;
    }
    return frameDuration;
}

- (IBAction)save:(id)sender {
    [self saveVideoWithUrl:[NSURL fileURLWithPath:self.outPath]];
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
