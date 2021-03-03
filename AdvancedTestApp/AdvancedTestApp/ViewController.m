//
//  ViewController.m
//  test
//
//  Copyright (c) 2015 Ziggeo Inc. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
@import AVFoundation;
@import AVKit;
@import MediaPlayer;
#import "Ziggeo/Ziggeo.h"
#import "TableViewVideoCell.h"
#import "TableViewUploadingVideoCell.h"

@interface ViewController ()
@property (atomic) NSMutableArray* videoJsonArray;
@property (atomic) NSMutableArray* uploadingVideos;
@end

@implementation ViewController {
    NSString *applicationGroup;
    AVPlayerViewController *_playerController;
    UIViewController *_adController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    applicationGroup = @"group.Ziggeo.AdvancedTestApp348597897.Group";
    self.title = @"Ziggeo Videos";
    NSString* ziggeoToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"token"];
    self.ziggeo = [[Ziggeo alloc] initWithToken:ziggeoToken];
    [self.ziggeo videos].delegate = self;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.refreshControl.tintColor = [UIColor darkGrayColor];
    [self.refreshControl addTarget:self
                            action:@selector(refreshVideoJsonArray)
                  forControlEvents:UIControlEventValueChanged];
    
    self.uploadingVideos = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *btnCapture = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(startCapture:)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = btnCapture;

    _playerController = [[AVPlayerViewController alloc] init];
    _adController = [[UIViewController alloc] init];

    [self refreshVideoJsonArray];
}

- (void)videoPreparingToUploadWithPath:(NSString *)sourcePath {
    // stub method. it's required by delegate
}

- (void)videoPreparingToUploadWithPath:(NSString *)sourcePath token:(NSString *)token {
    // stub method. it's required by delegate
}

-(void) videoUploadStartedWithPath:(NSString*)sourcePath token:(NSString*)token backgroundTask:(NSURLSessionTask*)uploadingTask {
    [self.uploadingVideos addObject:sourcePath];
    [self refreshVideoJsonArray];
}

-(void) videoUploadCompleteForPath:(NSString*)sourcePath token:(NSString*)token withResponse:(NSURLResponse*)response error:(NSError*)error json:(NSDictionary*)json {
    NSLog(@"upload complete: %@, error = %@", json, error);
    [self.uploadingVideos removeObject:sourcePath];
    [self refreshVideoJsonArray];
}

-(void) videoUploadProgressForPath:(NSString*)sourcePath token:(NSString*)token totalBytesSent:(int)bytesSent totalBytesExpectedToSend:(int)totalBytes {
    if(totalBytes > 0) {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            NSInteger rowNumber = [self.uploadingVideos indexOfObject:sourcePath];
            TableViewUploadingVideoCell* uploadingCell = (TableViewUploadingVideoCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:rowNumber inSection:1]];
            uploadingCell.progressView.progress = (float)bytesSent / (float)totalBytes;
            [uploadingCell setNeedsDisplay];
        });
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) refreshVideoJsonArray {
    ZiggeoVideos* videos = [self.ziggeo videos];
    [videos indexWithData:nil Callback:^(NSArray *jsonArray, NSError *error) {
        NSLog(@"videos: %@\nerror: %@", jsonArray.description, error.description);
        self.videoJsonArray = [jsonArray mutableCopy];
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
        });
    }];
}

