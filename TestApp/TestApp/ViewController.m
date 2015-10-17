//
//  ViewController.m
//  TestApp
//
//  Copyright (c) 2015 Ziggeo Inc. All rights reserved.
//

#import "ViewController.h"
#import "Ziggeo/Ziggeo.h"
@import AVKit;

@interface ViewController () {
    Ziggeo* m_ziggeo;
    ZiggeoPlayer* embeddedPlayer;
    AVPlayerLayer* embeddedPlayerLayer;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    m_ziggeo = [[Ziggeo alloc] initWithToken:@"APPLICATION_TOKEN"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (ZiggeoPlayer*) createPlayer
{
    return [[ZiggeoPlayer alloc] initWithZiggeoApplication:m_ziggeo videoToken:@"VIDEO_TOKEN"];
}

- (IBAction)playFullScreen:(id)sender {
    AVPlayerViewController* playerController = [[AVPlayerViewController alloc] init];
    playerController.player = [self createPlayer];
    [self presentViewController:playerController animated:true completion:nil];
    [playerController.player play];
}

- (IBAction)playEmbedded:(id)sender {
    if(embeddedPlayer) //remove previous player instance
    {
        [embeddedPlayer pause];
        [embeddedPlayerLayer removeFromSuperlayer];
        embeddedPlayerLayer = nil;
        embeddedPlayer = nil;
    }
    ZiggeoPlayer* player = [self createPlayer];
    AVPlayerLayer* playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = self.videoViewPlaceholder.frame;
    [self.videoViewPlaceholder.layer addSublayer:playerLayer];
    [player play];
    embeddedPlayer = player;
    embeddedPlayerLayer = playerLayer;
}

- (IBAction)record:(id)sender {
    ZiggeoRecorder* recorder = [[ZiggeoRecorder alloc] initWithZiggeoApplication:m_ziggeo];
    recorder.videoMaximumDuration = 20; //optional video duration limit
    recorder.coverSelectorEnabled = YES; //enable additional cover selector dialog
    [self presentViewController:recorder animated:true completion:nil];
}

@end
