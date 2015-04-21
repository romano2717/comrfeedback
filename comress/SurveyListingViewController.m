//
//  SurveyListingViewController.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "SurveyListingViewController.h"

@interface SurveyListingViewController ()

@end

@implementation SurveyListingViewController

@synthesize surveyArray,segment;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    survey = [[Survey alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    self.tabBarController.tabBar.hidden = NO;
    self.navigationController.navigationBar.hidden = NO;
    self.hidesBottomBarWhenPushed = NO;
    
    [self fetchSurvey];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.surveyTableView reloadData];
}

- (IBAction)segmentChanged:(id)sender
{
    [self fetchSurvey];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"push_survey_detail_from_list"])
    {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        
        int clientSurveyId = 0;
        int surveyId = 0;
        
        if(segment.selectedSegmentIndex == 0)
        {
            clientSurveyId = [[[[surveyArray objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"client_survey_id"] intValue];
            surveyId = [[[[surveyArray objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"survey_id"] intValue];
        }
        else if (segment.selectedSegmentIndex == 1)
        {
            NSString *key = [[[surveyArray firstObject] allKeys] objectAtIndex:indexPath.section];
            NSDictionary *dict = [[[surveyArray firstObject] objectForKey:key] objectAtIndex:indexPath.row];
            
            clientSurveyId = [[[dict objectForKey:@"survey"] valueForKey:@"client_survey_id"] intValue];
            surveyId = [[[dict objectForKey:@"survey"] valueForKey:@"survey_id"] intValue];
        }
        else
        {
            clientSurveyId = [[[[surveyArray objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"client_survey_id"] intValue];
            surveyId = [[[[surveyArray objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"survey_id"] intValue];
        }
        
        
        SurveyDetailViewController *sdvc = [segue destinationViewController];
        sdvc.surveyId = [NSNumber numberWithInt:surveyId];
        sdvc.clientSurveyId = [NSNumber numberWithInt:clientSurveyId];
    }
}


- (void)fetchSurvey
{
    surveyArray = [survey fetchSurveyForSegment:(int)segment.selectedSegmentIndex];
    DDLogVerbose(@"surveyArray %@",surveyArray);
    
    if(segment.selectedSegmentIndex == 2)//set overdue badge if there's any
    {
        if(surveyArray.count > 0)
            [segment setBadgeNumber:surveyArray.count forSegmentAtIndex:2];
    }
    
    [self.surveyTableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(segment.selectedSegmentIndex == 0)
        return  nil;
    else if (segment.selectedSegmentIndex == 1)
        return [[[surveyArray firstObject] allKeys] objectAtIndex:section];

    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(segment.selectedSegmentIndex == 0)
        return surveyArray.count;
    else if (segment.selectedSegmentIndex == 1)
    {
        NSString *key = [[[surveyArray firstObject] allKeys] objectAtIndex:section];
        NSArray *arr = [[surveyArray firstObject] objectForKey:key];
        return arr.count;
    }
    else
        return surveyArray.count;
    
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(segment.selectedSegmentIndex == 0)
        return 1;
    else if (segment.selectedSegmentIndex == 1)
        return [[[surveyArray firstObject] allKeys] count];
    else
        return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    
    SurveyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSDictionary *dict;
    
    if(segment.selectedSegmentIndex == 0)
        dict = [surveyArray objectAtIndex:indexPath.row];
    else if(segment.selectedSegmentIndex == 1)
    {
        NSString *key = [[[surveyArray firstObject] allKeys] objectAtIndex:indexPath.section];
        dict = [[[surveyArray firstObject] objectForKey:key] objectAtIndex:indexPath.row];
        
    }
    else
        dict = [surveyArray objectAtIndex:indexPath.row];
    
        
    [cell initCellWithResultSet:dict];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"push_survey_detail_from_list" sender:indexPath];
}


@end
