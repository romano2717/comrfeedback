//
//  SurveyTableViewCell.h
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Questions.h"

@interface SurveyTableViewCell : UITableViewCell
{
    Questions *questions;
}

@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UILabel *satisfactionRatingLabel;
@property (nonatomic, weak) IBOutlet UILabel *residentName;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@property (nonatomic) int numOfQuestions;

- (void)initCellWithResultSet:(NSDictionary *)dict;

@end
