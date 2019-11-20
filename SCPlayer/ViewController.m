//
//  ViewController.m
//  SCPlayer
//
//  Created by 石川 on 2019/11/14.
//  Copyright © 2019 石川. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <WebKit/WebKit.h>
#import "Aspects.h"
#import "NSObject+BlockObserver.h"
#import "UIView+ViewDesc.h"
#import "Thumbnail.h"
@interface ViewController ()
@property (nonatomic, strong) AVPlayer *player;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *playView;
@property (weak, nonatomic) IBOutlet UIButton *start_Pause;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (nonatomic,strong)AVPlayerViewController *playerController;
@property (nonatomic,strong)WKWebView *weView;
@property(nonatomic,strong) AVPlayerItemVideoOutput * playerOutput;
@property (nonatomic,strong)AVPlayerItem *item;
@property (nonatomic,assign)BOOL canPlay;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (nonatomic,assign)float allTime;
@property (nonatomic,assign)float currentTime;
@property (weak, nonatomic) IBOutlet UILabel *canPlayTime;

/*
 正在拖拽
 */

- (IBAction)getPhoto:(UIButton *)sender;
- (IBAction)addUrl:(UIButton *)sender;
//增加一个关闭按钮
@property (nonatomic, strong) UIControl *closeControl;
@property (weak, nonatomic) IBOutlet UILabel *timePross;
@property (weak, nonatomic) IBOutlet UILabel *timeAll;
@property (nonatomic,assign)BOOL centUpdatTime;


@end

@implementation ViewController

- (AVPlayer *)player {
    if (!_player) {
        //初始化播放器对象
        _player = [[AVPlayer alloc] init];
        
        //显示画面
        AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:_player];
        //设置画布frame
        layer.frame = self.playView.bounds;
        //视频填充模式
        layer.videoGravity = AVLayerVideoGravityResizeAspect;
        
    }
    return _player;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self addItem];
    //    [self addWK];
    //    [self addVCPlay];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.progressSlider addGestureRecognizer:tap];
    
    
    
    [self.progressSlider addTarget:self action:@selector(handleTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.progressSlider addTarget:self action:@selector(handleTouchUp:) forControlEvents:UIControlEventTouchUpInside];
}
-(void)addItem
{
    NSURL *url = [NSURL URLWithString:@"http://app-new.pudongtv.cn:8006/MP4http/gx1/pddst/video/2019/11/12/e238306ea17d5468599bc2a6749cbba0/playlist.m3u8"];
    // 初始化播放单元
    self.item = [AVPlayerItem playerItemWithURL:url];
    self.playerOutput = [[AVPlayerItemVideoOutput alloc] init];
    [self.item addOutput:self.playerOutput];
    [self.player replaceCurrentItemWithPlayerItem:self.item];
    
    [self addObserverToPlayerItem:self.item];
    //    self.playView.transform = CGAffineTransformRotate(self.view.transform, M_PI_2);//控件横屏
    self.centUpdatTime = YES;
}
- (void)setupUI {
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = self.playView.bounds;
    [self.playView.layer addSublayer:playerLayer];
    [self addProgressObserver];
}
- (void)timer
{
    return;
    
    
}

- (IBAction)startOrPauseClick:(UIButton *)sender {
    if (self.player.rate == 0) {
        [sender setTitle:@"stop" forState:UIControlStateNormal];
        
        if (self.canPlay) {
            [self.player play];
        }
        
    } else if (self.player.rate > 0) {
        [sender setTitle:@"play" forState:UIControlStateNormal];
        [self.player pause];
    }
}

#pragma mark - 监听
- (void)addProgressObserver {
    __weak typeof(self) weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        float allTimeF = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
        float currentTimeF = CMTimeGetSeconds(weakSelf.player.currentItem.currentTime);
        weakSelf.allTime = allTimeF;
        weakSelf.currentTime = currentTimeF;
       if (weakSelf.centUpdatTime) {
             weakSelf.progressSlider.value = currentTimeF / allTimeF;
        }
       
        
        
        
        int allTime = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
        int currentTime = CMTimeGetSeconds(weakSelf.player.currentItem.currentTime);
        
        int allHour = allTime / (60*60);
        int allMin  = allTime / 60;
        int allSecond  = allTime % 60;
        
        int currentHour = currentTime / (60*60);
        int currentMin  = currentTime / 60;
        int currentSecond  = currentTime % 60;
        
        
        weakSelf.timeAll.text = [NSString stringWithFormat:@"%.2d:%.2d:%.2d",allHour,allMin,allSecond];
        weakSelf.timePross.text = [NSString stringWithFormat:@"%.2d:%.2d:%.2d",currentHour,currentMin,currentSecond];
        
    }];
}

