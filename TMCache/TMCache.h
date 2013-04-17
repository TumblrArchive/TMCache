/**
 `TMCache` combines the advantages of <TMMemoryCache> and <TMDiskCache>.
 */

#import "TMDiskCache.h"
#import "TMMemoryCache.h"

@class TMCache;

typedef void (^TMCacheBlock)(TMCache *cache);
typedef void (^TMCacheObjectBlock)(TMCache *cache, NSString *key, id object);

@interface TMCache : NSObject

@property (readonly) NSString *name;
@property (readonly) dispatch_queue_t queue;

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
