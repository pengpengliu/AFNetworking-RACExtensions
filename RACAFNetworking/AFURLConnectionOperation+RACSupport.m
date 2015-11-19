//
//  AFURLConnectionOperation+RACSupport.m
//  Reactive AFNetworking Example
//
//  Created by Robert Widmann on 3/28/13.
//  Copyright (c) 2013 CodaFi. All rights reserved.
//

#import "AFURLConnectionOperation+RACSupport.h"
#import "AFHTTPRequestOperation.h"

@implementation AFURLConnectionOperation (RACSupport)

- (RACSignal *)rac_start {
	[self start];
	return [self rac_overrideHTTPCompletionBlock];
}

- (RACSignal *)rac_overrideHTTPCompletionBlock {
	RACReplaySubject *subject = [RACReplaySubject replaySubjectWithCapacity:1];
	[subject setNameWithFormat:@"-rac_start: %@", self.request.URL];
	
	if ([self respondsToSelector:@selector(setCompletionBlockWithSuccess:failure:)]) {
		
#ifdef RAFN_MAINTAIN_COMPLETION_BLOCKS
		void (^oldCompBlock)() = self.completionBlock;
#endif
		[(AFHTTPRequestOperation *)self setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
			[subject sendNext:RACTuplePack(responseObject, operation.response)];
			[subject sendCompleted];
#ifdef RAFN_MAINTAIN_COMPLETION_BLOCKS
			if (oldCompBlock) {
				oldCompBlock();
			}
#endif
		} failure:^(id operation, NSError *error) {
            NSError *err = [AFURLConnectionOperation errorFromRequestOperation:operation];
            
            [subject sendError:err?:error];
#ifdef RAFN_MAINTAIN_COMPLETION_BLOCKS
			if (oldCompBlock) {
				oldCompBlock();
			}
#endif
		}];
		
		return subject;
	}
	
	return subject;
}

#pragma mark - Error Handling

+ (NSError *)errorFromRequestOperation:(AFHTTPRequestOperation *)operation {
    NSParameterAssert(operation != nil);
    
    NSDictionary *responseDictionary = nil;
    
    if ([operation.responseObject isKindOfClass:[NSDictionary class]]) {
        responseDictionary = operation.responseObject;
    } else {
        return nil;
    }
    
    NSInteger code = [responseDictionary[@"code"] integerValue];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    userInfo[NSLocalizedDescriptionKey] = responseDictionary[@"error"];
    
    return [NSError errorWithDomain:@"WEClientErrorDomain" code:code userInfo:userInfo];
}

@end
