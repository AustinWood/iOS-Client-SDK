//
//  ViewController.m
//  TestApp
//
//  Copyright (c) 2015 Ziggeo Inc. All rights reserved.
//

#import "ViewController.h"
#import "Ziggeo/Ziggeo.h"
@import AVKit;

@interface ViewController () <ZiggeoRecorderDelegate> {
    Ziggeo* m_ziggeo;
    ZiggeoPlayer* embeddedPlayer;
    AVPlayerLayer* embeddedPlayerLayer;
}
@end

@implementation ViewController

NSString *ZIGGEO_APP_TOKEN = @"344a71099193b17a693ab11fdd0eeb10";
NSString *ZIGGEO_SERVER_AUTH_TOKEN = @"9569481ec23ba3be88467e17a32f7962";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    m_ziggeo = [[Ziggeo alloc] initWithToken:ZIGGEO_APP_TOKEN];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)playFullScreen:(id)sender {
    [ZiggeoPlayer createPlayerWithAdditionalParams:m_ziggeo videoToken:@"VIDEO_TOKEN" params:@{ @"client_auth" : @"CLIENT_AUTH_TOKEN" } callback:^(ZiggeoPlayer *player) {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            AVPlayerViewController* playerController = [[AVPlayerViewController alloc] init];
            playerController.player = player;
            //hide player on playback finished
            player.didFinishPlaying = ^(NSString *videoToken, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [playerController dismissViewControllerAnimated:true completion:nil];
                });
            };
            //show playback controls
            playerController.showsPlaybackControls = true;
            [self presentViewController:playerController animated:true completion:nil];
            [playerController.player play];
        });
    }];
}

- (IBAction)playEmbedded:(id)sender {
    if(embeddedPlayer) //remove previous player instance
    {
        [embeddedPlayer pause];
        [embeddedPlayerLayer removeFromSuperlayer];
        embeddedPlayerLayer = nil;
        embeddedPlayer = nil;
    }
    ZiggeoPlayer* player = [[ZiggeoPlayer alloc] initWithZiggeoApplication:m_ziggeo videoToken:@"VIDEO_TOKEN"];
    AVPlayerLayer* playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = self.videoViewPlaceholder.frame;
    [self.videoViewPlaceholder.layer addSublayer:playerLayer];
    [player play];
    embeddedPlayer = player;
    embeddedPlayerLayer = playerLayer;
}

- (IBAction)record:(id)sender {
    ZiggeoRecorder* recorder = [[ZiggeoRecorder alloc] initWithZiggeoApplication:m_ziggeo];
    recorder.coverSelectorEnabled = NO;
    recorder.cameraFlipButtonVisible = YES;
    recorder.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    recorder.useLiveStreaming = NO;
    recorder.recordingQuality = LowQuality;
    recorder.audioSampleRate = 44100;
    recorder.maxRecordedDurationSeconds = 0; //infinite
    recorder.autostartRecordingAfterSeconds = 0; //never
    recorder.controlsVisible = true; //false - no controls, autostart enabled, max duration = 30
    recorder.recorderDelegate = self;
    recorder.videoGravity = AVLayerVideoGravityResizeAspectFill;

    BOOL customizeButtons = NO;
    if (customizeButtons) {
        ZiggeoRecorderInterfaceConfig *config = [[ZiggeoRecorderInterfaceConfig alloc] init];
        config.recordButton.scale = 0.25;
        config.closeButton.scale = 0.5;
        config.cameraFlipButton.scale = 0.5;
        NSURL *flipCameraUrl = [NSBundle.mainBundle URLForResource:@"FlipCamera" withExtension:@"png"];
        if (flipCameraUrl) {
            config.cameraFlipButton.imagePath = flipCameraUrl.path;
        }
        recorder.interfaceConfig = config;
    }

    //recorder.showSoundIndicator = false;
    //recorder.showLightIndicator = false;
    //recorder.showFaceOutline = false;
    //recorder.extraArgsForCreateVideo = @{ @"effect_profile" : @"12345" };
    //recorder.extraArgsForCreateVideo = @{@"data": @"{\"foo\":\"bar\"}"}; //custom user data
// recorder level auth tokens:
//    recorder.extraArgsForCreateVideo = @{ @"client_auth" : @"CLIENT_AUTH_TOKEN" };
//    recorder.extraArgsForCreateVideo = @{ @"server_auth" : @"SERVER_AUTH_TOKEN" };
// global (application level) auth tokens:
//    m_ziggeo.connect.clientAuthToken = @"CLIENT_AUTH_TOKEN";
    m_ziggeo.connect.serverAuthToken = ZIGGEO_SERVER_AUTH_TOKEN;
    [self presentViewController:recorder animated:true completion:nil];
}

-(void) luxMeter:(double)luminousity {
    //NSLog(@"luminousity: %f", luminousity);
}

-(void) audioMeter:(double)audioLevel {
    //NSLog(@"audio: %f", audioLevel);
}

-(void) faceDetected:(int)faceID rect:(CGRect)rect {
    //NSLog(@"face %i detected with bounds: x = %f y = %f, size = %f x %f", faceID, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}


@end
