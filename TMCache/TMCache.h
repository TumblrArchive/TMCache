/**
 `TMCache` comprises two caches, one in memory and one on disk. It accepts `NSData` objects,
 writes them to disk, and manages their lifetime in the background based on certain conditions.
 
 The memory cache is a thin wrapper around `NSCache`, which incorporates various auto-removal
 policies based on memory usage. The disk cache mirrors the memory cache but persists data so
 that it can be recovered when memory conditions improve (or the app restarts).
 
 Data is saved to the `NSCachesDirectory` of the app, meaning that it should not be used for
 reliable longterm storage. The system may remove the contents of this directory at any time.
 
 ## Concurrency ##
 
 Every method comes in two flavors: synchronous and asynchronous. The asynchronous methods
 accept an optional completion block and return immediately, the synchronous methods block
 the calling thread until they finish. In both cases the work takes place on a serial <queue>.
 
 The asynchronous methods are safe to call from any thread at any time, including their own
 completion blocks. The synchronous methods are safe to call from any thread *except* within
 the completion blocks of the asynchronous methods or the `willEvictData` blocks.
 
 Only one queue is created per cache <name>, and multiple instances of `TMCache` with the
 same name will share the same serial queue to prevent disk access conflicts. In addition,
 the target of this <queue> can be set to any other queue, allowing `TMCache` to integrate
 e.g. with an existing application I/O queue.
    
    dispatch_set_target_queue([[TMCache sharedCache] queue], [YourApp ioQueue]);
 
 ## Limits ##
 
 By default, `TMCache` sets its memory limit at 10 MB. As noted in the `NSCache` header, this
 limit is "imprecise/not strict", so actual memory usage may occasionally exceed this number.
 Setting the <memoryCacheByteLimit> property to 0 effectively removes the limit.
 
 The <diskCacheByteLimit> and <diskCacheMaxAge> both default to `0`. A check is performed every
 time new data is written to disk, and when these are properties are greater than zero the disk
 cache is trimmed accordingly. In most cases it will be more performant to periodically trim
 the disk cache manually, e.g. when the app exits or goes to background.
 */

@class TMCache;

typedef void (^TMCacheBlock)(TMCache *cache);
typedef void (^TMCacheDataBlock)(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL);

@interface TMCache : NSObject <NSCacheDelegate>

#pragma mark - Vitals
/// @name Vitals

/**
 The name of the cache is used in three places:
 - the disk cache directory path
 - the name property of the <queue>, which appears in stack traces
 - the `description` method
 
 Safe to access from any thread at any time.
 */
@property (copy, readonly) NSString *name;

/**
 A serial queue where nearly all work is performed. Only one queue is created per cache <name>,
 so this queue will be the same object across different instances with the same <name>. This
 queue can safely target any other queue for integration with an existing system.
 
 Safe to access from any thread at any time.
 */
@property (assign, readonly) dispatch_queue_t queue;

#pragma mark - Memory Cache
/// @name Memory Cache

/**
 When the memory cache exceeds this byte limit data will start being evicted in the background.
 
 @warning Do not access this property within the completion blocks of the other methods.
 */
@property (assign) NSUInteger memoryCacheByteLimit;

/**
 When the memory cache exceeds this object limit data will start being evicted in the background.
 
 @warning Do not access this property within the completion blocks of the other methods.
 */
@property (assign) NSUInteger memoryCacheCountLimit;

/**
 Executed for each `NSData` object right before it is evicted from the memory cache.
 
 @warning Do not access this property within the completion blocks of the other methods.
 */
@property (copy) TMCacheDataBlock willEvictDataFromMemoryBlock;

#pragma mark - Disk Cache
/// @name Disk Cache

/**
 When the disk cache exceeds this byte limit data will start being evicted in the background.
 
 @warning Do not access this property within the completion blocks of the other methods.
 */
@property (assign) NSUInteger diskCacheByteLimit;

/**
 Data in the disk cache older than this number of seconds will be evicted in the background.
 
 @warning Do not access this property within the completion blocks of the other methods.
 */
@property (assign) NSTimeInterval diskCacheMaxAge;

/**
 Executed for every file right before it is evicted from the disk cache, except as a result of
 <clearDiskCache:> or <clearAllCaches:>.
 
 @warning Do not access this property within the completion blocks of the other methods.
 */
@property (copy) TMCacheDataBlock willEvictDataFromDiskBlock;

#pragma mark - Current Usage
/// @name Current Usage

/**
 The current memory usage, in bytes.
 
 Safe to access from any thread at any time.
 */
@property (assign, readonly) NSUInteger currentMemoryBytes;

/**
 The current number of itmes cached in memory.
 
 Safe to access from any thread at any time.
 */
@property (assign, readonly) NSUInteger currentMemoryCount;

/**
 The current disk usage, in bytes.
 
 Safe to access from any thread at any time.
 */
@property (assign, readonly) NSUInteger currentDiskBytes;

/**
 The current number of itmes cached on disk.
 
 Safe to access from any thread at any time.
 */
@property (assign, readonly) NSUInteger currentDiskCount;

#pragma mark - Genesis
/// @name Genesis

/**
 Creates a new `TMCache`.
 
 @see name
 
 @param name A name for the cache.
 @returns A cache with the specified name.
 */
