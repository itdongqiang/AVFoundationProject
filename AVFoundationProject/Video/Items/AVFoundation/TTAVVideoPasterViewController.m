//
//  TTAVVideoPasterViewController.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/3/10.
//

#import "TTAVVideoPasterViewController.h"

@interface TTAVVideoPasterViewController ()<WPMediaPickerViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *typeSeg;
@property(nonatomic,strong) AVAsset *asset;
@property(nonatomic,strong) CALayer *imageLayer;
@property(nonatomic,strong) CATextLayer *textLayer;
@property(nonatomic,strong) NSArray *layerArray;
@property(nonatomic,strong) CALayer *gifLayer;
@property(nonatomic,copy) NSURL *fileUrl;

@end

@implementation TTAVVideoPasterViewController

- (instancetype)init{
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TTAVVideoPasterViewController"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.fileUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"gif" ofType:@"gif"]];
    [self setUpMediaPickerWithMediaType:WPMediaTypeVideo allowMultipleSelection:NO delegate:self];
    self.layerArray = @[self.textLayer, self.imageLayer, self.gifLayer];
}
- (IBAction)import:(id)sender {
    [self presentViewController:self.mediaPicker animated:YES completion:nil];
}

- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray<WPMediaAsset> *)assets
{
    PHAsset *phAsset = [assets firstObject];
    PHImageManager *manager = [PHImageManager defaultManager];
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    [manager requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        self.asset = asset;
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (CALayer *)imageLayer{
    _imageLayer = [CALayer layer];
    _imageLayer.contents = (__bridge id _Nullable)([[UIImage imageNamed:@"logo"] CGImage]);
    _imageLayer.frame = CGRectMake(0, 0, 100, 100);
    
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.removedOnCompletion = false;
    animation.beginTime = AVCoreAnimationBeginTimeAtZero;
    animation.duration = 1;
    animation.fillMode = kCAFillModeBoth;
    animation.fromValue = @NO;
    animation.toValue = @YES;
//    [_imageLayer addAnimation:animation forKey:@"hidden"];

    return _imageLayer;
}

- (CATextLayer *)textLayer{
    _textLayer = [CATextLayer layer];
    _textLayer.string = @"探探";
    _textLayer.frame = CGRectMake(0, 0, 100, 100);
    
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.removedOnCompletion = false;
    animation.beginTime = AVCoreAnimationBeginTimeAtZero;
    animation.duration = 1;
    animation.fillMode = kCAFillModeBoth;
    animation.fromValue = @NO;
    animation.toValue = @YES;
//    [_textLayer addAnimation:animation forKey:@"hidden"];

    return _textLayer;
}

- (CALayer *)gifLayer{
    _gifLayer = [CALayer layer];
    _gifLayer.frame =  CGRectMake(0, 0, 150, 150);
    return _gifLayer;
}

- (IBAction)composite:(id)sender {
    if (!self.asset) {
        return;
    }

    CALayer *layer = self.layerArray[self.typeSeg.selectedSegmentIndex];
    __weak __typeof(self)weakSelf = self;
    AVPlayerViewController *playerVC = [[AVPlayerViewController alloc] init];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:_asset];
    AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    playerVC.player = player;
    AVSynchronizedLayer *asyLayer = [AVSynchronizedLayer synchronizedLayerWithPlayerItem:playerItem];
    [asyLayer addSublayer:layer];
    asyLayer.zPosition = 999;
    asyLayer.position = CGPointMake(0, 100);
    [playerVC.view.layer addSublayer:asyLayer];
    
    
    [weakSelf presentViewController:playerVC animated:YES completion:^{
        if (self.typeSeg.selectedSegmentIndex == 2) {
            [layer addAnimation:[self buildAnimationForGif] forKey:@"gif"];
        }
        [playerVC.player play];
    }];
}

- (CAKeyframeAnimation *)buildAnimationForGif{
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    animation.beginTime = AVCoreAnimationBeginTimeAtZero;
    animation.removedOnCompletion = YES;
    
    NSMutableArray * frames = [NSMutableArray new];    NSMutableArray *delayTimes = [NSMutableArray new];
    CGFloat totalTime = 0.0;
    CGFloat gifWidth;
    CGFloat gifHeight;
    CGImageSourceRef gifSource = CGImageSourceCreateWithURL((CFURLRef)self.fileUrl, NULL);
   
    size_t frameCount = CGImageSourceGetCount(gifSource);
    
    for (size_t i = 0; i < frameCount; ++i) {
        CGImageRef frame = CGImageSourceCreateImageAtIndex(gifSource, i, NULL);
        [frames addObject:(__bridge id)frame];        CGImageRelease(frame);

        NSDictionary *dict = (NSDictionary*)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(gifSource, i, NULL));
        gifWidth = [[dict valueForKey:(NSString*)kCGImagePropertyPixelWidth] floatValue];
        gifHeight = [[dict valueForKey:(NSString*)kCGImagePropertyPixelHeight] floatValue];
      
        NSDictionary *gifDict = [dict valueForKey:(NSString*)kCGImagePropertyGIFDictionary];
        [delayTimes addObject:[gifDict valueForKey:(NSString*)kCGImagePropertyGIFUnclampedDelayTime]];
        
        totalTime = totalTime + [[gifDict valueForKey:(NSString*)kCGImagePropertyGIFUnclampedDelayTime] floatValue];
    }
    
    if (gifSource) CFRelease(gifSource);
    
    NSMutableArray *times = [NSMutableArray arrayWithCapacity:3];
    CGFloat currentTime = 0;
    NSInteger count = delayTimes.count;
    for (int i = 0; i < count; ++i) {
        
        [times addObject:[NSNumber numberWithFloat:(currentTime / totalTime)]];
        currentTime += [[delayTimes objectAtIndex:i] floatValue];
    }
    
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:3];
    for (int i = 0; i < count; ++i) {
        [images addObject:[frames objectAtIndex:i]];
    }
    
    animation.keyTimes = times;
    animation.values = images;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.duration = totalTime;
    animation.repeatCount = HUGE_VALF;
    return animation;
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
