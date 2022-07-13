//
//  TTAVOpenCVSampleBasicViewController.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/7/11.
//

#import "TTAVOpenCVSampleBasicViewController.h"
#import "TTAVOpenCVSampleBasicTool.h"

@interface TTAVOpenCVSampleBasicViewController ()<WPMediaPickerViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageA;
@property (weak, nonatomic) IBOutlet UIImageView *imageB;

@property (nonatomic, strong) UIImage *originImage;
 
@end

@implementation TTAVOpenCVSampleBasicViewController

- (instancetype)init{
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TTAVOpenCVSampleBasicViewController"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpMediaPickerWithMediaType:WPMediaTypeImage allowMultipleSelection:NO delegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self presentViewController:self.mediaPicker animated:YES completion:nil];
}

- (IBAction)import:(id)sender {
    [self presentViewController:self.mediaPicker animated:YES completion:nil];
}

// 灰度化
- (IBAction)gray:(id)sender {
    self.imageB.image = [TTAVOpenCVSampleBasicTool ImageToGrayImage:_originImage];
}

// 感兴趣区域拷贝图像
- (IBAction)ROI:(id)sender {
    self.imageB.image = [TTAVOpenCVSampleBasicTool mergeImage:_originImage byROI:[UIImage imageNamed:@"logo2"]];
}

// 高斯滤波 边缘处理
- (IBAction)Canny:(id)sender {
    self.imageB.image = [TTAVOpenCVSampleBasicTool GaussianBlurAndCannyImage:_originImage apertureSize:5];
}

// 阈值化
- (IBAction)adaptiveThreshold:(id)sender {
    self.imageB.image = [TTAVOpenCVSampleBasicTool adaptiveThresholdImage:_originImage];
}

- (IBAction)mosaics:(id)sender {
    self.imageB.image = [TTAVOpenCVSampleBasicTool mosaicsToImage:_originImage level:10];
}

- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray<WPMediaAsset> *)assets
{
    for (int i = 0; i < assets.count; i++) {
        PHAsset *phAsset = assets[i];
        PHImageManager *manager = [PHImageManager defaultManager];
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        [manager requestImageDataAndOrientationForAsset:phAsset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, CGImagePropertyOrientation orientation, NSDictionary * _Nullable info) {
            UIImage *image = [TTAVOpenCVSampleBasicTool scaleAndRotateImageBackCamera:[UIImage imageWithData:imageData]];
            self.imageA.image = image;
            self.originImage = image;
        }];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
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
