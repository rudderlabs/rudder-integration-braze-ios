//
//  RUDDERViewController.m
//  Rudder-Braze
//
//  Created by arnab on 10/29/2019.
//  Copyright (c) 2019 arnab. All rights reserved.
//

#import "RUDDERViewController.h"
#import <Rudder/Rudder.h>

@interface RUDDERViewController ()

@end

@implementation RUDDERViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onButtonTap:(UIButton *)sender {
    switch (sender.tag) {
        case 10: {
            RSOption *option = [[RSOption alloc] init];
            [option putExternalId:@"brazeExternalId" withId:@"2d31d085-4d93-4126-b2b3-94e651810673"];
            
            NSDate *birthday = [[NSDate alloc] init];
            
            [[RSClient sharedInstance] identify: @"userid ios 1" traits: @{
                @"birthday": birthday,
                @"address": @{
                    @"city": @"Kolkata",
                    @"country": @"India"
                },
                @"firstname": @"First Name",
                @"lastname": @"Last Name",
                @"gender": @"Male",
                @"phone": @"0123456789",
                @"email": @"test@gmail.com",
                @"key-1": @"value-1",
                @"key-2": @1234
            } options:option];
        }
            break;
        case 0:
            [[RSClient sharedInstance] track:@"Install Attributed"];
            break;
        case 1:
            [[RSClient sharedInstance] track:@"Install Attributed" properties:@{
                @"campaign": @{
                    @"source": @"Source value",
                    @"name": @"Name value",
                    @"ad_group": @"ad_group value",
                    @"ad_creative": @"ad_creative value"
                }
            }];
            break;
        case 2:
            [[RSClient sharedInstance] track:@"Order Completed"];
            break;
        case 3:
            [[RSClient sharedInstance] track:@"Order Completed" properties:@{
                @"products": @[@{}]
            }];
            break;
        case 4:
            [[RSClient sharedInstance] track:@"Order Completed" properties:@{
                @"products": @[@{
                    @"product_id": @"10011",
                    @"quantity": @11,
                    @"price": @100.11,
                    @"Product-Key-1": @"Product-Value-1"
                }],
                @"revenue": @123,
                @"currency": @"INR",
                @"Key-1": @"Value-1"
            }];
            break;
        case 5:
            [[RSClient sharedInstance] track:@"Order Completed" properties:@{
                @"products": @[@{
                    @"product_id": @"1002",
                    @"quantity": @12,
                    @"price": @100.22
                }],
                @"currency": @"INR"
            }];
            break;
        case 6:
            [[RSClient sharedInstance] track:@"Ecomm track events" properties:@{
                @"products": @[@{
                    @"product_id": @"1002",
                    @"quantity": @12,
                    @"price": @100.22
                }],
                @"currency": @"INR"
            }];
            break;
        case 7:
            [[RSClient sharedInstance] track:@"Order Completed" properties:@{
                @"products": @[@{
                    @"product_id": @"1002",
                    @"quantity": @12,
                    @"price": @100.22
                }, @{
                    @"product_id": @"1003",
                    @"quantity": @5,
                    @"price": @89.50
                }],
                @"currency": @"INR"
            }];
            break;
        case 8:
            [[RSClient sharedInstance] track:@"New Track event" properties:@{
                @"key_1" : @"value_1",
                @"key_2" : @"value_2"
            }];
            break;
        case 9:
            [[RSClient sharedInstance] track:@"New Track event"];
            break;
        default:
            break;
    }
}

@end
