/**
 `TMCache` is an asynchronous wrapper for `NSCache` with simultaneous persistence to disk.
 */

@class TMCache;

typedef void (^TMCacheBlock)(TMCache *cache);
typedef void (^TMCacheDataBlock)(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL);

@interface TMCache : NSObject <NSCacheDelegate>

/// @name Core

@property (copy, readonly) NSString *name;
@property (strong, readonly) dispatch_queue_t queue;

/// @name Memory Cache

@property (assign) NSUInteger memoryCacheByteLimit;
@property (assign) NSUInteger memoryCacheCountLimit;
@property (copy) TMCacheDataBlock willEvictDataFromMemoryBlock;

/// @name Disk Cache

@property (assign) NSUInteger diskCacheByteLimit;
@property (assign) NSTimeInterval diskCacheMaxAge;
@property (copy) TMCacheDataBlock willEvictDataFromDiskBlock;

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
- (void)clearAllCaches:(TMCacheBlock)completionBlock;

/// @name Trim Disk

- (void)trimDiskCacheToSize:(NSUInteger)bytes block:(TMCacheBlock)completionBlock;
- (void)trimDiskCacheToDate:(NSDate *)date block:(TMCacheBlock)completionBlock;

/// @name Read & Write (Asynchronously)

- (void)dataForKey:(NSString *)key block:(TMCacheDataBlock)block;
- (void)fileURLForKey:(NSString *)key block:(TMCacheDataBlock)block;
- (void)removeDataForKey:(NSString *)key block:(TMCacheDataBlock)completionBlock;
- (void)setData:(NSData *)data forKey:(NSString *)key block:(TMCacheDataBlock)completionBlock;

@end
