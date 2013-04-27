/**
 `TMCache` is a thread safe key/value store designed for persisting temporary objects that are expensive to
 reproduce, such as downloaded data or the results of slow processing. It is comprised of two self-similar
 stores, one in memory (<TMMemoryCache>) and one on disk (<TMDiskCache>).
 
 `TMCache` itself actually does very little; its main function is providing a front end for a common use case:
 a small, fast memory cache that asynchronously persists itself to a large, slow disk cache. When objects are
 removed from the memory cache in response to an "apocalyptic" event they remain in the disk cache and are
 repopulated in memory the next time they are accessed. `TMCache` also does the tedious work of creating a
 dispatch group to wait for both caches to finish their operations without blocking each other.
 
 The parallel caches are accessible as public properties (<memoryCache> and <diskCache>) and can be manipulated
 separately if necessary. See the docs for <TMMemoryCache> and <TMDiskCache> for more details.
 */

#import "TMDiskCache.h"
#import "TMMemoryCache.h"

@class TMCache;

typedef void (^TMCacheBlock)(TMCache *cache);
typedef void (^TMCacheObjectBlock)(TMCache *cache, NSString *key, id object);

@interface TMCache : NSObject

@property (readonly) NSString *name;
@property (readonly) dispatch_queue_t queue;
@property (readonly) NSUInteger diskByteCount;

@property (readonly) TMDiskCache *diskCache;
@property (readonly) TMMemoryCache *memoryCache;

+ (instancetype)sharedCache;
- (instancetype)initWithName:(NSString *)name;

#pragma mark - Asynchronous

- (void)objectForKey:(NSString *)key block:(TMCacheObjectBlock)block;
- (void)setObject:(id <NSCoding>)object forKey:(NSString *)key block:(TMCacheObjectBlock)block;
- (void)removeObjectForKey:(NSString *)key block:(TMCacheObjectBlock)block;

- (void)trimToDate:(NSDate *)date block:(TMCacheBlock)block;
- (void)removeAllObjects:(TMCacheBlock)block;

#pragma mark - Synchronous

- (id)objectForKey:(NSString *)key;
- (void)setObject:(id <NSCoding>)object forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;

- (void)trimToDate:(NSDate *)date;
- (void)removeAllObjects;

@end
