//
//  DMContact.m
//  DMSocialContactsList
//
//  Created by Thomas Ricouard on 19/12/12.
//  Copyright (c) 2012 Thomas Ricouard. All rights reserved.
//

#import "DMContact.h"

@implementation DMContact
@dynamic fullName;
@dynamic facebookImageURL;


-(id)initWithFacebookData:(NSDictionary *)facbookData
{
    self = [super init];
    if (self) {
        _facebookId = [facbookData objectForKey:@"id"];
        NSString *fbName = [facbookData objectForKey:@"name"];
        NSArray *names = [fbName componentsSeparatedByString:@" "];
        _firstName = [names objectAtIndex:0];
        _lastName = [names lastObject];
    }
    return self;
}
-(NSString *)fullName
{
    if (self.lastName != nil && self.firstName != nil){
        return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
    }
    else if (self.lastName == nil){
        return [NSString stringWithFormat:@"%@", self.firstName];
    }
    else{
        return [NSString stringWithFormat:@"%@", self.lastName];
    }
    
}

-(NSURL *)facebookImageURL
{
    if (self.facebookId){
        return [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=150&height=150", self.facebookId]];
    }
    return nil;
}

-(void)addEmail:(NSString *)email
{
    if (!self.emails) {
        _emails = [[NSMutableArray alloc]init];
    }
    if (email) {
        [_emails addObject:email];   
    }
}

-(void)addPhone:(NSString *)phone
{
    if (!self.phones) {
        _phones = [[NSMutableArray alloc]init];
    }
    if (phone) {
        [_phones addObject:phone];   
    }
}

@end
    
