
# AVFoundationDemo
音频：
    1. AVAudioPlayer音频播放
    2. AVAudioEngineRecorder音频录制
视频：
    1. 视频拼接合成、添加背景音乐、转场效果
    2.视频添加贴纸、文字、gif表情包
图片： 
    1. 图片转视频
    2. 实况照片转视频、gif转视频
其他：
    1. 获取音视频元数据格式         
    

AVFoundation是在 iOS、macOS、watchOS 和 tvOS 上处理多媒体数据的功能齐全的框架。使用AVFoundation，我们可以播放、创建和编辑 QuickTime movie和 MPEG-4 文件，播放 HLS 流，并将强大的媒体编辑功能构建到我们的应用程序中。
# AVFouondation框架概述
在苹果的多媒体体系中，高层级的**AVKit**提供了 `AVPlayerViewController` 这种高度封装的视频播放器，轻便但封闭，可定制化的空间较小。低层级的框架主要以C接口为主，其中:
- **Core Audio**提供了音频相关的API，既提供了高层级简单的音频录制和播放功能，也提供了可以对音频进行完全控制的 `Audio Units`，对于音乐游戏或专业的音频编辑软件提供了全面的支持；
- **Core Video**使用基于管道的API处理数字视频，包括操作单个帧，以及对 `Metal` 和 `OpenGL` 的支持。
- **Core Media**定义了AVFoundation和Apple平台上其他高级媒体框架所使用的媒体管道。使用Core Media的低级数据类型和接口来高效处理媒体样本和管理媒体数据的队列。
- **Core Animation** 是iOS中动画相关的框架，AVFoundation结合Core Animation让开发者能够在视频编辑和播放过程中添加动画和贴纸效果。

而AVFoundation位于高层级框架和低层级框架之间，封装了低层级框架才能实现的功能，提供了OC和Swift接口，同时苹果在迭代过程中不断优化AVFoundation这种中间层框架的性能，很好地适配了新的设备和视频格式。因为位于UIKit之下，AVFoundation同样适用于苹果的其他平台：macOS、tvOS、watchOS。