- (void)addObserverToPlayerItem:(AVPlayerItem *)playerItem {
    
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        NSLog(@"状态%ld", (long)status);
        if (status == AVPlayerStatusReadyToPlay) {
            self.canPlay = YES;
            if ([self.start_Pause.titleLabel.text isEqualToString:@"stop"]) {
                [self.player play];
            }
        }else{
            self.canPlay = YES;
        }
    } else if([keyPath isEqualToString:@"loadedTimeRanges"]) {
        
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        //        NSTimeInterval totalBuffer = startSeconds + durationSeconds;;
        float progress = startSeconds+durationSeconds;
        self.progressView.progress = progress/self.allTime;
        
        
        
        int currentTime = progress;
        int currentHour = currentTime / (60*60);
        int currentMin  = currentTime / 60;
        int currentSecond  = currentTime % 60;
        self.canPlayTime.text = [NSString stringWithFormat:@"%.2d:%.2d:%.2d",currentHour,currentMin,currentSecond];
        
        if (self.currentTime<progress) {
            self.canPlay = YES;
            if ([self.start_Pause.titleLabel.text isEqualToString:@"stop"]) {
                [self.player play];
            }
        }else{
            self.canPlay = NO;
        }
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){
        NSLog(@"playbackBufferEmpty");
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        NSLog(@"playbackLikelyToKeepUp");
    }
    
    //    NSLog(@"===%@",change);
    
}

#pragma mark - 拖拽进度

- (IBAction)sliderChangeClick:(UISlider *)sender {
    self.centUpdatTime = NO;
    //拖拽的时候先暂停
    //    if (self.player.rate > 0) {
    //        [self.player pause];
    //    }
    
    
    //    float fps = [[[self.player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] nominalFrameRate];
    //    float fps = 60;//m3u8
    //    CMTime time = CMTimeMakeWithSeconds(CMTimeGetSeconds(self.player.currentItem.duration) * sender.value, fps);
    //    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
    //        if (finished) {
    //             NSLog(@"已经跳到时间对应的视频");
    //        }
    //    }];
    
}
#pragma mark - 点击调进度
- (void)tap:(UITapGestureRecognizer *)sender {
    
    self.centUpdatTime = NO;
    
    CGPoint touchPoint = [sender locationInView:self.progressSlider];
    CGFloat value = touchPoint.x / CGRectGetWidth(self.progressSlider.bounds);
    [self.progressSlider setValue:value animated:YES];
    [self sliderChangeClick:self.progressSlider];
    
    [self popTimePlay];
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        NSLog(@"结束点击");
        if ([self.start_Pause.titleLabel.text isEqualToString:@"stop"]) {
            if (self.canPlay) {
                [self.player play];
            }
        };
    }
    
}

#pragma mark - SliederAction
- (void)handleTouchDown:(UISlider *)slider{
    NSLog(@"TouchDown");
    if ([self.start_Pause.titleLabel.text isEqualToString:@"stop"]) {
        [self.player pause];
    };
    self.centUpdatTime = NO;
}

- (void)handleTouchUp:(UISlider *)slider{
    NSLog(@"TouchUp");
    if ([self.start_Pause.titleLabel.text isEqualToString:@"stop"]) {
        if (self.canPlay) {
            [self.player play];
        }
    };
    [self popTimePlay];
}
//调到播放
-(void)popTimePlay
{
    float fps = 60;//m3u8
    CMTime time = CMTimeMakeWithSeconds(CMTimeGetSeconds(self.player.currentItem.duration) * self.progressSlider.value, fps);
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        if (finished) {
            NSLog(@"已经跳到时间对应的视频");
            self.centUpdatTime = YES;
        }
    }];
}

- (IBAction)changeRateClick:(UIButton *)sender {
    if (![self.player.currentItem canPlayFastForward]) {
        return;
    }
    switch (sender.tag) {
        case 100:
            self.player.rate = 1.0;
            break;
        case 125:
            self.player.rate = 1.25;
            break;
        case 150:
            self.player.rate = 1.5;
            break;
        case 200:
            self.player.rate = 2.0;
            break;
        default:
            self.player.rate = 1.0;
            break;
    }
}
-(void)dealloc {
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}



- (IBAction)getPhoto:(UIButton *)sender {
    UIImage *img = [self screenshotsm3u8WithCurrentTime:self.player.currentTime playerItemVideoOutput:self.playerOutput];
    self.imageView.image = img;
    
}

- (IBAction)addUrl:(UIButton *)sender {
    [self addItem];
}

-(void)dimissSelf
{
    NSLog(@"=======");
}
-(UIImage *)screenshotsWithView:(UIView *)view{
    
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
-(UIImage *)screenshotsm3u8WithCurrentTime:(CMTime)currentTime playerItemVideoOutput:(AVPlayerItemVideoOutput *)output{
    
    CVPixelBufferRef pixelBuffer = [output copyPixelBufferForItemTime:currentTime itemTimeForDisplay:nil];
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext createCGImage:ciImage
                                                   fromRect:CGRectMake(0, 0,
                                                                       CVPixelBufferGetWidth(pixelBuffer),
                                                                       CVPixelBufferGetHeight(pixelBuffer))];
    UIImage *frameImg = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    //不释放会造成内存泄漏
    CVBufferRelease(pixelBuffer);
    return frameImg;
}



















