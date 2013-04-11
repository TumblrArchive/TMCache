/**
 `TMCache` is an asynchronous wrapper for `NSCache` with simultaneous persistence to disk.
 */

@class TMCache;

typedef void (^TMCacheBlock)(TMCache *cache);
typedef void (^TMCacheDataBlock)(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL);

@interface TMCache : NSObject <NSCacheDelegate>

/// @name Vitals

@property (copy, readonly) NSString *name;
@property (assign, readonly) dispatch_queue_t queue;

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

+ (instancetype)withName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name;

+ (instancetype)sharedCache;
+ (dispatch_queue_t)sharedQueue;

/// @name Clear Caches (Asynchronously)

- (void)clearMemoryCache:(TMCacheBlock)completionBlock;
- (void)clearDiskCache:(TMCacheBlock)completionBlock;
- (void)clearAllCaches:(TMCacheBlock)completionBlock;

/// @name Clear Caches (Synchronously)

- (void)clearMemoryCache;
- (void)clearDiskCache;
- (void)clearAllCaches;

/// @name Trim Disk Cache (Asynchronously)

- (void)trimDiskCacheToSize:(NSUInteger)bytes block:(TMCacheBlock)completionBlock;
- (void)trimDiskCacheToDate:(NSDate *)date block:(TMCacheBlock)completionBlock;

/// @name Trim Disk Cache (Synchronously)

- (void)trimDiskCacheToSize:(NSUInteger)bytes;
- (void)trimDiskCacheToDate:(NSDate *)date;

/// @name Read & Write (Asynchronously)

- (void)dataForKey:(NSString *)key block:(TMCacheDataBlock)completionBlock;
- (void)fileURLForKey:(NSString *)key block:(TMCacheDataBlock)completionBlock;
- (void)removeDataForKey:(NSString *)key block:(TMCacheDataBlock)completionBlock;
- (void)setData:(NSData *)data forKey:(NSString *)key block:(TMCacheDataBlock)completionBlock;

/// @name Read & Write (Synchronously)

- (NSData *)dataForKey:(NSString *)key;
- (NSURL *)fileURLForKey:(NSString *)key;
- (void)removeDataForKey:(NSString *)key;
- (void)setData:(NSData *)data forKey:(NSString *)key;

@end
