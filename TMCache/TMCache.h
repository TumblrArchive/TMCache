/**
 `TMCache` is an asynchronous wrapper for `NSCache` with simultaneous persistence to disk.
 */

@class TMCache;

typedef void (^TMCacheBlock)(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL);

@interface TMCache : NSObject <NSCacheDelegate>

/// @name Core

@property (copy, readonly) NSString *name;
@property (strong, readonly) dispatch_queue_t queue;

/// @name Memory Cache

@property (assign) NSUInteger memoryCacheByteLimit;
@property (assign) NSUInteger memoryCacheCountLimit;
@property (copy) TMCacheBlock willEvictDataFromMemoryBlock;

/// @name Disk Cache

@property (assign) NSUInteger diskCacheByteLimit;
@property (assign) NSTimeInterval diskCacheMaxAge;
@property (copy) TMCacheBlock willEvictDataFromDiskBlock;

/// @name Current Usage

@property (assign, readonly) NSUInteger currentMemoryBytes;
@property (assign, readonly) NSUInteger currentMemoryCount;
@property (assign, readonly) NSUInteger currentDiskBytes;
@property (assign, readonly) NSUInteger currentDiskCount;

/// @name Genesis

+ (instancetype)sharedCache;
+ (instancetype)withName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name;

/// @name Revelation

- (void)clearMemoryCache;
- (void)clearDiskCache;
- (void)clearAllCachesSynchronously;

/// @name Trim

- (void)trimDiskCacheToSize:(NSUInteger)bytes;
- (void)trimDiskCacheToDate:(NSDate *)date;

/// @name Write

- (void)setData:(NSData *)data forKey:(NSString *)key block:(TMCacheBlock)completionBlock;
- (void)removeDataForKey:(NSString *)key block:(TMCacheBlock)completionBlock;

/// @name Read

- (void)dataForKey:(NSString *)key block:(TMCacheBlock)block;
- (void)fileURLForKey:(NSString *)key block:(TMCacheBlock)block;

@end
