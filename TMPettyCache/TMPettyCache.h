//
//  TMPettyCache.h
//  Limoncello
//
//  Created by Justin Ouellette on 11/27/12.
//  Copyright (c) 2012 Tumblr. All rights reserved.
//

@class TMPettyCache;

typedef void (^TMPettyCacheDataBlock)(TMPettyCache *, NSData *data);
typedef void (^TMPettyCacheFileURLBlock)(TMPettyCache *, NSURL *fileURL);
typedef void (^TMPettyCacheObjectBlock)(TMPettyCache *, id object);

@interface TMPettyCache : NSObject <NSCacheDelegate>

@property (copy, readonly) NSString *name;
@property (assign) NSUInteger memoryCacheByteLimit;
@property (copy) TMPettyCacheObjectBlock willEvictObjectBlock;

+ (instancetype)sharedCache;

- (instancetype)initWithName:(NSString *)name;

- (void)trimDiskCacheToSize:(NSUInteger)bytes;
- (void)clearMemoryCache;
- (void)resetCache;

- (void)dataForKey:(NSString *)key block:(TMPettyCacheDataBlock)block;
- (void)fileURLForKey:(NSString *)key block:(TMPettyCacheFileURLBlock)block;
- (void)setData:(NSData *)data forKey:(NSString *)key;
- (void)removeDataForKey:(NSString *)key;

@end