- (instancetype)initWithName:(NSString *)name;

/**
 Creates a new `TMCache`.
 
 @see name
 
 @param name A name for the cache.
 @returns An autoreleased cache with the specified name.
 */
+ (instancetype)withName:(NSString *)name;

/**
 A singleton shared cache accessible anywhere in the app.
 
 @returns The shared cache.
 */
+ (instancetype)sharedCache;

#pragma mark - Clear Caches
/// @name Clear Caches (Asynchronously)

/**
 Clears the memory cache asynchronously.
 
 @param completionBlock A block executed after the cache has been cleared.
 */
- (void)clearMemoryCache:(TMCacheBlock)completionBlock;

/**
 Clears the disk cache asynchronously.
 
 @param completionBlock A block executed after the cache has been cleared.
 */
- (void)clearDiskCache:(TMCacheBlock)completionBlock;

/**
 Clears both memory and disk caches asynchronously.
 
 @param completionBlock A block executed after the caches have been cleared.
 */
- (void)clearAllCaches:(TMCacheBlock)completionBlock;

/// @name Clear Caches (Synchronously)

/**
 Clears the memory cache synchronously, blocking the calling thread until finished.
 */
- (void)clearMemoryCache;

/**
 Clears the disk cache synchronously, blocking the calling thread until finished.
 */
- (void)clearDiskCache;

/**
 Clears both memory and disk caches synchronously, blocking the calling thread until finished.
 */
- (void)clearAllCaches;

#pragma mark - Trim Disk Cache
/// @name Trim Disk Cache (Asynchronously)

/**
 Trims the disk cache to the specified size asynchronously, starting with items having the
 oldest access date.
 
 @param bytes The maxmimum number of bytes left on disk after the trim.
 @param completionBlock A block executed after the disk has been trimmed.
 */
- (void)trimDiskCacheToSize:(NSUInteger)bytes block:(TMCacheBlock)completionBlock;

/**
 Trims the disk cache asynchronously of all items with an access date older than the specified date.
 
 @param date The date of the oldest permissible item in the disk cache.
 @param completionBlock A block executed after the disk has been trimmed.
 */
- (void)trimDiskCacheToDate:(NSDate *)date block:(TMCacheBlock)completionBlock;

/// @name Trim Disk Cache (Synchronously)

/**
 Trims the disk cache synchronously, blocking the calling thread until finished.
 
 @see trimDiskCacheToSize:block:
 
 @param bytes The maxmimum number of bytes left on disk after the trim.
 */
- (void)trimDiskCacheToSize:(NSUInteger)bytes;

/**
 Trims the disk cache synchronously, blocking the calling thread until finished.
 
 @see trimDiskCacheToDate:block:
 
 @param date The date of the oldest permissible item in the disk cache.
 */
- (void)trimDiskCacheToDate:(NSDate *)date;

#pragma mark - Read & Write
/// @name Read & Write (Asynchronously)

/**
 Retrives data with the specified key from the cache asynchronously. In the event of the data
 not being available the completion block is executed with `nil`.
 
 @param key The key for the requested data.
 @param completionBlock A block to be excuted after the data has been retrieved.
 */
- (void)dataForKey:(NSString *)key block:(TMCacheDataBlock)completionBlock;

/**
 Retrives the file URL with the specified key from the cache asynchronously. In the event of the file
 not being available the completion block is executed with `nil`. The data itself is not accessed.
 
 @param key The key for the requested file URL.
 @param completionBlock A block to be excuted after the data has been retrieved.
 */
- (void)fileURLForKey:(NSString *)key block:(TMCacheDataBlock)completionBlock;

/**
 Removes data with the specified key from the cache asynchronously.
 
 @param key The key for the data to be removed.
 @param completionBlock A block to be excuted after the data has been removed.
 */
- (void)removeDataForKey:(NSString *)key block:(TMCacheDataBlock)completionBlock;

/**
 Adds data to the cache asynchronously with the specified key.
 
 @param data The data to be added to the cache.
 @param key The key for the data being added.
 @param completionBlock A block to be excuted after the data has been added.
 */
- (void)setData:(NSData *)data forKey:(NSString *)key block:(TMCacheDataBlock)completionBlock;

/// @name Read & Write (Synchronously)

/**
 Retrives data with the specified key from the cache synchronously, blocking the calling thread
 until finished.
 
 @see dataForKey:block:
 
 @param key The key for the requested data.
 @returns The data for the specified key.
 */
- (NSData *)dataForKey:(NSString *)key;

/**
 Retrives the file URL with the specified key from the cache synchronously, blocking the calling
 thread until finished.
 
 @see fileURLForKey:block:
 
 @param key The key for the requested file URL.
 @returns The file URL for the specified key.
 */
- (NSURL *)fileURLForKey:(NSString *)key;

/**
 Removes data with the specified key from the cache synchronously, blocking the calling thread
 until finished.
 
 @see removeDataForKey:block:
 
 @param key The key for the data to be removed.
 */
- (void)removeDataForKey:(NSString *)key;

/**
 Adds data to the cache asynchronously with the specified key, blocking the calling thread
 until finished.
 
 @see setData:forKey:block:
 
 @param data The data to be added to the cache.
 @param key The key for the data being added.
 */
- (void)setData:(NSData *)data forKey:(NSString *)key;

@end