![1-1](https://tva1.sinaimg.cn/large/e6c9d24ely1h0d041mtj6j21h80p276l.jpg)

[AVFoundation官方文档](https://developer.apple.com/documentation/avfoundation)介绍：AVFoundation结合了六个主要技术领域，这些领域覆盖了在Apple平台上捕获、处理、合成、控制、导入和导出视听媒体的主要功能。API Dodument主要划分了`Assets`媒体资产、`Playback`播放、`Capture`捕获、`Editing`编辑、`Audio`音频、`Speech`讲演六部分。

![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0d04ld42gj211k0u0gq5.jpg)

- **Assets**：提供加载、检查和导出媒体资产和元数据信息的功能，也可以使用`AVAssetReader`和`AVAssetWriter`对媒体样本数据进行样本级读写。
- **Playback**：提供对资产提供播放和播放控制的功能，可以使用`AVPlayer`播放一个项目，也可以使用`AVQueuePlayer`播放多个项目，`AVSynchronizedLayer`可以让我们结合Core Animation将动画层与播放视图层进行同步，实现播放中的诸如贴纸、文字等效果。
- **Capture**：用于拍摄照片、录制音频和视频，通过配置内置摄像头和麦克风或外部捕捉设备，可以构建自定义相机功能，控制照片和视频拍摄的输出格式，或者直接修改像素或音频数据流作为自定义输出。
- **Editing**：用于将来自多个来源的音频和视频轨道组合、编辑和重新混合到一个composition中。编辑模块的核心类是`AVComposition`，可以使用内置的合成器，也可以遵循对应的协议精细控制轨道合成的细节。
- **Audio**：播放、录制和处理音频；配置应用程序的系统音频行为。
- **Speech**：将文本转换为语音音频进行朗读。

Assets作为AVFoundation媒体处理的基础是需要首先学习的内容。
# 基础模块-AVAsset
AVAsset用于表示存储在用户设备上或远程服务器的媒体文件内容，当然也包括流媒体（如HTTP Live Streams），我们可以使用URL创建一个AVAsset实例。一个avasset是一个或多个AVAssetTrack实例的容器，该实例是对媒体的统一类型"轨道"进行的建模。一个简单的视频文件通常包含一个音频轨道和一个视频轨道，也可能包含一些补充内容，如隐藏式字幕、字幕，或者描述媒体内容的元数据(`AVMetadataItem`)。

![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0d04uzt25j214i0nadhd.jpg)
> 隐藏式字幕即`Closed Caption`，简称CC字幕。大多数CC字幕和剧本是一样的，里面除了对白之外，还有场景中产生的声音和配乐等的描述，主要是为了听障人士所设置的，Closed一词也说明了并不是默认开启的状态，与之相对的是`Open Caption`，也就是通常所说的字幕，而与对话语言相同的字幕称为`Caption`，不同的（即翻译）称为`Subtitle`。


AVAsset有很多属性，属性的访问总是同步发生，而AVAsset使用了延迟加载的设计，直到获取时才会进行加载，如果没有进行提前进行异步加载去访问资产的属性会阻塞线程，例如mp3文件如果没有在头文件设置用于定义duration的TLEN标签，那么我们获取duration属性时整个文件都需要被解析以获取准确的duration数值。AVAsset和AVAssetTrack都遵循了`AVAsynchronousKeyValueLoading`协议，可以进行异步加载属性和获取加载状态。
```
@protocol AVAsynchronousKeyValueLoading
// 异步加载包含在keys数组中的属性，在handler中使用statusOfValueForKey:error:方法判断加载是否完成。
- (void)loadValuesAsynchronouslyForKeys:(NSArray<NSString *> *)keys completionHandler:(nullable void (^)(void))handler;
// 获取key属性加载的状态，status为AVKeyValueStatusLoaded为加载完成。
- (AVKeyValueStatus)statusOfValueForKey:(NSString *)key error:(NSError * _Nullable * _Nullable)outError;
```
WWDC2021[What’s new in AVFoundation](https://developer.apple.com/videos/play/wwdc2021/10146/)提到，针对swift引入了`async` / `await` ，让我们得以使用与同步编程类似的控制流来进行异步编程。
```
let asset = AVAsset (url: assetURL)
let duration = trv await asset.load(.duration)
// 我们也可以加载多个属性，使用元组接收返回值：
let (duration, tracks) = try await asset.load(.duration, .tracks)
```
AVAsset的属性：
![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0f53x8odej20zk0fdad6.jpg)

代码实例中`tracks`属性返回的是一个avasset包含的所有`AVAssetTrack`的数组，苹果也提供了根据特定标准(如标识符、媒体类型或特征)检索轨道子集的方法如下，这也是编辑模块中取出某种类型的轨道要调用的方法。
```
// 根据TrackID检索轨道
- (void)loadTrackWithTrackID:(CMPersistentTrackID)trackID completionHandler:(void (^)(AVAssetTrack * _Nullable_result, NSError * _Nullable))completionHandler;
// 根据媒体类型检索轨道子集
- (voidloadTracksWithMediaType:(AVMediaType)mediaType completionHandler:(void (^)(NSArray<AVAssetTrack *> * _Nullable NSError * _Nullable))completionHandler;
// 根据媒体特征检索轨道子集
- (void)loadTracksWithMediaCharacteristic:(AVMediaCharacteristic)mediaCharacteristic completionHandler:(void (^)(NSArray<AVAssetTrack *> * _Nullable, NSError * _Nullable))completionHandler;
```
AVAsset还提供了几种查看文件元数据的接口，例如查看mp3文件中存储的音乐作品的作者、封面，视频文件中的创作时间、设备型号等，它们被存在`AVMetadataItem`里。

1. `availableMetadataFormats`：`asset.availableMetadataFormats`获得所有`keys`，遍历`keys`根据`[asset 
 metadataForFormat:key]`方法获取所有元数据`AVMetadataItem`数组。
2. `metadata`：通过`asset.metadata`方法直接可以得到所有元数据，和`availableMetadataFormats`获得到的元数据相同。
3. `commonMetadata`：通过`asset.commonMetadata`方法直接可以得到常用的元数据，但是获取的可能不全。

再深入一点，拿到一个`.mov`文件，如果想获取视频样本的编码类型(`h264`/`hevc`)、转换函数(`ITU_R_709_2`/`ITU_R_2100_HLG`)等，获取音频样本的采样率、通道数、位深等元数据样本格式信息，我们应该从哪里入手呢？前面我们介绍了在一个AVAsset资产中以轨道的形式把音频、视频等文件分别进行了单独的轨道建模，如果要获取视频样本格式的信息，只要根据媒体类型检索相应的轨道，获取assetTrack的`formatDescriptions`属性，即可拿到全部视频格式信息`CMVideoFormatDescription`的集合，同样还有`CMAudioFormatDescription`、`CMClosedCaptionFormatDescription`等用于描述各自轨道样本的数据格式。
```
// 获取元数据样本格式信息
AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
NSArray *videoFormats = VideoTrack.formatDescriptions;
```
认识了AVAsset和AVAssetTrack之后，我们建立了一种从资产轨道的角度去看待音视频文件的视角，下面我们正式开始从视频编辑的角度学习AVFoundation框架。

# 添加素材
短视频编辑的素材通常来自相册和拍摄，苹果的PhotosKit提供了管理相册资产的接口，而AVFoundation中的Capture模块则负责相机拍摄的部分。
## 拍摄
### 基础拍照录制功能
我们首先通过实现一个简单的拍照和录制视频（不支持暂停继续）的功能来认识拍摄模块的使用方式，需要使用的核心类如下：
- `AVCaptureSession`：AVCaptureSession是管理拍摄活动的开始和停止，并协调从输入设备到输出数据流的对象，接收来自摄像头和麦克风等捕捉设备的输入数据，将数据协调至适当的输出进行处理，最终生成视频、照片或元数据。
- `AVCaptureDevice`：一个AVCaptureDevice对象表示一个物理捕捉设备和与该设备相关联的属性（曝光模式、聚焦模式等）。捕捉设备向AVCaptureSession对象提供输入数据，不过`AVCaptureDevice`不能直接添加至`AVCaptureSession`中，而是需要封装为`AVCaptureDeviceInput`对象，来作为`AVCaptureSession`的输入源。
- `AVCaptureOutput`：决定了捕捉会话数据流的输出方式，通常我们使用其子类来决定输出什么样的数据格式，其中`AVCaptureMetadataOutput`用于处理定时元数据的输出，包含了人脸检测或机器码识别的数据；`AVCapturePhotoOutput`用于静态照片、实况照片的输出； `AVCaptureVideoDataOutput`用于记录视频并提供对视频帧进行处理的捕获输出。`AVCaptureMovieFileOutput`继承自`AVCaptureFileOutput`：将视频和音频记录到QuickTime电影文件的捕获输出。`AVCaptureDepthDataOutput`在兼容的摄像机设备上记录场景深度信息的捕捉输出。
- `AVCaptureConnection`：用于连接AVCaptureSession中输入和输出的对象，要求音频和视频要对应。
- `AVCaptureVideoPreviewLayer`：CALayer的子类，可以对捕捉视频数据进行实时预览。

学习AVFoundation相机拍摄功能最好的代码实例是苹果官方的demo-[AVCam](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app?language=objc)，苹果每年在相机功能方面进行改进的同时也会对该demo保持更新，这里不再附加实例代码。不过有些需要留意的点还是要提一下：
- 相机和麦克风作为用户隐私功能，我们首先需要在info.plist中配置相应的访问说明，使用前也要检查设备授权状态`AVCaptureDeviceAVAuthorizationStatus`。
- 添加`AVCaptureInput和AVCaptureOutput`前都要进行canAddxx的判断。
- 因为相机和麦克风设备可能不止一个应用程序在使用，对相机的闪光模式、曝光模式、聚焦模式等配置的修改需要放在``[device lockForConfiguration:&error]``和``[device unLockForConfiguration:&error]``之间，修改前还需要判断当前设备是否支持即将切换的配置。。
- `AVCaptureSession`要运行在单独的线程，以免阻塞主线程。
- 由于拍摄期间可能会被电话或其他意外情况打断，最好注册`AVCaptureSessionWasInterruptedNotification`以做出相应的处理。
- 相机是一个CPU占用较高的硬件，如果设备承受过大的压力（例如过热），拍摄也可能会停止，最好通过KVO监听`KeyPath"videoDeviceInput.device.systemPressureState"`，根据`AVCaptureSystemPressureState`调整相机性能。

![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0d05emylvj21md0u0gpm.jpg)
上图是包含了最基础的照片拍摄和视频录制写入URLPath基本功能的流程。但是使用`AVCaptureMovieFileOutput`作为输出不能控制录制的暂停和继续，我们需要引入AVFoundaton中Assets模块的另一个类AVAssetWriter来配合`AVCaptureVideoDataOutput`和`AVCaptureAudioDataOutput`来控制视频的录制过程。

### AVAssetWriter写入文件
**AVAssetReader & AVAssetWriter** 

`AVAsserReader`用于从AVAsset实例中读取媒体样本，通常AVAsset包含多个轨道，所以必须给AVAsserReader配置一个或多个`AVAssetReaderOutput`实例，通过调用`copyNextSampleBuffer`访问音频样本和视频帧。AVAssetReaderOutput是一个抽象类，通常使用其子类来从不同来源读取数据，其中`AVAssetReaderTrackOutput`用于从资产的单个轨道读取媒体数据的对象；
`AVAssetReaderAudioMixOutput`用于读取一个或多个轨道混合音频产生的音频样本的对象；`AVAssetReaderVideoCompositionOutput`用于从资产的一个或多个轨道读取组合视频帧的对象；`AssetReaderSampleReferenceOutput`用来提取有关轨道中示例位置的信息——文件URL和偏移量。

**注意**：AVAsserReader在开始读取前可以设置读取的范围，开始读取后不可以进行修改，只能顺序向后读，不过可以在output中可以设置`supportsRandomAccess = YES`之后可以重置读取范围。虽然AVAssetReader的创建需要一个AVAsset实例，但是我们可以通过将多个AVAsset组合成一个AVAsset的子类`AVComposition`进行多个文件的读取，`AVComposition`会在视频编辑中详细介绍。
```
AVAsset *asset = ...;
// 获取视频轨道
AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo]firstObject];
// 通过asset创建读取器
AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset:asset error:nil];
// 配置outsettings
NSDictionary *readerOutputSettings = @{               
    (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)
};
AVAssetReaderOutput *trackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:readerOutputSettings];
[assetReader addOutput:trackOutput];
// 调用开始读取，之后不断获取下一帧直到没有数据返回
[assetReader startReading];
while (assetReader.status == AVAssetReaderStatusReading) {        
    CMSampleBufferRef sampleBuffer = [trackOutput copyNextSampleBuffer];   
    if (sampleBuffer) {        
        CMBlockBufferRef blockBufferRef =                               
        CMSampleBufferGetDataBuffer(sampleBuffer);    
        size_t length = CMBlockBufferGetDataLength(blockBufferRef);
        SInt16 sampleBytes[length];
        CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, sampleBytes);
        // 你的处理xxx例如重新编码写入
        CMSampleBufferInvalidate(sampleBuffer);                         
        CFRelease(sampleBuffer);
    }
}
    if (assetReader.status == AVAssetReaderStatusCompleted) {             
        // Completed
    }
```
> CMSampleBuffer是读取器和写入器操作的对象，它是系统用来通过媒体管道移动媒体样本数据的核心基础对象，CMSampleBuffer的角色是将基础的样本数据进行封装并提供格式和时间信息，还会加上所有在转换和处理数据时用到的元数据。CMSampleBuffer的实例包含零个或多个特定媒体类型的压缩（或未压缩）样本，并包含以下内容之一：
>    - 一个或多个媒体样本的CMBlockBuffer。
>    - CVImageBuffer，是对CMSampleBuffers流的格式、每个包含的媒体样本的大小和时间信息、缓冲区级别和样本级别的附件的引用。
> ![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0d05pcdpjj20zs0jojtd.jpg)

`AVAssetWriter`用于对资源进行编码并将其写入到容器文件中。它由一个或多个`AVAssetWriterInput`对象配置，用于附加媒体样本的`CMSampleBuffer`。在我们使用AVAssetWriter的时候，经常会用到`AVAssetWriterInputPixelBufferAdaptor`作为assetWriter的输入，用于把缓冲池中的像素打包追加到视频样本上，举例来说，当我们要将摄像头获取的原数据（一般是CMSampleBufferRef）写入文件的时候，需要将`CMSampleBuffer`转成`CVPixelBuffer`，而这个转换是在`CVPixelBufferPool`中完成的，`AVAssetWriterInputPixelBufferAdaptor`的实例提供了一个`CVPixelBufferPool`，可用于分配像素缓冲区来写入输出数据，苹果文档介绍，使用它提供的像素缓冲池进行缓冲区分配通常比使用额外创建的缓冲区更有效。
```
NSURL *outputURL = ...;
// 通过一个空文件的ur来创建写入器
AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:outputURL fileType:AVFileTypeQuickTimeMovie error:nil];
// 配置outsettings
NSDictionary *writerOutputSettings = @{
                                           AVVideoCodecKey : AVVideoCodecH264,
                                           AVVideoWidthKey : @1080,
                                           AVVideoHeightKey : @1920,
                                           AVVideoCompressionPropertiesKey : @{
                                                   AVVideoMaxKeyFrameIntervalKey : @1,
                                                   AVVideoAverageBitRateKey : @10500000,
                                                   AVVideoProfileLevelKey : AVVideoProfileLevelH264Main31
                                                   }
                                           };
// 使用视频格式文件作为输入
AVAssetWriterInput *writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:writerOutputSettings];
[assetWriter addInput:writerInput];
// 开始写入
[assetWriter startWriting];
```
AVAssetWriter可用于实时操作和离线操作两种情况，对于每个场景有不同的方法将样本buffer添加到写入对象的输入中：

**实时**：实时资源时，比如从`AVCaptureVideoDataOutput`写入捕捉的样本时，`AVAssetWriterInput`应该设置`expectsMediaDataInRealTime`属性为YES来确保`isReadyForMoreMediaData`值被正确设置，不过在写入开始后，无法再修改此属性。

**离线**： 当从离线资源读取媒体资源时，比如从AVAssetReader读取样本buffer，在附加样本前仍然需要观察写入的`readyForMoreMediaData`属性的状态，不过可以使用`requestMediaDataWhenReadyOnQueue：usingBlock:`方法控制数据的提供。传到这个方法中的代码会随写入器输入准备附加更多的样本而不断被调用，添加样本时开发者需要检索数据并从资源中找到下一个样本进行添加。
> AVAssetReaderOutput和AVAssetWriterInput都可以配置outputSettings，outputSettings正是控制解、编码视频的核心。 
>
>`AVVideoSettings`
>- AVVideoCodecKey 编码方式
>- AVVideoWidthKey 像素宽
>- AVVideoHeightKey 像素高
>- AVVideoCompressionPropertiesKey 压缩设置：
 >   - AVVideoAverageBitRateKey 平均比特率
 >   - AVVideoProfileLevelKey 画质级别 
 >   - AVVideoMaxKeyFrameIntervalKey 关键帧最大间隔
 > `AVAudioSettings`
> - AVFormatIDKey 音频格式
> - AVNumberOfChannelsKey 采样通道数
> - AVSampleRateKey 采样率
> - AVEncoderBitRateKey 编码码率 
> 更多的设置，参见苹果官方文档[Video Settings](https://developer.apple.com/documentation/avfoundation/avcapturephotosettings/video_settings/)

**注意**: AVAssetReader不适用做实时处理，例如HLS实时数据流。

`AVAssetReader`可以看做解码器，与`AVAssetReaderOutput`配套使用，决定以什么样的配置解码成buffer数据；`AVAssetWriter`可以看做编码器，与`AVAssetWriterInput`配套使用，决定将数据以什么配置编码成视频，`CMSampleBuffer`为编码的数据，视频经`AVAssetReader`后输出`CMSampleBuffer`，经`AVAssetWriter`可以重新将CMSampleBuffer`编码成视频。

下面是AVAssetReader和AVAssetWriter成对使用用作视频转码示例：
```
- (BOOL)startAssetReaderAndWriter {
    // 尝试开始读取
     BOOL success = [self.assetReader startReading];
    if (success){
        // 尝试开始写
        success = [self.assetWriter startWriting];
     }
     if (success) {
          // 开启写入session
          self.dispatchGroup = dispatch_group_create();
          [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
          self.videoFinished = NO;
          if (self.assetWriterVideoInput) {
               dispatch_group_enter(self.dispatchGroup);
               [self.assetWriterVideoInput requestMediaDataWhenReadyOnQueue:self.rwVideoSerializationQueue usingBlock:^{
                    BOOL completedOrFailed = NO;
                    // WriterVideoInput准备好元数据时开始读写
                    while ([self.assetWriterVideoInput isReadyForMoreMediaData] && !completedOrFailed) {
                         // 获取视频下一帧 加入 output中
                         CMSampleBufferRef sampleBuffer = [self.assetReaderVideoOutput copyNextSampleBuffer];
                         if (sampleBuffer != NULL) {
                              BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                              CFRelease(sampleBuffer);
                              sampleBuffer = NULL;
                              completedOrFailed = !success;
                         } else {
                              completedOrFailed = YES;
                         }
                    }
                    if (completedOrFailed) {
                         // 标记写入结束
                         BOOL oldFinished = self.videoFinished;
                         self.videoFinished = YES;
                         if (oldFinished == NO) {
                              [self.assetWriterVideoInput markAsFinished];
                         }
                         dispatch_group_leave(self.dispatchGroup);
                    }
               }];
          }
          // 监听读取写入完成状态
          dispatch_group_notify(self.dispatchGroup, self.mainSerializationQueue, ^{
               BOOL finalSuccess = YES;
              if ([self.assetReader status] == AVAssetReaderStatusFailed) {
                   finalSuccess = NO;
              }
              // 完成写入
              if (finalSuccess) {
                   finalSuccess = [self.assetWriter finishWriting];
              }
               // 处理写入完成
               [self readingAndWritingDidFinishSuccessfully:finalSuccess];
          });
     }
     return success;
}
```
但是两者并不要求一定成对使用，AVAssetWriter要处理的数据是前面介绍的`CMSampleBuffer`，`CMSampleBuffer`可以从相机拍摄视频时获取实时流，也可以通过图片数据转换得来（图片转视频）。

![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0d062c8saj20s107ljrz.jpg)

下面是通过AVAssetWiter将AVCaptureVideoDataOutput的代理方法中的CMSampleBuffer写入文件的核心代码。
```
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    [_writer startWriting];
    [_writer startSessionAtSourceTime:startTime];
    if(captureOutput == self.videoDataOutput) {
        //视频输入是否准备接受更多的媒体数据
        if (_videoInput.readyForMoreMediaData == YES) {
            //拼接视频数据
            [_videoInput appendSampleBuffer:sampleBuffer];
        }
    } else {
        //音频输入是否准备接受更多的媒体数据
        if (_audioInput.readyForMoreMediaData) {
            //拼接音频数据
            [_audioInput appendSampleBuffer:sampleBuffer];
        }
    }
}

```
至此我们可以实现视频录制的暂停与继续，基本上已经介绍了大多数app相机模块实现的主要功能架构，如下：

![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0d06fvnfnj21og0u0n0t.jpg)
### 相机的其他功能
苹果每年都会对设备的相机功能进行优化或扩展，除了简单的拍照和录像，我们还可以使用Capture模块捕捉更多数据。
#### 人脸、身体和机器可读码
AVFoundation中的人脸检测`AVMetadataFaceObject`功能在iOS6.0就开始支持，iOS13.0增加了对身体的检测，包含人体`AVMetadataHumanBodyObject`、猫身体`AVMetadataCatBodyObject`、狗身体`AVMetadataDogBodyObject`。他们都继承自`AVMetadataObject`，除了各自增加了诸如`faceID`、`bodyID`这样的属性外，他们的属性主要来自`AVMetadataObject`，其中bounds是检测到的目标的轮廓，当然，人脸检测补充了沿着z轴旋转的人脸角度`rollAngle`和是沿着y轴旋转的人脸角度`yawAngle`。
> 如果我们想要检测人脸的关键点数据，可以使用`Vision`框架中的`VNDetectFaceRectanglesRequest`和`ARKit`框架中的`ARFaceTrackingConfiguration`，都可以吊起相机获取人脸关键点的数据。

iOS7.0增加了机器可读码(`AVMetadataMachineReadableCodeObject`)的识别功能，返回了包含表示机器码的字符含义的stringValue数据，在WWDC2021[What's new in camera capture](https://developer.apple.com/videos/play/wwdc2021/10047/)中提到了辅助可读码识别功能一个重要的属性`minimumFocusDistance`，是指镜头能够合焦的最近拍摄距离，所有摄像头都会包含该参数，只是苹果在iOS15.0才公开该属性，我们可以使用该属性调整相机的放大倍数，以解决低于最近识别距离后无法识别的问题，详细源码可参考官网的demo[AVCam​条码：检测条码和人脸](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcambarcode_detecting_barcodes_and_faces?language=objc)。

这里把这些并不相关的检测放在一块介绍是因为从API的角度，他们都以`AVCaptureMetadataOutput`作为输出，`AVCaptureMetadataOutput`提供了一个`metadataObjectTypes`数组属性，我们可以传入一个或多个要检测的类型，实现`AVCaptureMetadataOutputObjectsDelegate`协议的现``- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection;``方法，从metadataObjects中获取想要的数据。
#### Live photo 
live photo是iOS10.0推出的功能，系统相机app中选择“照片”项右上角的live标志控制是否开启拍摄live photo功能。开启live photo功能会拍摄下用户点击拍摄按钮前后各0-1.5秒（官网说的是1.5秒）的视频，取中间的一帧作为静态图片和一个3秒左右的视频一起保存下来，在相册中长按照片可以播放其中的视频。使用live photo拍摄API，需要使用`AVCapturePhotoOutput`的`isLivePhotoCaptureSupported`属性判断是否支持该功能，live photo只能运行在`AVCaptureSessionPresetPhoto`预设模式下，且不能和`AVCaptureMovieFileOutput`共存，live photo有自己的两个回调方法：
```
// 已经完成整段视频的录制，还没写入沙盒
- (void) captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishRecordingLivePhotoMovieForEventualFileAtURL:(NSURL *)outputFileURL resolvedSettings:(AVCaptureResolvedPhotoSetting s *)resolvedSettings;
// 视频已经写入沙盒
- (void) captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error;
```
**注意**：保存Live Photo必须和图片使用同一个`PHAssetCreationRequest`对象，才能将两者关联起来，要展示实况照片，需要使用`PHLivePhotoView`，它默认添加了长按播放实况照片的手势。
#### 景深
苹果在相机方面的功能和Capture模块的API每年都会有很多的更新（也是比较恶心的一点），但是像深度数据这样，发布以来从图片编辑到视频编辑从软件到硬件，不断优化不断拓宽应用领域和深度得并不多，景深数据值得我们持续关注。

景深是指摄像头拍照时获取到图片中的物体在现实世界的远近数据，苹果在iOS11.0在具有双摄像头的设备中推出了带有景深数据的人像模式，最初后置摄像头的景深数据是使用跳眼法通过两个摄像头的数据根据相似三角形原理计算得来，前置摄像头通过红外线探测，后来苹果引入了LiDAR模组，通过光线探测测距能够得到精确的景深数据，它对AR模块也有很大帮助。
![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0d08iov12j21g60u040e.jpg)
用来描述景深数据的是`AVDepthData`类，其包含的核心属性如下：
```
depthDataType: 景深数据的数据类型，kCVPixelFormatType_DisparityX表示的是视差数据，kCVPixelFormatType_DepthX表示的是深度数据，可以转换。
depthDataMap: 景深的数据缓冲区，可以转成UIImage
isDepthDataFiltered: 是否启动插值
depthDataAccuracy: 景深数据的准确度
```

**注意**：通过UIImge创建的imag不会包含景深数据，需要使用photosKit框架读取。

在AVFoundation的Capture模块，景深数据捕捉分为静态景深捕捉和实时景深捕捉。
- 静态景深捕捉：静态景深捕捉只需要配置`AVCapturePhotoOutput`和`AVCapturePhotoSettings`的`isDepthDataDeliveryEnabled`为YES，在代理方法中即可获取`photo.depthData`数据，我们可以将景深数据中的depthDataMap转为图片存相册，也可以将数据写入原图，保存为一张带有景深数据的人像图。
- 实时景深：顾名思义，要有数据流的支撑，需要同时使用`AVCaptureVideoDataOutput`和景深输出`AVCaptureDepthDataOutput`，但是景深输出的帧率和分辨率都远低于视频数据输出（性能考虑），为解决这一问题，苹果专门引入了`AVCaptureDataOutputSynchronizer`来协调各个流的输出。
```
self.dataOutputSynchronizer = [[AVCaptureDataOutputSynchronizer alloc] initWithDataOutputs:@[self.videoOutput, self.depthOutput]];
[self.dataOutputSynchronizer setDelegate:self queue: self.cameraProcessingQueue];
```
然后我们就可以在代理方法中得到`AVCaptureSynchronizedDataCollection`实例
```
- (void)dataOutputSynchronizer:(AVCaptureDataOutputSynchronizer *)synchronizer didOutputSynchronizedDataCollection:(AVCaptureSynchronizedDataCollection *)synchronizedDataCollection{
    AVCaptureSynchronizedDepthData *depthData = (AVCaptureSynchronizedDepthData *)[synchronizedDataCollection synchronizedDataForCaptureOutput:self.depthOutput];
}
```
如果我们仅仅只想使用景深数据，也可以直接在`AVCaptureVideoDataOutput`的回调方法中处理。有了深度数据，我们可以使用`Core Image`提供的各种遮罩、滤镜、更改焦点等效果，让照片显示出不同的效果的同时仍然保持层次感，具体的应用可以参考[Video Depth Maps Tutorial for iOS](https://www.raywenderlich.com/5999357-video-depth-maps-tutorial-for-ios-getting-started#toc-anchor-001)。

在添加了实时景深输出后，相机的架构变成了这样：
![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0d09qhrrwj21i10u0wio.jpg)

AVFoundation的Capture模块为我们提供了自定义相机的拍照、录像、实况照片、景深人像模式、人脸身体检测、机器码识别等等，此外诸如多相机拍摄、图像分割（头发、牙齿、眼镜、皮肤）。。。不再深入介绍。

## 相册
相册是视频剪辑素材的另一个来源，苹果的系统相册可以保存图片、视频、实况照片、gif动图等，剪映、快影和wink等视频剪辑app对于从相册中选择的素材都统一转为了一段视频，下面分别介绍转为视频的方法。
### 静态图片转视频
静态图片转视频的功能所使用的核心类 `AVAssetWriter` 前面已经学习过了，和视频录制写入文件的差别在于数据的来源变成了相册中的图片，缺点是使用 `AVAssetWriter` 写入文件过程中不支持预览，这个问题我们会在视频编辑部分解决。
### 实况照片转视频
前面已经介绍了如何使用自定义相机拍摄和保存实况照片，而大多app从相册中直接获取去使用交给UIImage的往往是一张静态图片，要转为视频进行编辑，我们需要使用PhotosKit提供的API。
```
// 创建实况照片请求配置
PHLivePhotoRequestOptions* options = [[PHLivePhotoRequestOptions alloc] init];
options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
[[PHImageManager defaultManager] requestLivePhotoForAsset:phAsset targetSize:[UIScreen mainScreen].bounds.size contentMode:PHImageContentModeDefault options:options resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
    NSArray* assetResources = [PHAssetResource assetResourcesForLivePhoto:livePhoto];
    PHAssetResource* videoResource = nil;
    // 判断是否含有视频资源
    for(PHAssetResource* resource in assetResources){
        if (resource.type == PHAssetResourceTypePairedVideo) {
            videoResource = resource;
            break;
        }
    if(videoResource){
        // 将视频资源写入指定路径
        [[PHAssetResourceManager defaultManager] writeDataForAssetResource:videoResource toFile:fileUrl options:nil completionHandler:^(NSError * _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 去使用视频资源
        [self handleVideoWithPath:self.outPath];
    });
}];
```
值得一提的是，`PHAsset`还有一个私有方法`fileURLForVideoComplementFile`可以直接获取实况照片中视频文件的URL地址，不过私有API要避免在线上使用。
### gif动图转视频
gif由多张图片组合，利用视觉暂留原理形成动画效果，要把gif转为视频的关键是获取gif中保存的单帧和每帧停留的时间，ImageIO.framework提供了相关的接口。
```
// 从相册读取gif
PHImageManager *manager = [PHImageManager defaultManager];
PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
[manager requestImageDataAndOrientationForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, CGImagePropertyOrientation orientation, NSDictionary * _Nullable info) {
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    CFRetain(imageSource);
    // 获取gif包含的帧数
    NSUInteger numberOfFrames = CGImageSourceGetCount(imageSource);
    NSDictionary *imageProperties = CFBridgingRelease(CGImageSourceCopyProperties(imageSource, NULL));
    NSDictionary *gifProperties = [imageProperties objectForKey:(NSString *)kCGImagePropertyGIFDictionary];
    NSTimeInterval totalDuratoin = 0;//开辟空间
    NSTimeInterval *frameDurations = (NSTimeInterval *)malloc(numberOfFrames * sizeof(NSTimeInterval));
    //读取循环次数
    NSUInteger loopCount = [gifProperties[(NSString *)kCGImagePropertyGIFLoopCount] unsignedIntegerValue];
    //创建所有图片的数值
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:numberOfFrames];
    for (NSUInteger i = 0; i < numberOfFrames; ++i) {
        //读取每张的显示时间,添加到数组中,并计算总时间
        CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, i, NULL);
        [images addObject:[UIImage imageWithCGImage:image scale:1.0 orientation:UIImageOrientationUp]];
        CFRelease(image);
        NSTimeInterval frameDuration = [self getGifFrameDelayImageSourceRef:imageSource index:i];
        frameDurations[i] = frameDuration;
        totalDuratoin += frameDuration;
    }
CFRelease(imageSource);
}];
```
单帧的停留时间，保存在`kCGImagePropertyGIFDictionary`字典中，只是其中包含了两个看起来很相似的key：`kCGImagePropertyGIFUnclampedDelayTime`：数值可以为0，`kCGImagePropertyGIFDelayTime`：值不会小于100毫秒。很多gif图片为了得到最快的显示速度会把duration设置为0， 浏览器在显示他们的时候为了性能考虑就会给他们减速(clamp)，通常我们会取先获取 `kCGImagePropertyGIFUnclampedDelayTime` 的值，如果没有就取 `kCGImagePropertyGIFDelayTime`的值， 如果这个值太小就设置为0.1，因为gif的标准中对这一数值有限制，不能太小。
```
- (NSTimeInterval)getGifFrameDelayImageSourceRef:(CGImageSourceRef)imageSource index:(NSUInteger)index
{
    NSTimeInterval frameDuration = 0;
    CFDictionaryRef theImageProperties;
    if ((theImageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, NULL))) {
        CFDictionaryRef gifProperties;
        if (CFDictionaryGetValueIfPresent(theImageProperties, kCGImagePropertyGIFDictionary, (const void **)&gifProperties)) {
        const void *frameDurationValue;
            // 先获取kCGImagePropertyGIFUnclampedDelayTime的值
            if (CFDictionaryGetValueIfPresent(gifProperties, kCGImagePropertyGIFUnclampedDelayTime, &frameDurationValue)) {
                frameDuration = [(__bridge NSNumber *)frameDurationValue doubleValue];
                // 如果值不可用，获取kCGImagePropertyGIFDelayTime的值
                if (frameDuration <= 0) {
                    if (CFDictionaryGetValueIfPresent(gifProperties, kCGImagePropertyGIFDelayTime, &frameDurationValue)) {
                        frameDuration = [(__bridge NSNumber *)frameDurationValue doubleValue];
                    }
                }
            }
        }
    CFRelease(theImageProperties);
    }
    // 如果值太小，则设置为0.1
    if (frameDuration < 0.02 - FLT_EPSILON) {
        frameDuration = 0.1;
    }
    return frameDuration;
}
```
在获取了所有的图片和图片停留时间后，我们就可以使用图片转视频的方法进行处理了。这部分内容我们在编辑部分对视频中添加gif表情包也会用到。

至此，无论是从相机拍摄还是相册获取，我们都能结合AVFoundation框架得到我们想要的视频文件来作为视频编辑的主素材，可以正式开始我们的编辑了。

# 编辑
## 视频拼接 + bgm
### AVMutableComposition
前面我们提到，`AVAssetWriter`在进行写入时不支持预览（虽然通过`AVSampleBufferDisplayLayer`可以显示`CMSambuffer`，但这无疑增加了很多的工作量也违背了我们从宏观角度看待视频编辑的初心），而视频播放需要的`AVPlayerItem`需要一个`AVAsset`实例来初始化，我们希望有一个类，它继承自`AVAsset`，而且能够对其中的`AVAssetTrack`进行任意的修改，既可以处理编辑，也可以用来在耗时的导出之前进行预览，AVFoundation为我们提供了这样一个类`AVComposition`，其可变子类`AVMutableComposition`满足了这些要求。

> AVFoundation的Editing模块的很多类都有这样一个特点：不可变的父类拥有很多只读的属性，其可变的子类继承父类的属性将部分属性变为了可读可写，这里注意不一定是全部都可读可写。

![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0d09zcenzj21220ru416.jpg)

在Assets模块的中，我们说到`AVAsset`包含一个或多个 `AVAssetTrack`，同样作为子类的`AVComposition`也包含一个或多个 `AVCompositionTrack`，而我们处理的对象正是他们的可变子类`AVMutableComposition`和`AVMutableCompositionTrack`。

`AVMutableComposition`中提供了两个类方法用来创建一个空资产。
```
+ (instancetype)composition;
+ (instancetype)compositionWithURLAssetInitializationOptions:(nullable NSDictionary<NSString *, id> *)URLAssetInitializationOptions NS_AVAILABLE(10_11, 9_0);
```
从composition中添加和移除`AVMutableCompositionTrack`的方法：
```
//向 composition 中添加一个指定媒体资源类型的空的AVMutableCompositionTrack
- (AVMutableCompositionTrack *)addMutableTrackWithMediaType:(NSString *)mediaType preferredTrackID:(CMPersistentTrackID)preferredTrackID;
//从 composition 中删除一个指定的 track
- (void)removeTrack:(AVCompositionTrack *)track;
```
修改`AVCompositionTrack`的方法：
```
//将指定时间段的 asset 中的所有的 tracks 添加到 composition 中 startTime 处
- (BOOL)insertTimeRange:(CMTimeRange)timeRange ofAsset:(AVAsset *)asset atTime:(CMTime)startTime error:(NSError * _Nullable * _Nullable)outError;
//向 composition 中的所有 tracks 添加空的时间范围
- (void)insertEmptyTimeRange:(CMTimeRange)timeRange;
//从 composition 的所有 tracks 中删除一段时间，该操作不会删除 track ，而是会删除与该时间段相交的 track segment
- (void)removeTimeRange:(CMTimeRange)timeRange
//改变 composition 中的所有的 tracks 的指定时间范围的时长，该操作会改变 asset 的播放速度
- (void)scaleTimeRange:(CMTimeRange)timeRange toDuration:(CMTime)duration;
```
我们留意到很多方法需要传递一个`CMTime`或`CMTimeRange`，这是`Core Media`框架提供的结构体类型。
```
typedef struct { 
    CMTimeValue value; 
    CMTimeScale timescale; 
    CMTimeFlags flags; 
    CMTimeEpoch epoch; 
}
typedef struct {
    CMTime start; 
    CMTime duration; 
} CMTimeRange
```
浮点类型难以满足对性能和精确度要求的视频编辑，`CMTime`使用分数的形式表示时间，`value`表示分子，`timescale`表示分母，`seconds = value/timescale`，`flags是位掩码`，表示时间的指定状态。在创建CMTime时为了兼容电影电视的24fps、25fps等我们一般把`timescale`设置为600。而`CMTimeRange`则包含了一个起点和一个持续时间。

从上面提供的方法可以看出，我们可以对`AVMutableComposition`添加空的`AVMutableCompositionTrack`轨道，然后将准备好的`AVAsset`的`AVAssetTrack`插入到`AVMutableCompositionTrack`轨道中，视频的拼接就是这样一个简单的操作。
 
使用`AVMutableComposition`我们已经可以完成视频的拼接了，然后添加一段时长与总时间相等的`AVCompositionAudioTrack`就有了背景音乐，如果要调整多个音频轨道混合后各个轨道的音量，我们还需要另一个类`AVAudioMix`，`AVPlayerItem`也含有这一属性，在播放时应用混合音频参数。
 ### AVMutableAudioMix
`AVMutableAudioMix` 包含一组 `AVAudioMixInputParameters`，每个 `AVAudioMixInputParameters` 对应一个它控制的音频 `AVCompositionTrack`。
`AVAudioMixInputParameters` 包含一个 `MTAudioProcessingTap`，用来实时处理音频，一个`AVAudioTimePitchAlgorithm`，可以使用它来设置音调，这两个相对要稍微复杂一点，我们暂时不关注。现在我们想分别设置原视频和背景音乐轨道的的音量大小，可以使用`AVAudioMixInputParameters`提供的如如下方法：
```
// 从某个时间点开始，将音量变为volume
- (void)setVolume:(float)volume atTime:(CMTime)time
// 在timeRange时间内将音量线性变化，从startVolume逐渐变为endVolume
- (void)setVolumeRampFromStartVolume:(float)startVolume toEndVolume:(float)endVolume timeRange:(CMTimeRange)timeRange;
```
![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0d8g678qnj21js0u043p.jpg)

即通过创建每个音频轨道的`AVAudioMixInputParameters`，配置音量，将多个`AVAudioMixInputParameters`加入数组，作为`AVAudioMix`的`inputParameters`属性。

下面是拼接视频并添加背景音乐的代码示例：
```
// 1. 创建AVMutableComposition、AVMutableudioMix、和AVAudioMixInputParameters数组
AVMutableComposition *composition = [AVMutableComposition composition];
AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
NSMutableArray *audioMixInputParameters = [NSMutableArray array];

// 2. 插入空的音视频轨道
AVMutableCompositionTrack* videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
AVMutableCompositionTrack* audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];