- (IBAction)startCapture:(id)sender {
    ZiggeoRecorder* recorder = [[ZiggeoRecorder alloc] initWithZiggeoApplication:self.ziggeo];
    recorder.coverSelectorEnabled = YES;
    
    UIAlertController* selectVideoSourceAlert = [UIAlertController alertControllerWithTitle:@"Video upload"
                                                                   message:@"Please select video source"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* createNewVideoAction = [UIAlertAction actionWithTitle:@"Create new video" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self presentViewController:recorder animated:YES completion:nil];
    }];
    [selectVideoSourceAlert addAction:createNewVideoAction];
    
    UIAlertAction* selectExistingVideoAction = [UIAlertAction actionWithTitle:@"Select existing video" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [recorder selectExistingVideo];
        [self presentViewController:recorder animated:YES completion:nil];
    }];
    [selectVideoSourceAlert addAction:selectExistingVideoAction];

    UIAlertAction* recordScreenVideoAction = [UIAlertAction actionWithTitle:@"Record screen video" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        CGRect rect = CGRectMake(20, 100, 50, 50);
        ViewController *vc = [[ViewController alloc]init];
        vc.modalPresentationStyle = UIModalPresentationPopover;
        [self presentModalViewController:vc animated:YES];
        [self.ziggeo.videos startScreenRecordingAndAddRecordingButtonToView:vc.view frame:rect appGroup:self->applicationGroup];
    }];
    [selectVideoSourceAlert addAction:recordScreenVideoAction];

    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
    }];
    [selectVideoSourceAlert addAction:cancelAction];
    
    [self presentViewController:selectVideoSourceAlert animated:YES completion:nil];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0 && self.videoJsonArray != nil)
    {
        return self.videoJsonArray.count;
    } else if (section == 1 && self.uploadingVideos != nil)
    {
        return self.uploadingVideos.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0) {
        TableViewVideoCell* cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewVideoCell" forIndexPath:indexPath];
        if(!cell) cell = [[TableViewVideoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TableViewVideoCell"];
        if(self.videoJsonArray && self.videoJsonArray.count > indexPath.row)
        {
            NSDictionary* item = self.videoJsonArray[indexPath.row];
            cell.token = [item objectForKey:@"token"];;
            cell.thumbView.image = nil;
            [[self.ziggeo videos] getImageForVideoByToken:cell.token data:nil callback:^(UIImage *image, NSURLResponse *response, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                   cell.thumbView.image = image;
                   [cell setNeedsDisplay];
                });
            }];
        }
        return cell;
    } else if (indexPath.section == 1 && self.uploadingVideos && self.uploadingVideos.count > indexPath.row) {
        TableViewUploadingVideoCell* cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewUploadingVideoCell" forIndexPath:indexPath];
        if(!cell) cell = [[TableViewUploadingVideoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TableViewUploadingVideoCell"];
        cell.thumbView.image = nil;
        cell.progressView.progress = 0;
        cell.sourceVideoPath = [self.uploadingVideos objectAtIndex:indexPath.row];
        [[self.ziggeo videos] getImageForVideoByPath:[self.uploadingVideos objectAtIndex:indexPath.row] callback:^(UIImage *image, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                cell.thumbView.image = image;
                [cell setNeedsDisplay];
            });
        }];
        return cell;
    }
    else return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        TableViewVideoCell* cell = (TableViewVideoCell*)[tableView cellForRowAtIndexPath:indexPath];
        if(cell)
        {
            NSString* videoToken = cell.token;
            [tableView beginUpdates];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            if(self.videoJsonArray.count > indexPath.row)
            {
                [self.videoJsonArray removeObjectAtIndex:indexPath.row];
            }
            if(self.videoJsonArray.count==0 && self.uploadingVideos.count == 0) [tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationFade];
            [tableView endUpdates];
            [[self.ziggeo videos] deleteVideoByToken:videoToken data:nil callback:^(NSData *responseData, NSURLResponse *response, NSError *error) {
                [self refreshVideoJsonArray];
            }];
        }
    }
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
    AVPlayer* player = nil;
    if(indexPath.section==0) {
        TableViewVideoCell* cell = (TableViewVideoCell*)[tableView cellForRowAtIndexPath:indexPath];
        NSLog(@"video with token %@ going to play", cell.token);
        NSDictionary *params = @{@"server_auth": @"f2aa843895b7c276df956dd93838b17f"};
        [ZiggeoPlayer createPlayerWithAdditionalParams:self.ziggeo videoToken:cell.token params:params callback:^(ZiggeoPlayer *player) {
            [self playWithPlayer:player];
        }];
    } else if(indexPath.section == 1) {
        TableViewUploadingVideoCell* cell = (TableViewUploadingVideoCell*)[tableView cellForRowAtIndexPath:indexPath];
        player = [[AVPlayer alloc] initWithURL: [NSURL fileURLWithPath:cell.sourceVideoPath]];
    }

    if (player) {
        [self playWithPlayer:player];
    }
}

- (void)playWithPlayer:(AVPlayer *)player {
    dispatch_async(dispatch_get_main_queue(), ^{

        BOOL showAds = true; // todo add switch button which will toggle it on the left from app title
        NSString *adUrl = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dskippablelinear&correlator=";

        _playerController.player = player;

        if (showAds && [player isKindOfClass:[ZiggeoPlayer class]]) {
            [self presentViewController:_adController animated:YES completion:nil]; // note that we don't show _playerController itself.
            [(ZiggeoPlayer *) player playWithAdsWithAdTagURL:adUrl playerContainer:_adController.view playerViewController:_playerController];
        } else {
            [self presentViewController:_playerController animated:YES completion:nil];
            [player play];
        }
        
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if((self.videoJsonArray && self.videoJsonArray.count > 0) || (self.uploadingVideos && self.uploadingVideos.count > 0))
    {
        self.tableView.backgroundView = nil;
        return 2;
    }
    else {
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        
        messageLabel.text = @"No video available\nPull down to refresh";
        messageLabel.textColor = [UIColor lightGrayColor];
        messageLabel.numberOfLines = 2;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        [messageLabel sizeToFit];
        
        self.tableView.backgroundView = messageLabel;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"Uploaded Videos";
    }
    if (section == 1)
    {
        if(self.uploadingVideos && self.uploadingVideos.count > 0)
        {
            return @"Uploading Videos";
        } else {
            return @"";
        }
    }
    return @"";
}

@end
