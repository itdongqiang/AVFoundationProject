//
//  TTAVAssetDataFormatViewController.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/3/9.
//

#import "TTAVAssetDataFormatViewController.h"

@interface TTAVAssetDataFormatViewController ()<WPMediaPickerViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end


@implementation TTAVAssetDataFormatViewController

- (instancetype)init{
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TTAVAssetDataFormatViewController"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpMediaPickerWithMediaType:WPMediaTypeVideo allowMultipleSelection:NO delegate:self];
}
- (IBAction)import:(id)sender {
    [self presentViewController:self.mediaPicker animated:YES completion:nil];
}

- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray<WPMediaAsset> *)assets{
    PHAsset *phAsset = [assets firstObject];
    PHImageManager *manager = [PHImageManager defaultManager];
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    __block NSString *text = @"";
    [manager requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (int i = 0; i < asset.tracks.count; i++) {
                AVAssetTrack *assetTrack = asset.tracks[i];
                text = [text stringByAppendingString:[NSString stringWithFormat:@"================%@================\n", assetTrack.mediaType]];
                for (id formatDescription in assetTrack.formatDescriptions)
                {
                    text = [text stringByAppendingString:[formatDescription description]];
                    NSLog(@"%@", text);
                }
            }
            self.textView.text = text;
        });
    }];
    [picker dismissViewControllerAnimated:YES completion:nil];
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
