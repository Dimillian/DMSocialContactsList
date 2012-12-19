//
//  DMViewController.m
//  DMSocialContactsList
//
//  Created by Thomas Ricouard on 19/12/12.
//  Copyright (c) 2012 Thomas Ricouard. All rights reserved.
//

#import "DMContactlistViewController.h"
#import "DMContact.h"
#import <AddressBook/AddressBook.h>
#import <AddressBook/ABAddressBook.h>
#import <AddressBook/ABPerson.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <FacebookSDK/FacebookSDK.h>

@interface DMContactlistViewController ()
{
    NSMutableArray *_localContacts;
    NSMutableArray *_fbContacts;
    NSMutableArray *_datasource;
    NSMutableArray *_selectedContacts;
    NSMutableArray *_searchedUsers;
    DMContact *_tmpSelectedContact;
    
    BOOL _inSearch; 
}
@end

@implementation DMContactlistViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Select contacts";
    _selectedContacts = [[NSMutableArray alloc]init];
    [self loadAdressBookContact];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - contact fetching

-(void)loadAdressBookContact
{
    CFErrorRef error;
    ABAddressBookRef m_addressbook = ABAddressBookCreateWithOptions(NULL, &error);
    if (m_addressbook) {
        __block BOOL accessGranted = NO;
        if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS6
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            ABAddressBookRequestAccessWithCompletion(m_addressbook, ^(bool granted, CFErrorRef error) {
                accessGranted = granted;
                dispatch_semaphore_signal(sema);
            });
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }
        else { // we're on iOS5 or older
            accessGranted = YES;
        }
        if (accessGranted) {
            CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeopleInSource(m_addressbook, kABSourceTypeLocal);
            NSArray *array = (NSArray *)CFBridgingRelease(allPeople);
            _localContacts = [[NSMutableArray alloc]init];
            for (int i=0;i < array.count; i++) {
                DMContact *contact = [[DMContact alloc]init];
                
                ABRecordRef ref = CFArrayGetValueAtIndex(allPeople,i);
                CFStringRef firstName, lastName;
                firstName = ABRecordCopyValue(ref, kABPersonFirstNameProperty);
                lastName  = ABRecordCopyValue(ref, kABPersonLastNameProperty);
                
                contact.firstName = (__bridge NSString *)(firstName);
                contact.lastName = (__bridge NSString *)(lastName);
                
                if (firstName) {
                    CFRelease(firstName);
                }
                if (lastName) {
                    CFRelease(lastName);
                }
                ABMutableMultiValueRef emails  = ABRecordCopyValue(ref, kABPersonEmailProperty);
                ABMutableMultiValueRef phones  = ABRecordCopyValue(ref, kABPersonPhoneProperty);
                
                //If there is at least 1 email or 1 phone then our contact is able to receive invitation
                if(ABMultiValueGetCount(emails) > 0 || ABMultiValueGetCount(phones) > 0) {
                    
                    if (ABMultiValueGetCount(emails) > 0) {
                        for (CFIndex i = 0; i < ABMultiValueGetCount(emails); i++) {
                            NSString *email =  (NSString *)CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, i));
                            [contact addEmail:email];
                        }
                    }
                    if (ABMultiValueGetCount(phones) > 0) {
                        for (CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
                            NSString *phone = (NSString*)CFBridgingRelease(ABMultiValueCopyValueAtIndex(phones, i));
                            [contact addPhone:phone];
                        }
                    }
                    
                    //Ensure that you only display proper contacts. No old sim contacts or default contacts (like Apple store)
                    if (![[contact fullName]hasPrefix:@"_"] && (lastName || firstName)) {
                        NSData *contactImageData = (NSData*)CFBridgingRelease(ABPersonCopyImageDataWithFormat(ref,
                                                                                                              
                                                                                                              kABPersonImageFormatThumbnail));
                        if (contactImageData) {
                            contact.localImageData = contactImageData;
                        }
                        [_localContacts addObject:contact];
                    }
                    if (emails) {
                        CFRelease(emails);
                    }
                    if (phones) {
                        CFRelease(phones);
                    }
                    
                }
                
            }
        }

    }
    [self loadFBFriends];
    
}

-(void)loadFBFriends
{
    [FBSession openActiveSessionWithReadPermissions:[NSArray arrayWithObjects:@"email", nil] allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        [self sessionStateChanged:session state:status error:error];
    }];
}

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    NSLog(@"%@", error);
    switch (state) {
        case FBSessionStateOpen: {
            [self getFBFriends];
        }
            break;
        case FBSessionStateClosed:
            [self orderAndGroupContact];
            break;
        case FBSessionStateClosedLoginFailed:
            
            [FBSession.activeSession closeAndClearTokenInformation];
            [self orderAndGroupContact];
            break;
        default:
            [self orderAndGroupContact];
            break;
    }
    
}

-(void)getFBFriends
{
    _fbContacts = [[NSMutableArray alloc]init];
    FBRequest *request = [[FBRequest alloc]initWithSession:[FBSession activeSession] graphPath:@"me/friends?fields=username,name"];
    [request startWithCompletionHandler:^(FBRequestConnection *request, id result, NSError *error){
        NSDictionary *users = (NSDictionary *)result;
        for (NSDictionary *user in [users objectForKey:@"data"]) {
            DMContact *contact = [[DMContact alloc]initWithFacebookData:user];
            [_fbContacts addObject:contact];
        }
        [self orderAndGroupContact];
    }];
}

