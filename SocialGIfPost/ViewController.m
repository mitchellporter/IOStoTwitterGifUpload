//
//  ViewController.m
//  SocialGIfPost
//
//  Created by IGAL NASSIMA on 8/12/15.
//  Copyright (c) 2015 IGAL NASSIMA. All rights reserved.
//

#import "ViewController.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    ACAccountStore *account = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:
                                  ACAccountTypeIdentifierTwitter];
    
    [account requestAccessToAccountsWithType:accountType options:nil
                                  completion:^(BOOL granted, NSError *error) {
        if (granted == YES)
        {
            arrayOfAccounts = [account accountsWithAccountType:accountType];
                     NSString* filePath = [[NSBundle mainBundle] pathForResource:@"giphy"
                                                                 ofType:@"gif"];
            
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            [self sendTweetWithImage:data withCompletion:^(NSString *mediaId, NSError *err) {
                
                if(err) {
                    NSLog(@"ERR %@", err);
                } else {
                    
                    [self postStatusWithMediaId:mediaId :@"tweet" withCompletion:^(NSError *err){
                       
                        if(err) {
                            NSLog(@"ERR %@", err);
                        } else {
                            
                            NSLog(@"Completed");
                        }
                        
                    }];
                    
                }
            }];
        }
    
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/**
 *  Post status to Twitter with mediaid
 *
 *  @param mediaid        media uploaded to twitter
 *  @param completion     callback on return
 */
-(void)postStatusWithMediaId:(NSString *)mediaid:(NSString *)status withCompletion:(void(^)(NSError *error))completion {
    
    NSURL *requestURL = [[NSURL alloc] initWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
    
    NSMutableDictionary *message = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                    status,@"status",
                                    @"true",@"wrap_links",
                                    mediaid, @"media_ids",
                                    nil];
    
   // NSLog(@"MESSAGE %@ " , message);
    
    SLRequest *postRequest = [SLRequest
                              requestForServiceType:SLServiceTypeTwitter
                              requestMethod:SLRequestMethodPOST
                              URL:requestURL parameters:message];
    
    postRequest.account = [arrayOfAccounts objectAtIndex:0];
    
    [postRequest performRequestWithHandler:
     ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         NSString *resp = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
         
         NSLog(@"RESP %@", resp);
         
         if (error) {
             NSLog(@"%@",error.description);
         }
         else {
             NSLog(@"SUCCESS");
         }
         
     }];
}

/**
 *  Upload an image to twitter to get media_id for is
 *
 *  @param img        The image (UIImage or NSData) to be uploaded
 *  @param completion
 */
- (void)sendTweetWithImage:(NSData *)data withCompletion:(void(^)(NSString *mediaID, NSError *error))completion {
    
    NSURL *requestURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    
    //Get image data
//    NSData *data = img;
//    if ([img isKindOfClass:[UIImage class]]) {
//        data = UIImagePNGRepresentation(img);
//    }
    
    ACAccount *twitterAccount = [arrayOfAccounts objectAtIndex:0];
    NSLog(@"account %@", twitterAccount);
    
  
    
    SLRequest *postRequest = [SLRequest
                              requestForServiceType:SLServiceTypeTwitter
                              requestMethod:SLRequestMethodPOST
                              URL:requestURL parameters:nil];
    
    //Setup upload TW request
    [postRequest addMultipartData:data withName:@"media" type:@"image/gif" filename:@"synth.gif"];
    postRequest.account = twitterAccount;
    //Post the request to get the media ID
    [postRequest performRequestWithHandler:
     ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         
         NSLog(@"ERR %@", error);
         if (!error && responseData) {
             
             NSString *resp = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
             NSLog(@"restp : %@",resp);
             //DLog(@"restp : %@",resp);
             if (error) {
                 NSLog(@"error :%@",error);
             }
             NSError *jsonError = nil;
             NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
             
             if (jsonError) {
                 error = jsonError;
             }
             
             if (completion) {
                 completion(json[@"media_id_string"],error);
             }
         }
         else {
             if (completion) {
                 completion(nil,error);
             }
             
         }
     }];
}

@end