-(void)addVCPlay
{
    NSURL *url = [NSURL URLWithString:@"https://stanserver.cn/video/cat1.mp4"];
    // 初始化播放单元
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    
    if (self.playerController) {
        self.playerController = nil;
    }
    
    self.playerController = [[AVPlayerViewController alloc] init];
    self.playerController.player = [[AVPlayer alloc] init];
    [self.playerController.player replaceCurrentItemWithPlayerItem:item];
    //拉伸模式
    self.playerController.videoGravity = AVLayerVideoGravityResizeAspect;
    //是否显示媒体播放组件
    self.playerController.showsPlaybackControls = YES;
    
    
    //    self.playerController.delegate = self;
    [self.playerController.player play];
    
    self.playerController.view.bounds = CGRectMake(0, 0, self.view.bounds.size.width, 300);
    self.playerController.view.center = CGPointMake(CGRectGetMidX(self.view.bounds), 64 + CGRectGetMidY(self.playerController.view.bounds) + 30);
    
    //在本VC播放
    [self addChildViewController:self.playerController];
    [self.view addSubview:self.playerController.view];
    [self getAVTouchIgnoringView];
}
-(void)addWK
{
    NSString *videoStr = @"https://stanserver.cn/video/cat1.mp4";
    
    //创建网页配置对象
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.mediaTypesRequiringUserActionForPlayback = NO;//把手动播放设置NO ios(8.0, 9.0)
    config.allowsInlineMediaPlayback = YES;// 是使用h5的视频播放器在线播放, 还是使用原生播放器全屏播放
    
    
    //偏好设置
    config.preferences.javaScriptEnabled = YES;//允许运行js
    
    //oc向html中注入js
    NSString *jSString = [NSString stringWithFormat:
                          @"var dom = document.getElementById(\"video\");\
                          dom.setAttribute(\"src\",'%@');\
                          dom.setAttribute(\"poster\",'%@')"
                          ,videoStr,@""];
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jSString injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [config.userContentController addUserScript:wkUScript];
    
    
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"SCPlay.html" withExtension:nil];
    self.weView = [[WKWebView alloc] initWithFrame:self.playView.frame configuration:config];
    self.weView.contentMode = UIViewContentModeScaleToFill;
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:fileURL];
    [self.weView loadRequest:request];
    [self.view addSubview:self.weView];
}

-(void)getAVTouchIgnoringView
{
    Class UIGestureRecognizerTarget = NSClassFromString(@"UIGestureRecognizerTarget");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [UIGestureRecognizerTarget aspect_hookSelector:@selector(_sendActionWithGestureRecognizer:) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo>info,UIGestureRecognizer *gest){
        if (gest.numberOfTouches == 1) {
            UIView *view = [gest.view findViewByClassName:@"AVVolumeButtonControl"];
            if (view) {
                while (view.superview) {
                    view = view.superview;
                    if ([view isKindOfClass:[NSClassFromString(@"AVTouchIgnoringView") class]]) {
                        
                        
                        [view HF_addObserverForKeyPath:@"hidden" block:^(__weak id object, id oldValue, id newValue) {
                            NSLog(@"newValue ==%@",newValue);
                            BOOL isHidden = [(NSNumber *)newValue boolValue];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.closeControl setHidden:isHidden];
                            });
                            
                        }];
                        break;
                    }
                }
            }
            
        }
        
    } error:nil];
    
#pragma clang diagnostic pop
    //这里必须监听到准备好开始播放了，才把按钮添加上去（系统控件的懒加载机制，我们才能获取到合适的 view 去添加），不然很突兀！
    [self.playerController.player HF_addObserverForKeyPath:@"status" block:^(__weak id object, id oldValue, id newValue) {
        AVPlayerStatus status = [newValue integerValue];
        if (status == AVPlayerStatusReadyToPlay) {
            UIView *avTouchIgnoringView = self.playerController.view;
            [avTouchIgnoringView addSubview:self.closeControl];
        }
    }];
    
}
- (UIControl *)closeControl
{
    if (!_closeControl) {
        _closeControl = [[UIControl alloc] init];
        [_closeControl addTarget:self action:@selector(dimissSelf) forControlEvents:UIControlEventTouchUpInside];
        _closeControl.backgroundColor = [UIColor colorWithRed:0.14 green:0.14 blue:0.14 alpha:0.8];
        _closeControl.tintColor = [UIColor colorWithWhite:1 alpha:0.55];
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        UIImage *normalImage = [UIImage imageNamed:@"closeAV.png" inBundle:bundle compatibleWithTraitCollection:nil];
        [_closeControl.layer setContents:(id)normalImage.CGImage];
        _closeControl.layer.contentsGravity = kCAGravityCenter;
        _closeControl.layer.cornerRadius = 17;
        _closeControl.layer.masksToBounds = YES;
        _closeControl.frame = CGRectMake(100, 100, 100, 100);
    }
    return _closeControl;
    
}





@end

