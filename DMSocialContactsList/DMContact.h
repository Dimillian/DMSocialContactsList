//
//  DMContact.h
//  DMSocialContactsList
//
//  Created by Thomas Ricouard on 19/12/12.
//  Copyright (c) 2012 Thomas Ricouard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMContact : NSObject


@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, readonly) NSString *fullName;

//The facebook id, if it's null then it is a local contact.
@property (nonatomic, strong) NSString *facebookId;
@property (nonatomic, readonly) NSMutableArray *emails;
@property (nonatomic, readonly) NSMutableArray *phones;

//Data of the local image
@property (nonatomic, strong) NSData *localImageData;
//Generated URL to the square Facebook image
@property (nonatomic, readonly) NSURL *facebookImageURL;

//The reference to the selected value from the contact list. Store a phone number, email address or facebook ID
@property (nonatomic, strong) NSString *selectedValueRef;

@property (nonatomic, getter = isSelected, setter = isSelected:) BOOL selected;

-(id)initWithFacebookData:(NSDictionary *)facbookData;

-(void)addEmail:(NSString *)email;
-(void)addPhone:(NSString *)phone;

@end