#pragma mark - Contact ordering

-(void)orderAndGroupContact
{
    
    _datasource = [[NSMutableArray alloc]init];
    
    //Merge Facebook id contact with local contact
    for (DMContact *localUser in _localContacts) {
        for (DMContact *FBUser in _fbContacts) {
            if ([localUser.fullName compare:FBUser.fullName options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch] == NSOrderedSame) {
                localUser.facebookId = FBUser.facebookId;

            }
        }
    }
    
    //Add local contacts with or without facebook id to the final datasource
    for (DMContact *contact in _localContacts) {
        [_datasource addObject:contact];
    }
    
    
    //Add Facebook contact that are not already in the datasource in it
    for (DMContact *fbContact in _fbContacts) {
        BOOL toAdd = YES;
        for (DMContact *dataSourceContact in _datasource) {
            if ([dataSourceContact.fullName compare:fbContact.fullName options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch] == NSOrderedSame) {
                toAdd = NO; 
            }
        }
        if (toAdd) {
            [_datasource addObject:fbContact];
        }
    }

    //Order the datasource
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES comparator:^(id obj1, id obj2) {
        DMContact *contact1 = (DMContact *)obj1;
        DMContact *contact2 = (DMContact *)obj2;
        return [contact1.fullName compare:contact2.fullName options:NSCaseInsensitiveSearch];
    }];
    NSArray *sortedArray = [_datasource sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
    _datasource = [sortedArray mutableCopy];
    
    //Finally reload the tableview
    [self.tableView reloadData];
    
}



#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_inSearch) {
        return _searchedUsers.count;
    }
    else{
        return _datasource.count;   
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    DMContact *contact;
    if (_inSearch) {
        contact = [_searchedUsers objectAtIndex:indexPath.row];
    }
    else{
        contact = [_datasource objectAtIndex:indexPath.row];
    }
                   
    if (contact.isSelected) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    else{
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@", contact.fullName];
    if (contact.facebookId) {
        [cell.imageView setImageWithURL:contact.facebookImageURL];
    }
    else{
        [cell.imageView setImage:[UIImage imageWithData:contact.localImageData]];   
    }

    return cell;
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DMContact *contact;
    if (_inSearch) {
        contact = [_searchedUsers objectAtIndex:indexPath.row];
        [self displaySheetForContact:contact];
    }
    else{
        contact = [_datasource objectAtIndex:indexPath.row];
        [self displaySheetForContact:contact];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIScrollView delegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}

#pragma mark - UIActionSheet Stuff
-(void)displaySheetForContact:(DMContact *)contact
{
    if (contact.isSelected) {
        contact.selected = NO;
        [self.tableView reloadData];
    }
    else{
        _tmpSelectedContact = contact;
        UIActionSheet *sheet = [[UIActionSheet alloc]initWithTitle:@"Send to" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        if (contact.facebookId) {
            [sheet addButtonWithTitle:@"Facebook wall"];
        }
        if (contact.phones) {
            for (NSString *phone in contact.phones) {
                [sheet addButtonWithTitle:phone];
            }
        }
        if (contact.emails) {
            for (NSString *email in contact.emails) {
                [sheet addButtonWithTitle:email];
            }
        }
        [sheet addButtonWithTitle:@"Cancel"];
        [sheet setCancelButtonIndex:sheet.numberOfButtons - 1];
        [sheet showInView:self.view];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        _tmpSelectedContact.selected = YES;
        _tmpSelectedContact.selectedValueRef = [actionSheet buttonTitleAtIndex:buttonIndex];
        [_selectedContacts addObject:_tmpSelectedContact];
        
    }
    [self.tableView reloadData];
}

#pragma mark - SearchBar stuff
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];
    [self activateCancelButton];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];
    _inSearch = NO;
    [self.searchBar setText:@""];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self activateCancelButton];
    [self.tableView reloadData];
    
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.searchBar setShowsCancelButton:YES animated:YES];
    dispatch_queue_t queue = dispatch_queue_create("contactListSearch",NULL);
    dispatch_queue_t main = dispatch_get_main_queue();
    dispatch_async(queue,^{
        [self searchContactWithString:searchText];
        dispatch_async(main,^{
            [self.tableView reloadData];
        });
    });
    
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self.searchBar setShowsCancelButton:YES animated:YES];
}
-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self activateCancelButton];
}

-(void)searchContactWithString:(NSString *)string
{
    
    if (string.length > 0) {
        _inSearch = YES;
        _searchedUsers = [[NSMutableArray alloc]init];
        for (DMContact *contact in _datasource) {
            NSString *name = contact.fullName;
            if ([name rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [_searchedUsers addObject:contact];
            }
        }
    }
    else{
        _inSearch = NO;
    }
     
}

-(void)activateCancelButton
{
    for(id subview in [self.searchBar subviews])
    {
        if ([subview isKindOfClass:[UIButton class]]) {
            [subview setEnabled:YES];
        }
    }
}





@end