// 记录已添加的视频总时间
CMTime startTime = kCMTimeZero;
CMTime duration = kCMTimeZero;
// 拼接视频
for (int i = 0; i < assetArray.count; i++) {
    AVAsset* asset = assetArray[i];
    AVAssetTrack* videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    AVAssetTrack* audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    // 3. 轨道中插入对应的音视频
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:startTime error:nil];
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:audioTrack atTime:startTime error:nil];
    
    // 4. 配置原视频的AVMutableAudioMixInputParameters     
    AVMutableAudioMixInputParameters *audioTrackParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
    // 设置原视频声音音量
    [audioTrackParameters setVolume:0.2 atTime:startTime];
    [audioMixInputParameters addObject:audioTrackParameters];
    // 设置原视频声音音量
    [audioTrackParameters setVolume:0.2 atTime:startTime];
    [audioMixInputParameters addObject:audioTrackParameters];
        
    // 拼接时间
    startTime = CMTimeAdd(startTime, asset.duration);
};

// 5. 添加BGM音频轨道
AVAsset *bgmAsset = ...;
AVMutableCompositionTrack *bgmAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
AVAssetTrack *bgmAssetAudioTrack = [[bgmAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
[bgmAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration) ofTrack:bgmAssetAudioTrack atTime:kCMTimeZero error:nil];
AVMutableAudioMixInputParameters *bgAudioTrackParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:bgmAudioTrack];
// 6. 设置背景音乐音量
[bgAudioTrackParameters setVolume:0.8 atTime:kCMTimeZero];
[audioMixArray addObject:bgAudioTrackParameters];
// 7. 设置inputParameters
audioMix.inputParameters = audioMixArray;

