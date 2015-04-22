//
//  IssuesChatViewController.h
//  comress
//
//  Created by Diffy Romano on 10/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSQMessagesViewController.h"
#import "JSQMessage.h"
#import "MessageData.h"
#import "Users.h"
#import "Comment.h"
#import "Post.h"
#import "NSDate+HumanizedTime.h"
#import "ImageOptions.h"
#import "ImagePreviewViewController.h"
#import "PostInfoViewController.h"
#import "ARCMacros.h"
#import "UIImageView+WebCache.h"
#import "PostStatusTableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NavigationBarTitleWithSubtitleView.h"
#import "MBProgressHUD.h"
#import "Database.h"

@class IssuesChatViewController;

@protocol IssuesChatViewControllerDelegate <NSObject>

- (void)didDismissJSQMessageComposerViewController:(IssuesChatViewController *)vc;

@end

@interface IssuesChatViewController : JSQMessagesViewController<UIActionSheetDelegate,CLLocationManagerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIPopoverPresentationControllerDelegate>
{
    Users *user;
    Comment *comment;
    Post *post;
    ImageOptions *imgOpts;
    CLLocationManager *locationManager;
    Database *myDatabase;
    
    PostStatusTableViewController *postStatusVc;
    PostInfoViewController *postInfoVc;
}

@property (nonatomic, weak) id<IssuesChatViewControllerDelegate> delegateModal;
@property (nonatomic, strong) MessageData *messageData;
@property (nonatomic) int postId;
@property (nonatomic) int ServerPostId;
@property (nonatomic, strong) NSDictionary *postDict;
@property (nonatomic, strong) NSDictionary *postInfoDict;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *actionButton;
@property (nonatomic, strong) NSArray *commentsArray;
@property (nonatomic, strong) NSNumber *theNewSelectedStatus;
@property (nonatomic) BOOL isFiltered;

- (void)selectedTableRow:(NSNotification *)notif; //when user select a status from the pop-up

@end
