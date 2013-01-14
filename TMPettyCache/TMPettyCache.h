//
//  TMPettyCache.h
//  Limoncello
//
//  Created by Justin Ouellette on 11/27/12.
//  Copyright (c) 2012 Tumblr. All rights reserved.
//

@class TMPettyCache;

typedef void (^TMPettyCacheBlock)(TMPettyCache *cache, NSString *key, NSData *data, NSURL *fileURL);

@interface TMPettyCache : NSObject <NSCacheDelegate>

@property (copy, readonly) NSString *name;
@property (assign) NSUInteger memoryCacheByteLimit;
@property (assign) NSUInteger memoryCacheCountLimit;
@property (copy) TMPettyCacheBlock willEvictDataBlock;

+ (instancetype)sharedCache;

- (instancetype)initWithName:(NSString *)name;

- (void)trimDiskCacheToSize:(NSUInteger)bytes;
- (void)clearMemoryCache;
- (void)clearDiskCache;
- (void)clearAllCachesSynchronously;

- (void)dataForKey:(NSString *)key block:(TMPettyCacheBlock)block;
- (void)fileURLForKey:(NSString *)key block:(TMPettyCacheBlock)block;
- (void)setData:(NSData *)data forKey:(NSString *)key;
- (void)removeDataForKey:(NSString *)key;

@end