// 使用AVPlayerViewController预览
AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc]init];
// 使用AVMutableComposition创建AVPlayerItem
AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:composition];
// 8. 将音频混合参数传递给AVPlayerItem
playerItem.audioMix = audioMix;
playerViewController.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
playerViewController.view.frame = self.view.frame;
[playerViewController.player play];
[self presentViewController:playerViewController animated:YES completion:nil];
```
最简单的视频拼接和添加背景音乐的功能就完成了，但是大概率会出现视频方向和尺寸不正确的问题，我们希望能像控制音轨音量一样，控制每一段视频轨道的合成方式，甚至添加视频过渡效果，这时候我们需要`AVVideoComposition`，顺便我们实现一个"叠化"的视频转场的效果。
 ## 视频转场
 ### AVMutableVideoComposition
`AVVideoComposition`从iOS4.0开始支持，从命名看起来 `AVVideoComposition` 好像跟 `AVComposition` 好像是有什么血缘关系，事实并非如此，`AVVideoComposition` 继承自 `NSObject` ，我们可以把它看做与同样继承自 `NSObject` 的 `AVAudioMix` 平级，一个负责音频轨道的合成控制，一个负责对多个视频轨道的合成控制。

创建`AVMutableVideoComposition `的方法如下：
```
// 返回属性为空的实例
+ (AVMutableVideoComposition *)videoComposition;
// 返回包含了适合的指令的实例
+ (AVMutableVideoComposition *)videoCompositionWithPropertiesOfAsset:(AVAsset *)asset API_AVAILABLE(macos(10.9), ios(6.0), tvos(9.0)) API_UNAVAILABLE(watchos);
// iOS13.0新增，为了在创建时直接设置好背景色
+ (AVMutableVideoComposition *)videoCompositionWithPropertiesOfAsset:(AVAsset *)asset prototypeInstruction:(AVVideoCompositionInstruction *)prototypeInstruction API_AVAILABLE(macos(10.15), ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
```
AVMutableVideoComposition部分属性列表：
```
//视频每一帧的刷新时间
@property (nonatomic) CMTime frameDuration;

//视频显示时的大小范围
@property (nonatomic) CGSize renderSize;

//视频显示范围大小的缩放比例
@property (nonatomic) float renderScale;

//描述视频集合中具体视频播放方式信息的集合。
@property (nonatomic, copy) NSArray<id <AVVideoCompositionInstruction>> *instructions;

//这三个属性设置了渲染帧时的颜色空间、矩阵、颜色转换函数，可用的在 AVVideoSetting.h 文件中定义
@property (nonatomic, nullable) NSString *colorPrimaries NS_AVAILABLE(10_12, 10_0);
@property (nonatomic, nullable) NSString *colorYCbCrMatrix NS_AVAILABLE(10_12, 10_0);
@property (nonatomic, nullable) NSString *colorTransferFunction NS_AVAILABLE(10_12, 10_0);

// iOS 15新增，告诉视频合成对象合成的元数据样本相关的轨道ID
@property (nonatomic, copy) NSArray<NSNumber *> *sourceSampleDataTrackIDs;
```
从属性列表可以看出，从一个  `AVMutableVideoComposition` 输出视频时，我们还可以指定输出的尺寸`renderSize`(裁剪功能)、缩放比例`renderScale`、帧率`frameDuration`等。同时`AVPlayerItem`也含有`videoComposition`属性，在播放时按照合成指令显示视频内容。

> `AVVideoComposition`和`AVAudioMix`都没有和`AVComposition`强相关，这样做的好处是我们在预览、导出、获取视频缩略图功能上能够更灵活的使用。

### AVMutableVideoCompositionInstruction
`videoComposition` 最重要的一个属性是 `instructions`，数组包含一个或多个`AVMutableVideoCompositionInstruction`，它拥有`backgroundColor`属性用来修改视频的背景色，此外最关键的一个属性是`timeRange`，它描述了一段组合形式出现的时间范围。

AVMutableVideoCompositionInstruction属性和方法列表：
```
// 指令适用的时间范围。
@property (nonatomic) CMTimeRange timeRange;
// 视频合成的背景颜色。
@property (nonatomic, retain, nullable) __attribute__((NSObject)) CGColorRef backgroundColor;

// 指定如何从源轨道分层和编写视频帧的说明。
@property (nonatomic, copy) NSArray<AVVideoCompositionLayerInstruction *> *layerInstructions;
// 指示指令是否需要后期处理。
@property (nonatomic) BOOL enablePostProcessing;

// 合成器合成视频帧所遵循的指令需要的轨道id。
@property (nonatomic) NSArray<NSValue *> *requiredSourceTrackIDs;

// passthrough轨道id
@property (nonatomic, readonly) CMPersistentTrackID passthroughTrackID; 

// iOS15新增，用于视频元数据合成。
@property (nonatomic) NSArray<NSNumber *> *requiredSourceSampleDataTrackIDs;
```
> 这里注意一下`AVMutableVideoCompositionLayerInstruction`拥有一个`passthroughTrackID`属性，尽管在可变类中也还是个只读属性。

### AVMutableVideoCompositionLayerInstruction
`AVMutableVideoCompositionInstruction`拥有一个`layerInstructions`属性，数组中是`AVMutableVideoCompositionLayerInstruction`类型的实例，通过`AVMutableCompositionTrack`创建`，或与之trackID关联，描述了对于该轨道的合成方式，提供了用于修改特定的时间点或者一个时间范围内线性变化的transform、crop、opacity的方法，如下，可做的事情并不多。

```
// 渐变仿射变换
- (void)setTransformRampFromStartTransform:(CGAffineTransform)startTransform toEndTransform:(CGAffineTransform)endTransform timeRange:(CMTimeRange)timeRange;
// 仿射变换，还可以用来修正视频方向
- (void)setTransform:(CGAffineTransform)transform atTime:(CMTime)time;
// 透明度渐变
- (void)setOpacityRampFromStartOpacity:(float)startOpacity toEndOpacity:(float)endOpacity timeRange:(CMTimeRange)timeRange;
// 设置透明度
- (void)setOpacity:(float)opacity atTime:(CMTime)time;
// 裁剪区域渐变
- (void)setCropRectangleRampFromStartCropRectangle:(CGRect)startCropRectangle toEndCropRectangle:(CGRect)endCropRectangle timeRange:(CMTimeRange)timeRange;
// 设置裁剪区域
- (void)setCropRectangle:(CGRect)cropRectangle atTime:(CMTime)time;
```
综上，`AVMutableVideoComposition`用于视频合成，对视频组合做一个总体描述，`AVMutableVideoCompositionInstruction`用于规定其包含的`AVMutableVideoCompositionLayerInstruction`集合所控制的时间范围，而`AVMutableVideoCompositionLayerInstruction`是描述具体轨道混合时的呈现形式。那么这里有一个问题：为什么要这样分别设计三个类？我们先往下看。

我们先从创建`AVMutableVideoComposition`的第一种方法`+ (AVMutableVideoComposition *)videoComposition`说起，他会返回一个属性基本都是空的实例，我们从零去创建，这样可以更好理解。

要将两段视频进行混合，首先需要两段视频在时间线上含有重叠的区域，之后分别创建各自在混合区域中的出现或消失的指令。苹果官方文档介绍，每一个视频轨道都会配置一个单独的解码器，不建议添加过多的轨道，我们通常使用A/B轨道法——即创建两段视频轨道，将avassetTrack交替插入A/B轨道中，如下图，我们需要对段视频添加相应的instruction，不包含重叠区域的称为pass through，只需要指定时间范围即可，重叠区域称为transition，需要一个描述前一个视频隐藏方式的layerInstruction指令和描述后一个视频出现方式的layerInstruction指令。

![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0d0auydgzj21680dymyk.jpg)

每一个instruction都要设置好控制的时间范围，一旦出现指令时间范围没有拼接完整或出现交叉等情况就会产生错误，例如崩溃或者无法正常播放，在合成前我们可以调用AVVideoComposition的`- (BOOL)isValidForAsset: timeRange: validationDelegate:`以检查指令描述的时间范围是否可用，其中`delegate`要求遵守的`AVVideoCompositionValidationHandling`的协议提供的方法给了我们更多的错误信息描述，如果不需要也可以传`nil`。

`transition`部分的`AVMutableVideoCompositionInstruction`创建示例（叠化效果）：
```
    CMTimeRange atTime_end = kCMTimeRangeZero;
    __block CMTimeRange atTime_begin = kCMTimeRangeZero;
    NSMutableArray* layerInstructions = [NSMutableArray array];
    // 视频合成指令
    AVMutableVideoCompositionInstruction *videoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    videoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    
    for (int i = 0; i < compositionVideoTracks.count; i++) {
        AVMutableCompositionTrack *compositionTrack = compositionVideoTracks[i];
        AVAsset *asset = assets[i];
        // layerInstruction
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionTrack];
        if (compositionVideoTracks.count > 1) {
            // 叠化掉过
            atTime_begin = atTime_end;
            atTime_end =  CMTimeRangeMake(CMTimeAdd(CMTimeSubtract(atTime_end.start, transTime), asset.duration), transTime);
            CMTimeRangeShow(atTime_begin);
            CMTimeRangeShow(atTime_end);
            if (i == 0) {
                [layerInstruction setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.0 timeRange:atTime_end];
            } else if (i == compositionVideoTracks.count - 1) {
                [layerInstruction setOpacityRampFromStartOpacity:0.0 toEndOpacity:1.0 timeRange:atTime_begin];
            } else{
                [layerInstruction setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.0 timeRange:atTime_end];
                [layerInstruction setOpacityRampFromStartOpacity:0.0 toEndOpacity:1.0 timeRange:atTime_begin];
            }
        }
        [layerInstructions addObject:layerInstruction];
    }
    videoCompositionInstruction.layerInstructions = layerInstructions;
```

当然，这么麻烦逐个地创建"pass through instruction"和"transition instruction"肯定不是我们想要的，上面介绍的方式是使用`+ (AVMutableVideoComposition *)videoComposition;`方法创建`AVMutableVideoComposition`，返回的是一个各个属性都为空的对象，所以需要我们逐个添加指令。

苹果还给我们提供了一个`+ (AVMutableVideoComposition *)videoCompositionWithPropertiesOfAsset:(AVAsset *)asset`方法，传入添加好视频轨道的`AVMutableComposition`，方法返回的`AVMutableVideoComposition`实例包含了设置好的属性值和适用于根据其时间和几何属性以及其轨道的属性呈现指定资产的视频轨道的指令，简单的说就是instructons和其layerInstructions都已经为我们创建好了，我们可以直接从中取出transition时间段中的fromLayerInstruction和toLayerInstruction，一个消失一个显示，就能够完成视频转场效果了，这两种创建videoComposition的方式称为内置合成器（Bultin-in Compositor），虽然有着施展空间不足的问题，但是优点是苹果对于这种已经经过封装的接口能够自动针对新的技术或设备的适配，例如WWDC2021提到的对HDR视频文件的适配，内置合成器会将含有HDR视频合成输出一个HDR视频。

苹果在iOS9.0开始又提供了可以对视频使用CIFilter添加类似模糊、色彩等滤镜效果的方式来创建`AVMutableVideoComposition`：
`+ (AVMutableVideoComposition *)videoCompositionWithAsset:(AVAsset *)asset
applyingCIFiltersWithHandler:(void (^)(AVAsynchronousCIImageFilteringRequest *request))applier`，不过这种方式只有使用系统的CIFilter才能支持HDR的合成导出，否则需要修改参数。
```
CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
AVMutableVideoComposition  *videocomposition = [AVMutableVideoComposition videoCompositionWithAsset:asset applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
    // 获取源ciimage
    CIImage *source = request.sourceImage.imageByClampingToExtent;
    // 添加滤镜
    [filter setValue:source forKey:kCIInputImageKey];
    Float64 seconds = CMTimeGetSeconds(request.compositionTime);
    CIImage *output = [filter.outputImage imageByCroppingToRect:request.sourceImage.extent];
    filter setValue:seconds * 10.0 forKey:kCIInputRadiusKey];
    // 提交输出
    [request finishWithImage:output context:nil];
}];
```

**注意**: 使用该方法创建的`AVMutableVideoComposition`实例，其`instructions`数组中的数据类型就成了私有类[`AVCoreImageFilterVideoCompositionInstruction`](https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/AVFoundation.framework/AVCoreImageFilterVideoCompositionInstruction.h)，官方文档没有任何资料，我们没法创建或者修改它和它的`layerInstructions`，不过我们可以使用`CIAffineTransform`的`CIilter`直接调整`sourceImage`的方向，修正方向问题。

在iOS13.0又提供了`+ (AVMutableVideoComposition *)videoCompositionWithPropertiesOfAsset:(AVAsset *)asset prototypeInstruction:(AVVideoCompositionInstruction *)prototypeInstruction`方法，我们可以提前创建一个原型指令，将背景色进行设置，之后调用该方法创建`AVMutableVideoComposition`就可以得到一个各段instruction背景色都设置好的`AVMutableVideoComposition`实例。

但是要实现完全的自定义转场或者自定义合成，能够做到对每一帧做处理，这些方法还是不够，苹果在iOS7.0在`AVMutableVideoComposition`类中新增了`customVideoCompositorClass`属性，它要求一个遵守了`AVVideoCompositing`协议的类，注意，这里需要传的是一个类。
```
@property (nonatomic, retain, nullable) Class<AVVideoCompositing> customVideoCompositorClass;
```
AVVideoCompositing协议定义如下：

```
@protocol AVVideoCompositing<NSObject>
// 源PixelBuffer的属性
@property (nonatomic, nullable) NSDictionary<NSString *, id> *sourcePixelBufferAttributes;
// VideoComposition创建的PixelBuffer的属性
@property (nonatomic) NSDictionary<NSString *, id> *requiredPixelBufferAttributesForRenderContext;
// 通知切换渲染上下文
- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext;
// 开始合成请求，在
- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)asyncVideoCompositionRequest;
// 取消合成请求
- (void)cancelAllPendingVideoCompositionRequests;
```
其中`startVideoCompositionRequest`方法中的`AVAsynchronousVideoCompositionRequest`对象，拥有`- (CVPixelBufferRef)sourceFrameByTrackID:(CMPersistentTrackID)trackID;`方法，可以获某个轨道此刻需要合成的`CVPixelBufferRef`，之后我们就可以自定义合成方式了，结合、core image、opengles或者metal等实现丰富的效果。

创建自定义合成器示例：
```
// 返回源PixelBuffer的属性
- (NSDictionary *)sourcePixelBufferAttributes {
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}
// 返回VideoComposition创建的PixelBuffer的属性
- (NSDictionary *)requiredPixelBufferAttributesForRenderContext {
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}
// 通知切换渲染上下文
- (void)renderContextChanged:(nonnull AVVideoCompositionRenderContext *)newRenderContext {
}
// 开始合成请求
- (void)startVideoCompositionRequest:(nonnull AVAsynchronousVideoCompositionRequest *)request {
    @autoreleasepool {
        dispatch_async(_renderingQueue, ^{
            if (self.shouldCancelAllRequests) {
                // 用于取消合成 
                [request finishCancelledRequest];
            } else {
                NSError *err = nil;
                CVPixelBufferRef resultPixels = nil;
                //获取当前合成指令 
                AVVideoCompositionInstruction *currentInstruction = request.videoCompositionInstruction;
                // 获取指定trackID的轨道的PixelBuffer
                CVPixelBufferRef currentPixelBuffer = [request sourceFrameByTrackID:currentInstruction.trackID];
                // 在这里就可以进行自定义的处理了
                CVPixelBuffer resultPixels = [self handleByYourSelf:currentPixelBuffer];
                
                if (resultPixels) {
                    CFRetain(resultPixels);
                    // 处理完毕提交处理后的CVPixelBufferRef
                    [request finishWithComposedVideoFrame:resultPixels];
                    CFRelease(resultPixels);
                } else {
                    [request finishWithError:err];
                }
            }
        });
    }
}
// 取消合成请求
- (void)cancelAllPendingVideoCompositionRequests {
    _shouldCancelAllRequests = YES;
    dispatch_barrier_async(_renderingQueue, ^() {
        self.shouldCancelAllRequests = NO;
    });
}
```
流程可分解为：
1. AVAsynchronousVideoCompositionRequest绑定了当前时间的一系列原始帧，以及当前时间所在的 Instruction。
2. 收到startVideoCompositionRequest: 回调，并接收到这个 Request。
3. 根据原始帧及Instruction 相关混合参数，渲染得到合成的帧。
4. 调用finishWithComposedVideoFrame，交付渲染后的帧。

在创建并使用自定义合成器后，我们通常不再使用`AVVideoCompositionInstruction`，而是遵守`AVVideoCompositionInstruction`遵守的`AVVideoCompositionInstruction`协议，创建自定义的合成指令。为什么？

因为我们自定义的合成器类，是作为一个类传递给`AVVideoComposition`，而不是一个属性，在实际合成渲染的时候都是在自定义合成器内部进行的，这就是说我们实际上拿不到自定义合成器的对象，那我们怎么告诉合成器我们设计的五花八门的合成方式呢？`AVAsynchronousVideoCompositionRequest`中可以拿到`AVVideoCompositionInstruction`实例，所以我们只要遵循`AVVideoCompositionInstruction`协议创建自己的合成指令类，我们就可以随意添加参数传递给合成器内，完成数据流通。

AVVideoCompositionInstruction协议内容如下：

```
@protocol AVVideoCompositionInstruction<NSObject>
@required
// 指令适用的时间范围
@property (nonatomic, readonly) CMTimeRange timeRange;
// 指示指令是否需要后期处理
@property (nonatomic, readonly) BOOL enablePostProcessing;
// YES表示从相同的源buffer在相同的组合指令下在两个不同的和城市间下渲染帧和可能会产生不同的输出帧。NO值表示两个组合物产生相同的帧。
@property (nonatomic, readonly) BOOL containsTweening;
// 合成器合成视频帧所遵循的指令需要的轨道id
@property (nonatomic, readonly, nullable) NSArray<NSValue *> *requiredSourceTrackIDs;
// 在不合成的情况下通过源轨道的标识符
@property (nonatomic, readonly) CMPersistentTrackID passthroughTrackID; 

@optional
// iOS15新增，用于视频元数据合成
@property (nonatomic, readonly) NSArray<NSNumber *> *requiredSourceSampleDataTrackIDs;

@end
```

通过比较可以发现，`AVVideoCompositionInstruction`类与`AVVideoCompositionInstruction`协议的内容基本一致，只是多了`backgroundCoclor`和`layerInstructions`属性。也可以说苹果只是遵循了`AVVideoCompositionInstruction`协议，创建了一个我们看到的"系统的类"`AVVideoCompositionInstruction`，而`AVVideoCompositionInstruction`类只是新增了一个修改背景色的“设计”和一个用于传递合成细节的`layerInstructions`属性，为我们做了一个简单的范例。

那合成器的`startVideoCompositionRequest:`方法每次都必须执行吗？我们在讲转场的开始将指令分为了"pass through"和"transition"，理论上我们既然规定了某一段指令属于"pass through"，那就应该直接通过，不必请求合成，这里就需要前面的只读属性`passthroughTrackID`了，不过在我们遵循协议创建自己的"CustomMutableVideoCompositionInstruction"后，我们可以进行修改了，在设置了`passthroughTrackID`之后，就不会在需要"pass through"该段轨道时调用`startVideoCompositionRequest:`方法了。

> 经测试，使用`+ (AVMutableVideoComposition *)videoCompositionWithPropertiesOfAsset:(AVAsset *)asset`方法构建的合成器，其自动为我们创建好的`AVMutableVideoCompositionLayerInstruction`的`passthroughTrackID`值是nil。

到这里，前面的问题就好解释了：为什么要分别设这三个类？

要合成视频首先需要一个遵循了合成协议的合成器，一个遵循合成指令协议的类来指定分段的时间范围，但是我们不一定需要`AVVideoCompositionLayerInstruction`类来控制合成细节，所以这三者是分开设计，`AVVideoCompositionLayerInstruction`只是系统的示例为了要传递参数而封装的容器。

综上，一个完整的自定义视频合成器的过程应该是这样的：
1. 通过`AVAsset(s)`构建`AVMutableComposition`实例`composition`；
2. 通过`composition`创建`AVMutableVideoComposition`实例`videoComposition`；
3. 创建自定义合成器和自定义合成指令；
4. 设置`videoComposition`的`customVideoCompositorClass`设置为自定义合成器；
5. 将`videoCompositio`n的`instructions`中的指令替换为自定义合成指令，并分别配置各段的自定义合成参数。
6. 在自定义合成器中的`startVideoCompositionRequest:`方法中取出自定义合成指令，根据指令的合成参数处理每一帧的合成。

最后我们解释一下iOS15新增的两个属性的作用——时基元数据合成：iOS15支持自定义时基元数据合成，WWDC举的例子是我们有一系列GPS数据，并且该数据带有时间戳并与视频同步，如果希望使用这些GPS数据来影响帧的组合方式，第一步需要先把GPS数据写入源电影中的定时元数据轨道(我们可以使用`AVAssetWriter`)，之后我们可以使用`AVMutableVideoComposition`新的`sourceSampleDataTrackIDs`属性告诉合成器需要合成的时基元数据轨道ID，设置`AVMutableVideoCompositionInstruction`的`requiredSourceSampleDataTrackIDs`属性以告诉它与当前指令相关的轨道ID，最后在自定义合成器中获取元数据执行自定义合成。

WWDC2021的示例：
```
func startRequest(_ request: AVAsynchronousVideoCompositionRequest){
    for trackID in request.sourceSampleDataTrackIDs {
        // 也可以使用sourceSampleBuffer(byTrackID:获取CMSampleBuffer
        let metadata: AVTimedMetadataGroup? = request.sourceTimedMetadata(byTrackID: trackID
        // 执行自定义合成操作
        using metadata, here.
    }
    request.finish(withComposedVideoFrame: composedFrame)
}
```
## 添加文字、贴纸
虽然我们可以处理`CVPixelBuffer`了，要实现文字贴纸都不难了，不过我们还有更简单的方式，使用我们熟悉的`Core Animation`框架，AVFoundation为我们从播放和导出视频分别提供了对接`Core Animation`的方式。
### 播放-AVSynchronizedLayer
AVFoundation提供了一个专门`的CALayer`子类`AVSynchronizedLayer`，用于与给定的`AVPlaverltem`实例同步时间。这个图层本身不展示任何内容，只是用来与图层子树协同时间。通常使用`AVSynchronizedLayer`时会将其整合到播放器视图的图层继承关系中，`AVSynchronizedLayer`直接呈现在视频图层之上，这样就可以添加标题、贴纸或者水印到播放视频中，并与播放器的行为保持同步。

![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0fctujnu4j21e60teq4u.jpg)

日常使用`Core Animation`时，时间模型取决于系统主机，主机的时间不会停止，但是视频动画有其自己的时间线，同时还要支持停止、暂停、回退或快进等效果，所以不能直接用系统主机的时间模型向一个视频中添加基于时间的动画，所以动画的`beginTime` 不能直接设置为0.0了，因为它会转为`CACurrentMediaTime()`代表当前的主机时间，苹果官方文档还说到，任何具有动画属性的`CoreAnimation`层，如果被添加为`AVSynchronizedLayer`的子层，应该将动画的`beginTime`属性设置为一个非零的正值，这样动画才能在playerItem的时间轴上被解释。此外我们必须设置`removedOnCompletion = NO`，否则动画就是一次性的。

我们直接以gif表情包贴纸为例，可以直接使用上面提到的gif获取每一帧图片和其停留时间的代码。

```
// 创建gif关键帧动画
CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
animation.beginTime = AVCoreAnimationBeginTimeAtZero;
animation.removedOnCompletion = NO;
// 获取gif的图片images和停留时间数组times
// 使用上文中的实例代码
// 设置动画时间点的contents对应的gif图片
animation.keyTimes = times;
animation.values = images;
animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
animation.duration = totalTime;
animation.repeatCount = HUGE_VALF;

// 创建gif图层
_gifLayer = [CALayer layer];
_gifLayer.frame = CGRectMake(0, 0, 150, 150);
[_gifLayer addAnimation:animation forKey:@"gif"];

// 播放器
AVPlayerViewController *playerVC = [[AVPlayerViewController alloc] init];
AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:_asset];
AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
playerVC.player = player;

// 创建AVSynchronizedLayer
AVSynchronizedLayer *asyLayer = [AVSynchronizedLayer synchronizedLayerWithPlayerItem:playerItem];

// 将gif图层添加到asyLayer
[asyLayer addSublayer:_gifLayer];
// 将asyLayer图层添加到播放器图层
[playerVC.view.layer addSublayer:asyLayer];
[player play];
```
播放过程添加贴纸文字动画等效果就完成了，导出视频我们还需要`AVVideoCompositionCoreAnimationTool`。
### 导出-AVVideoCompositionCoreAnimationTool
`AVMutableVideoComposition`拥有一个`AVVideoCompositionCoreAnimationTool`类型的属性`animationTool`，构建`AVVideoCompositionCoreAnimationTool`的常用是`+ (instancetyp*)videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:(CALayer *)videoLayer inLayer:(CALayer *)animationLayer;`，其中要求我们传递了两个`CALayer`的对象，一个VideoLayer一个animationLayer，苹果官方文档解释，将视频的合成帧与animationLayer一起渲染形成最终的视频帧，videoLayer应该在animationLayer的子图层中，animationLayer不应该来自或被添加到任何其他的图层树中。

![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0d0b3sh90j21e10u0ju8.jpg)
```
//创建一个合并图层
CALayer *animationLayer = [CALayer layer];

//创建一个视频帧图层，将承载组合的视频帧
CALayer *videoLayer = [CALayer layer];
[animationLayer addSublayer:videoLayer];
[animationLayer addSublayer:gifLayer];

// 创建AVVideoCompositionCoreAnimationTool与videoComposition的animationTool关联
AVVideoCompositionCoreAnimationTool *animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:animationLayer];
self.videoComposition.animationTool = animationTool;
```
**注意**：在为videoComposition配置了animationTool之后，就不能再用于播放的playItem了，AVVideoCompositionCoreAnimationTool只能用于AVAssetExportSession和AVAssetReader这种离线渲染，不能用于实时渲染。

# 导出
## AVAssetExportSession
导出部分比较简单，只需要把前面创建的合成参数传递给导出用的实例即可。导出部分的核心类是`AVAssetExportSession`，创建一个`AVAssetExportSession`需要传递一个`asset`和一个预设参数`presetName`，预设参数支持`H.264`、`HEVC`、`Apple ProRes`编码，支持不同的视频分辨率，支持不同的视频质量级别，不过并非所有`presetName`都与所有`asset`和文件类型兼容，因此我们应该导出之前调用下面的放法来检查特定组合的兼容性，检查方法如下：
```
+ (void)determineCompatibilityOfExportPreset:(NSString *)presetName
withAsset:(AVAsset *)asset
outputFileType:(AVFileType)outputFileType
completionHandler:(void (^)(BOOL compatible))handler;
```
下面列举了`AVAssetExportSession` 重要的属性。
```
// 导出的文件类型，容器格式
@property (nonatomic, copy, nullable) AVFileType outputFileType;
// 导出的路径
@property (nonatomic, copy, nullable) NSURL *outputURL;
// 是否针对网络使用进行优化
@property (nonatomic) BOOL shouldOptimizeForNetworkUse;
// 导出的状态
@property (nonatomic, readonly) AVAssetExportSessionStatus status;
// 音频混合参数
@property (nonatomic, copy, nullable) AVAudioMix *audioMix;
// 视频合成指令
@property (nonatomic, copy, nullable) AVVideoComposition *videoComposition;
// 元数据
@property (nonatomic, copy, nullable) NSArray<AVMetadataItem *> *metadata;
// 元数据标识
@property (nonatomic, retain, nullable) AVMetadataItemFilter *metadataItemFilter;
// 导出的进度
@property (nonatomic, readonly) float progress;
```
从属性列表中我们可以看到，`AVAssetExportSession` 拥有视频合成需要的几个关键属性，音频的混合方式`AVAudioMix`、视频的合成方式`AVVideoComposition`都可以在导出时应用。

导出是一个相对耗时的操作，`AVAssetExportSession` 提供了异步导出的接口`- (void)exportAsynchronouslyWithCompletionHandler:(void (^)(void))handler`，在block中我们可以随时获取`progress`导出进度，同时根据`AVAssetExportSessionStatus`的值，来观察导出结果是否符合预期。
```
// 通过composition和presetName创建AVAssetExportSession
self.exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHEVCHighestQuality];
// 配置合成视频参数
self.exportSession.videoComposition = videoComposition;
// 配置音频混合参数
self.exportSession.audioMix = audioMix;
// 配置输出url地址
self.exportSession.outputURL = [NSURL fileURLWithPath:path];
// 配置输出的文件格式
self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
// 开始异步导出
[self.exportSession exportAsynchronouslyWithCompletionHandler:^(void){
    // 监听导出状态
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
            NSLog(@"AVAssetExportSessionStatusCancelled");
            break;
        default:
        break;
    }
}];
```

前面我们还学习了使用`AVAssetReader`和`AVAssetWriter`配合来重新编码写入文件的方式，其中`AVAssetReaderAudioMixOutput`拥有`audioMix`属性，`AVAssetReaderVideoCompositionOutput`拥有`videoCompositionOutput`属性，这样的话整个`composition`的合成配置都可以作为`AVAssetReaderOutput`的参数了。
现在我们已经学习两种导出文件的方式`AVAssetExportSession`和`AVAssetWriter`。如果只要简单的导出为某种文件格式，不对细节有很高的要求，使用`AVAssetExportSession`就足够了， 而使用`AVAssetWriter`的优势是可以通过指定比特率、帧率、视频帧尺寸、色彩空间、关键帧间隔、视频比特率、H.264配置文件、像素宽高比甚至用于导出的视频编码器等等，我们可以完全控制导出过程。
# 总结：
最后用一张图片总结一下本文的内容：
![](https://tva1.sinaimg.cn/large/e6c9d24ely1h0dsx5od9wj227y0hswhc.jpg)

demo地址: [https://github.com/itdongqiang/AVFoundationProject](https://github.com/itdongqiang/AVFoundationProject)\
功能包含：
- 音频：
    1. AVAudioPlayer音频播放
    2. AVAudioEngineRecorder音频录制
- 视频：
    1. 视频拼接合成、添加背景音乐、叠化转场效果
    2. 视频添加贴纸、文字、gif表情包
- 图片： 
    1. 普通图片转视频
    2. 实况照片转视频、gif转视频
- 其他：
    1. 获取文件元数据样本格式信息   

参考文档

[developer.apple.com/documentation/avfoundation/](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app?language=objc)\
[wwdc2021-What’s new in camera capture](https://developer.apple.com/videos/play/wwdc2021/10047/)\
[wwdc2021-What’s new in AVFoundation](https://developer.apple.com/videos/play/wwdc2021/10146/)\
[wwdc2020-Edit and play back HDR video with AVFoundation](https://developer.apple.com/videos/play/wwdc2020/10009/)\
[wwdc2020-What’s new in camera capture](https://developer.apple.com/videos/play/wwdc2021/10047/)\
