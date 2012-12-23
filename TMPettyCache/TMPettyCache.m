//
//  TMPettyCache.m
//  Limoncello
//
//  Created by Justin Ouellette on 11/27/12.
//  Copyright (c) 2012 Tumblr. All rights reserved.
//

#import "TMPettyCache.h"

#define TMPettyCacheError(error) NSLog(@"%@ (%d) ERROR: %@", \
            [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
            __LINE__, [error localizedDescription]);

NSString * const TMPettyCacheDirectory = @"TMPettyCacheDirectory";
NSString * const TMPettyCacheSharedName = @"TMPettyCacheShared";
NSUInteger const TMPettyCacheDefaultMemoryLimit = 0xA00000; // 10 MB

@interface TMPettyCache ()
#if OS_OBJECT_USE_OBJC
@property (strong, nonatomic) dispatch_queue_t queue;
#else
@property (assign, nonatomic) dispatch_queue_t queue;
#endif
@property (strong, nonatomic) NSString *cachePath;
@property (strong, nonatomic) NSCache *cache;
@property (copy) NSString *name;
@end

@implementation TMPettyCache

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.cache.delegate = nil;

    #if !OS_OBJECT_USE_OBJC
    dispatch_release(_queue);
    #endif
}

- (instancetype)initWithName:(NSString *)name
{
    if (![name length])
        return nil;

    if (self = [super init]) {
        self.name = name;
        self.cache = [[NSCache alloc] init];
        self.cache.name = [[NSString alloc] initWithFormat:@"%@.%@.%p", NSStringFromClass([self class]), self.name, self];
        self.cache.delegate = self;

        self.queue = dispatch_queue_create([self.cache.name UTF8String], DISPATCH_QUEUE_SERIAL);
        self.memoryCacheByteLimit = TMPettyCacheDefaultMemoryLimit;
        self.willEvictObjectBlock = nil;

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *dirPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:TMPettyCacheDirectory];
        self.cachePath = [dirPath stringByAppendingPathComponent:self.name];
        
        [self createCacheDirectory];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemoryCache)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:[UIApplication sharedApplication]];
    }
    return self;
}

+ (instancetype)sharedCache
{
    static TMPettyCache *cache = nil;
    static dispatch_once_t predicate;

    dispatch_once(&predicate, ^{
        cache = [[self alloc] initWithName:TMPettyCacheSharedName];
    });

    return cache;
}

#pragma mark - <NSCacheDelegate>

- (void)cache:(NSCache *)cache willEvictObject:(id)object
{
    if (self.willEvictObjectBlock)
        self.willEvictObjectBlock(self, object);
}

#pragma mark - Private Methods

- (NSURL *)fileURLForKey:(NSString *)key
{
    if (![self.cachePath length] || ![key length])
        return nil;

    return [NSURL fileURLWithPath:[self.cachePath stringByAppendingPathComponent:key]];
}

- (void)createCacheDirectory
{
    if (![self.cachePath length] || [[NSFileManager defaultManager] fileExistsAtPath:self.cachePath isDirectory:nil])
        return;

    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:self.cachePath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error)
        TMPettyCacheError(error);
}

#pragma mark - Accessors

- (NSUInteger)memoryCacheByteLimit
{
    __block NSUInteger limit = 0;

    dispatch_sync(self.queue, ^{
        limit = self.cache.totalCostLimit;
    });

    return limit;
}

- (void)setMemoryCacheByteLimit:(NSUInteger)limit
{
    __weak __typeof(self) weakSelf = self;
    
    dispatch_async(self.queue, ^{
        weakSelf.cache.totalCostLimit = limit < 0 || limit == NSUIntegerMax ? 0 : limit;
    });
}

#pragma mark - Public Methods

