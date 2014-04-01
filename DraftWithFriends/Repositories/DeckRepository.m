//
//  DeckRepository.m
//  DraftWithFriends
//
//  Created by Trent Ellingsen on 3/18/14.
//  Copyright (c) 2014 Ryan Schroeder. All rights reserved.
//

#import <Parse/Parse.h>
#import "DeckRepository.h"
#import "CompleteDeck+Mapper.h"

@implementation DeckRepository

- (void)decksWithUserId:(NSString *)userId completed:(RepositoryCompletionBlock)completed
{
    if (!userId) {
        if (completed) {
            completed(nil, @[]);
            return;
        }
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"CompleteDeck"];
    [query whereKey:@"userId" equalTo:userId];
    [query orderByDescending:@"createdAt"];
    [query setCachePolicy:kPFCachePolicyNetworkElseCache];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (completed) completed(nil, [CompleteDeck mapPFCompleteDeckArray:objects]);
        } else {
            if (completed) completed(error, nil);
        }
    }];
}

- (void)saveDeck:(CompleteDeck *)deck
{
    PFObject *pfDeck = [CompleteDeck mapCompleteDeck:deck];
    
    [pfDeck saveInBackground];
}

- (void)deleteDeck:(CompleteDeck *)deck
{
    PFQuery *query = [PFQuery queryWithClassName:@"CompleteDeck"];
    [query whereKey:@"objectId" equalTo:deck.pfCompletedDeck.objectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            [object deleteInBackground];
        }
    }];
}

+ (DeckRepository *)sharedRepository
{
	static dispatch_once_t pred = 0;
	__strong static id _sharedRepository = nil;
	
	dispatch_once(&pred, ^{
		_sharedRepository = [[self alloc] init];
	});
	
	return _sharedRepository;
}

@end