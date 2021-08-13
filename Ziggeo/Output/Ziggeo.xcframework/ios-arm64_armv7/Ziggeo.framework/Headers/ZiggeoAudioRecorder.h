//
//  ZiggeoAudioRecorder.h
//  Ziggeo
//
//  Created by alex on 07/04/16.
//  Copyright © 2016 Ziggeo. All rights reserved.
//

@import AVFoundation;
#import <UIKit/UIKit.h>
#import "ZiggeoApplication.h"

@interface ZiggeoAudioRecorder : UIViewController

- (id)initWithZiggeoApplication:(Ziggeo*)ziggeo;
- (id)initWithZiggeoApplication:(Ziggeo*)ziggeo audioToken:(NSString*)audioToken;

@end