- (void)dataForKey:(NSString *)key block:(TMPettyCacheDataBlock)block
{
    if (!block || ![key length])
        return;

    __weak __typeof(self) weakSelf = self;
    
    dispatch_async(self.queue, ^{
        __typeof(weakSelf) strongSelf = weakSelf;

        NSData *data = [strongSelf.cache objectForKey:key];;
        
        if (!data && [[NSFileManager defaultManager] fileExistsAtPath:[[strongSelf fileURLForKey:key] path]]) {
            NSError *error = nil;
            data = [NSData dataWithContentsOfURL:[strongSelf fileURLForKey:key] options:0 error:&error];
            if (error)
                TMPettyCacheError(error);
            
            if (data) {
                __weak __typeof(strongSelf) weakSelf = strongSelf;
                dispatch_async(strongSelf.queue, ^{
                    [weakSelf.cache setObject:data forKey:key cost:[data length]];
                });
            }
        }

        block(strongSelf, data);
    });
}

- (void)fileURLForKey:(NSString *)key block:(TMPettyCacheFileURLBlock)block
{
    if (!block || ![key length])
        return;

    __weak __typeof(self) weakSelf = self;

    dispatch_async(self.queue, ^{
        __typeof(weakSelf) strongSelf = weakSelf;

        NSURL *fileURL = [strongSelf fileURLForKey:key];

        if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
            block(strongSelf, fileURL);
        } else {
            block(strongSelf, nil);
        }
    });
}

- (void)setData:(NSData *)data forKey:(NSString *)key
{
    if (![key length])
        return;
    
    if (!data) {
        [self removeDataForKey:key];
        return;
    }

    __weak __typeof(self) weakSelf = self;
    
    dispatch_async(self.queue, ^{
        __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return;

        [strongSelf.cache setObject:data forKey:key cost:[data length]];
        
        NSError *error = nil;
        [data writeToURL:[strongSelf fileURLForKey:key] options:0 error:&error];
        if (error)
            TMPettyCacheError(error);
    });
}

- (void)removeDataForKey:(NSString *)key
{
    if (![key length])
        return;

    __weak __typeof(self) weakSelf = self;

    dispatch_async(self.queue, ^{
        __typeof(weakSelf) strongSelf = weakSelf;

        [strongSelf.cache removeObjectForKey:key];

        NSURL *fileURL = [strongSelf fileURLForKey:key];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
            if (error)
                TMPettyCacheError(error);
        }
    });
}

- (void)clearMemoryCache
{
    __weak __typeof(self) weakSelf = self;

    dispatch_async(self.queue, ^{
        [weakSelf.cache removeAllObjects];
    });
}

- (void)clearDiskCache
{
    __weak __typeof(self) weakSelf = self;
    
    dispatch_async(self.queue, ^{
        __typeof(weakSelf) strongSelf = weakSelf;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:strongSelf.cachePath]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:strongSelf.cachePath error:&error];
            if (error)
                TMPettyCacheError(error);
            
            [strongSelf createCacheDirectory];
        }
    });
}

- (void)trimDiskCacheToSize:(NSUInteger)diskCacheByteLimit
{
    __weak __typeof(self) weakSelf = self;

    if (diskCacheByteLimit <= 0) {
        [self clearDiskCache];
        return;
    }

    dispatch_async(self.queue, ^{
        __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return;
        
        NSError *error = nil;
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:strongSelf.cachePath error:&error];
        if (error)
            NSLog(@"%@", error);

        NSMutableDictionary *filePathsWithAttributes = [[NSMutableDictionary alloc] initWithCapacity:[contents count]];
        NSUInteger diskCacheSize = 0;
        
        for (NSString *fileName in contents) {
            NSString *filePath = [strongSelf.cachePath stringByAppendingPathComponent:fileName];

            NSError *error = nil;
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
            if (error)
                TMPettyCacheError(error);

            if (!attributes)
                continue;
            
            [filePathsWithAttributes setObject:attributes forKey:filePath];
            diskCacheSize += [attributes fileSize];
        }

        NSArray *filePathsSortedByDate = [filePathsWithAttributes keysSortedByValueUsingComparator:^(id file0, id file1) {
            return [[file0 fileCreationDate] compare:[file1 fileCreationDate]];
        }];

        for (NSString *filePath in filePathsSortedByDate) {
            NSDictionary *attributes = [filePathsWithAttributes objectForKey:filePath];
            if (!attributes)
                continue;

            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
                if (error)
                    TMPettyCacheError(error);

                diskCacheSize -= [attributes fileSize];
            }

            if (diskCacheSize <= diskCacheByteLimit)
                break;
        }
    });
}

@end
