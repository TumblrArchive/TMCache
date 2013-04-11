#import "TMCache.h"

#define TMCacheError(error) if (error) { NSLog(@"%@ (%d) ERROR: %@", \
            [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
            __LINE__, [error localizedDescription]); }

NSString * const TMCachePrefix = @"com.tumblr.TMCache";
NSUInteger const TMCacheDefaultMemoryLimit = 0xA00000; // 10 MB

@interface TMCache ()
#if OS_OBJECT_USE_OBJC
@property (strong) dispatch_queue_t queue;
#else
@property (assign) dispatch_queue_t queue;
#endif
@property (copy) NSString *name;
@property (strong) NSMutableDictionary *dataKeys;
@property (strong) NSCache *cache;
@property (strong) NSString *cachePath;
@property (assign) NSUInteger currentMemoryBytes;
@property (assign) NSUInteger currentMemoryCount;
@property (assign) NSUInteger currentDiskBytes;
@property (assign) NSUInteger currentDiskCount;
@end

@implementation TMCache

@synthesize diskCacheByteLimit = _diskCacheByteLimit;
@synthesize diskCacheMaxAge = _diskCacheMaxAge;
@synthesize willEvictDataFromMemoryBlock = _willEvictDataFromMemoryBlock;
@synthesize willEvictDataFromDiskBlock = _willEvictDataFromDiskBlock;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.cache.delegate = nil;

    #if !OS_OBJECT_USE_OBJC
    dispatch_release(_queue);
    _queue = NULL;
    #endif
}

- (instancetype)initWithName:(NSString *)name
{
    if (![name length])
        return nil;

    if (self = [super init]) {
        self.name = name;

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *dirPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:TMCachePrefix];
        self.cachePath = [dirPath stringByAppendingPathComponent:self.name];

        self.cache = [[NSCache alloc] init];
        self.cache.name = [[NSString alloc] initWithFormat:@"%@.%p", TMCachePrefix, self];
        self.cache.delegate = self;

        self.queue = dispatch_queue_create([self.cache.name UTF8String], DISPATCH_QUEUE_SERIAL);
        self.dataKeys = [[NSMutableDictionary alloc] init];
        self.willEvictDataFromMemoryBlock = nil;
        self.willEvictDataFromDiskBlock = nil;

        self.currentMemoryBytes = 0;
        self.currentMemoryCount = 0;
        self.currentDiskBytes = 0;
        self.currentDiskCount = 0;

        self.memoryCacheByteLimit = TMCacheDefaultMemoryLimit;
        self.memoryCacheCountLimit = 0;
        self.diskCacheByteLimit = 0;
        self.diskCacheMaxAge = 0;

        __weak TMCache *weakSelf = self;

        dispatch_async(self.queue, ^{
            TMCache *strongSelf = weakSelf;
            if (!strongSelf)
                return;
            
            /**
             All instances of `TMCache` in the app serialize their queues against the
             sharedCache's queue. This allows multiple caches to exist with the same
             name and not interfere with each other's disk access.
             */
            
            if (strongSelf != [TMCache sharedCache])
                dispatch_set_target_queue(strongSelf.queue, [[TMCache sharedCache] queue]);
            
            __weak TMCache *weakSelf = strongSelf;
            
            dispatch_async(strongSelf.queue, ^{
                [weakSelf createCacheDirectory];
                [weakSelf updateDiskBytesAndCount];
            });
        });

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:[UIApplication sharedApplication]];
    }

    return self;
}

+ (instancetype)withName:(NSString *)name
{
    return [[self alloc] initWithName:name];
}

+ (instancetype)sharedCache
{
    static id cache = nil;
    static dispatch_once_t predicate;

    dispatch_once(&predicate, ^{
        cache = [[self alloc] initWithName:NSStringFromClass(self)];
    });

    return cache;
}

#pragma mark - <NSCacheDelegate>

- (void)cache:(NSCache *)cache willEvictObject:(id)object
{
    __weak TMCache *weakSelf = self;
    
    void (^evictionBlock)() = ^{
        TMCache *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        
        NSData *data = (NSData *)object;
        NSUInteger dataLength = [data length];
        NSValue *dataValue = [NSValue valueWithNonretainedObject:data];
        
        NSString *key = [strongSelf.dataKeys objectForKey:dataValue];
        [strongSelf.dataKeys removeObjectForKey:dataValue];
        
        NSURL *fileURL = [strongSelf escapedFileURLForKey:key];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]];
        
        if (strongSelf->_willEvictDataFromMemoryBlock)
            strongSelf->_willEvictDataFromMemoryBlock(self, key, data, fileExists ? fileURL : nil);
        
        strongSelf.currentMemoryBytes -= dataLength;
        strongSelf.currentMemoryCount -= 1;
    };
    
    /**
     When `TMCache` is performing the eviction (via `removeDataForKey`, `clearMemoryCache`,
     or `clearAllCachesSynchronously`) this method will always be called on `self.queue`.
     
     When the system does evictions (e.g. when the app goes to background) this method will be
     called on the main thread and should be sync'd with `self.queue` for seriality.
     */
    
    if ([NSThread isMainThread]) {
        dispatch_sync(self.queue, evictionBlock);
    } else {
        evictionBlock();
    }
}

#pragma mark - Private Methods

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    [self clearMemoryCache];
}

+ (NSString *)escapedString:(NSString *)string
{
    if (![string length])
        return @"";

    CFStringRef static const charsToEscape = CFSTR(".:/");
    CFStringRef escapedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                        (__bridge CFStringRef)string,
                                                                        NULL,
                                                                        charsToEscape,
                                                                        kCFStringEncodingUTF8);
    return (__bridge_transfer NSString *)escapedString;
}

+ (NSString *)unescapedString:(NSString *)string
{
    if (![string length])
        return @"";

    CFStringRef unescapedString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                          (__bridge CFStringRef)string,
                                                                                          CFSTR(""),
                                                                                          kCFStringEncodingUTF8);

    return (__bridge_transfer NSString *)unescapedString;
}

- (NSURL *)escapedFileURLForKey:(NSString *)key
{
    if (![key length])
        return nil;
    
    NSString *path = [self.cachePath stringByAppendingPathComponent:[[self class] escapedString:key]];

    return [NSURL fileURLWithPath:path];
}

- (NSString *)keyForEscapedFileURL:(NSURL *)url
{
    NSString *fileName = [url lastPathComponent];
    if (!fileName)
        return nil;

    return [[self class] unescapedString:fileName];
}

#pragma mark - Private Queue Methods 

- (NSDictionary *)cacheFilePathsWithAttributes
{
    // should only be called privately on `self.queue`
    
    NSError *error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.cachePath error:&error];
    TMCacheError(error);
    
    if (![files count])
        return nil;
    
    NSMutableDictionary *filePathsWithAttributes = [[NSMutableDictionary alloc] initWithCapacity:[files count]];
    
    for (NSString *fileName in files) {
        NSString *filePath = [self.cachePath stringByAppendingPathComponent:fileName];
        
        error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
        TMCacheError(error);
        
        if (!attributes)
            continue;
        
        [filePathsWithAttributes setObject:attributes forKey:filePath];
    }
    
    return [[NSDictionary alloc] initWithDictionary:filePathsWithAttributes];
}

- (void)setDataInMemoryCache:(NSData *)data forKey:(NSString *)key
{
    // should only be called privately on `self.queue`
    
    NSUInteger dataLength = [data length];
    
    [self.dataKeys setObject:key forKey:[NSValue valueWithNonretainedObject:data]];
    [self.cache setObject:data forKey:key cost:dataLength];
    
    self.currentMemoryBytes += dataLength;
    self.currentMemoryCount += 1;
}

- (void)setFileModificationDate:(NSDate *)date fileURL:(NSURL *)url
{
    // should only be called privately on `self.queue`
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:NO];
    if (!fileExists)
        return;

    NSError *error = nil;
    [[NSFileManager defaultManager] setAttributes:@{ NSFileModificationDate: date }
                                     ofItemAtPath:[url path]
                                            error:&error];
    TMCacheError(error);
}

- (void)createCacheDirectory
{
    // should only be called privately on `self.queue`

    if ([[NSFileManager defaultManager] fileExistsAtPath:self.cachePath isDirectory:nil])
        return;

    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:self.cachePath withIntermediateDirectories:YES attributes:nil error:&error];
    TMCacheError(error);

    self.currentDiskBytes = 0;
    self.currentDiskCount = 0;
}

- (void)updateDiskBytesAndCount
{
    // should only be called privately on `self.queue`

    NSUInteger diskBytes = 0;

    NSError *error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.cachePath error:&error];
    TMCacheError(error);

    for (NSString *fileName in files) {
        NSString *filePath = [self.cachePath stringByAppendingPathComponent:fileName];

        error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
        TMCacheError(error);
        
        if (!attributes)
            continue;

        diskBytes += [attributes fileSize];
    }

    self.currentDiskBytes = diskBytes;
    self.currentDiskCount = [files count];
}

- (void)removeFileAtURL:(NSURL *)fileURL
{
    // should only be called privately on `self.queue`

    NSString *filePath = [fileURL path];

    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        if (_willEvictDataFromDiskBlock) {
            NSString *key = [self keyForEscapedFileURL:fileURL];
            _willEvictDataFromDiskBlock(self, key, nil, fileURL);
        }
        
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
        TMCacheError(error);

        error = nil;
        BOOL removed = [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
        TMCacheError(error);

        if (removed) {
            self.currentDiskBytes -= [attributes fileSize];
            self.currentDiskCount -= 1;
        }
    }
}

#pragma mark - Clearing (Asynchronous)

- (void)clearMemoryCache:(TMCacheBlock)completionBlock
{
    __weak TMCache *weakSelf = self;

    dispatch_async(self.queue, ^{
        TMCache *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        
        [strongSelf.cache removeAllObjects];
        [strongSelf.dataKeys removeAllObjects];

        if (completionBlock)
            completionBlock(strongSelf);
    });
}

- (void)clearDiskCache:(TMCacheBlock)completionBlock
{
    __weak TMCache *weakSelf = self;

    dispatch_async(self.queue, ^{
        TMCache *strongSelf = weakSelf;
        if (!strongSelf)
            return;

        if ([[NSFileManager defaultManager] fileExistsAtPath:strongSelf.cachePath]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:strongSelf.cachePath error:&error];
            TMCacheError(error);
        }
        
        [strongSelf createCacheDirectory];

        if (completionBlock)
            completionBlock(strongSelf);
    });
}

- (void)clearAllCaches:(TMCacheBlock)completionBlock
{
    __weak TMCache *weakSelf = self;
    
    dispatch_async(self.queue, ^{
        TMCache *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        
        [strongSelf.cache removeAllObjects];
        [strongSelf.dataKeys removeAllObjects];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:strongSelf.cachePath]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:strongSelf.cachePath error:&error];
            TMCacheError(error);
        }
        
        [strongSelf createCacheDirectory];
        
        if (completionBlock)
            completionBlock(strongSelf);
    });
}

#pragma mark - Clearing (Synchronous)

- (void)clearMemoryCache
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [self clearMemoryCache:^(TMCache *cache) {
        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    #if !OS_OBJECT_USE_OBJC
    dispatch_release(semaphore);
    #endif
}

- (void)clearDiskCache
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [self clearDiskCache:^(TMCache *cache) {
        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    #if !OS_OBJECT_USE_OBJC
    dispatch_release(semaphore);
    #endif
}

- (void)clearAllCaches
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [self clearAllCaches:^(TMCache *cache) {
        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    #if !OS_OBJECT_USE_OBJC
    dispatch_release(semaphore);
    #endif
}

#pragma mark - Trimming (Asynchronous) 

- (void)trimDiskCacheToSize:(NSUInteger)byteLimit block:(TMCacheBlock)completionBlock
{
    if (byteLimit <= 0) {
        [self clearDiskCache];
        return;
    }
    
    __weak TMCache *weakSelf = self;

    dispatch_async(self.queue, ^{
        TMCache *strongSelf = weakSelf;
        if (!strongSelf)
            return;

        NSDictionary *filePathsWithAttributes = [strongSelf cacheFilePathsWithAttributes];
        if (!filePathsWithAttributes)
            return;

        NSArray *filePathsSortedByDate = [filePathsWithAttributes keysSortedByValueUsingComparator:^(id file0, id file1) {
            return [[file0 fileModificationDate] compare:[file1 fileModificationDate]];
        }];

        for (NSString *filePath in filePathsSortedByDate) {
            if (strongSelf.currentDiskBytes <= byteLimit)
                break;

            [strongSelf removeFileAtURL:[NSURL fileURLWithPath:filePath isDirectory:NO]];
        }
        
        if (completionBlock)
            completionBlock(strongSelf);
    });
}

- (void)trimDiskCacheToDate:(NSDate *)trimDate block:(TMCacheBlock)completionBlock
{
    if (!trimDate)
        return;

    if ([trimDate isEqualToDate:[NSDate distantPast]]) {
        [self clearDiskCache];
        return;
    }

    __weak TMCache *weakSelf = self;

    dispatch_async(self.queue, ^{
        TMCache *strongSelf = weakSelf;
        if (!strongSelf)
            return;

        NSDictionary *filePathsWithAttributes = [strongSelf cacheFilePathsWithAttributes];
        if (!filePathsWithAttributes)
            return;

        NSArray *filePathsSortedByDate = [filePathsWithAttributes keysSortedByValueUsingComparator:^(id file0, id file1) {
            return [[file0 fileModificationDate] compare:[file1 fileModificationDate]];
        }];

        for (NSString *filePath in filePathsSortedByDate) {
            NSDictionary *attributes = [filePathsWithAttributes objectForKey:filePath];
            if (!attributes)
                continue;

            if ([[attributes fileModificationDate] compare:trimDate] != NSOrderedDescending) {
                [strongSelf removeFileAtURL:[NSURL fileURLWithPath:filePath isDirectory:NO]];
            } else {
                break;
            }
        }
        
        if (completionBlock)
            completionBlock(strongSelf);
    });
}

#pragma mark - Trimming (Synchronous)

- (void)trimDiskCacheToSize:(NSUInteger)bytes
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self trimDiskCacheToSize:bytes block:^(TMCache *cache) {
        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    #if !OS_OBJECT_USE_OBJC
    dispatch_release(semaphore);
    #endif
}

- (void)trimDiskCacheToDate:(NSDate *)date
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [self trimDiskCacheToDate:date block:^(TMCache *cache) {
        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    #if !OS_OBJECT_USE_OBJC
    dispatch_release(semaphore);
    #endif
}

#pragma mark - Read & Write (Asynchronous)

- (void)dataForKey:(NSString *)key block:(TMCacheDataBlock)completionBlock
{
    NSDate *now = [[NSDate alloc] init];
    
    if (!completionBlock || ![key length])
        return;
    
    __weak TMCache *weakSelf = self;
    
    dispatch_async(self.queue, ^{
        TMCache *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        
        NSData *data = [strongSelf.cache objectForKey:key];
        NSURL *fileURL = [strongSelf escapedFileURLForKey:key];
        
        if (!data && [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
            [strongSelf setFileModificationDate:now fileURL:fileURL];

            NSError *error = nil;
            data = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingMappedIfSafe error:&error];
            TMCacheError(error);
            
            if (data)
                [strongSelf setDataInMemoryCache:data forKey:key];
        }
        
        completionBlock(strongSelf, key, data, fileURL);
    });
}

- (void)fileURLForKey:(NSString *)key block:(TMCacheDataBlock)completionBlock
{
    if (!completionBlock || ![key length])
        return;
    
    __weak TMCache *weakSelf = self;
    
    dispatch_async(self.queue, ^{
        TMCache *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        
        NSURL *fileURL = [strongSelf escapedFileURLForKey:key];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]];
        completionBlock(strongSelf, key, nil, fileExists ? fileURL : nil);
    });
}

- (void)removeDataForKey:(NSString *)key block:(TMCacheDataBlock)completionBlock
{
    if (![key length])
        return;
    
    __weak TMCache *weakSelf = self;
    
    dispatch_async(self.queue, ^{
        TMCache *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        
        NSData *data = [strongSelf.cache objectForKey:key];
        if (data)
            [strongSelf.cache removeObjectForKey:key];
        
        NSURL *fileURL = [strongSelf escapedFileURLForKey:key];
        [strongSelf removeFileAtURL:fileURL];
        
        if (completionBlock)
            completionBlock(strongSelf, key, nil, fileURL);
    });
}

- (void)setData:(NSData *)data forKey:(NSString *)key block:(TMCacheDataBlock)completionBlock
{
    if (![key length])
        return;
    
    if (!data) {
        [self removeDataForKey:key block:nil];
        return;
    }
    
    __weak TMCache *weakSelf = self;
    
    dispatch_async(self.queue, ^{
        TMCache *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        
        [strongSelf setDataInMemoryCache:data forKey:key];
        
        NSURL *fileURL = [strongSelf escapedFileURLForKey:key];
        
        NSError *error = nil;
        BOOL written = [data writeToURL:fileURL options:0 error:&error];
        TMCacheError(error);
        
        if (written) {
            strongSelf.currentDiskBytes += [data length];
            strongSelf.currentDiskCount += 1;
        }
        
        if (completionBlock)
            completionBlock(strongSelf, key, data, fileURL);
        
        if (strongSelf->_diskCacheByteLimit > 0) {
            if (strongSelf.currentDiskBytes > strongSelf->_diskCacheByteLimit)
                [strongSelf trimDiskCacheToSize:strongSelf->_diskCacheByteLimit block:nil];
        }
        
        if (strongSelf->_diskCacheMaxAge > 0.0) {
            NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceNow:-strongSelf->_diskCacheMaxAge];
            [strongSelf trimDiskCacheToDate:date block:nil];
        }
    });
}

#pragma mark - Read & Write (Synchronous)

- (NSData *)dataForKey:(NSString *)key
{
    __block NSData *dataForKey = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self dataForKey:key block:^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        dataForKey = data;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    #if !OS_OBJECT_USE_OBJC
    dispatch_release(semaphore);
    #endif

    return dataForKey;
}

- (NSURL *)fileURLForKey:(NSString *)key
{
    __block NSURL *fileURLForKey = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [self fileURLForKey:key block:^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        fileURLForKey = fileURL;
        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    #if !OS_OBJECT_USE_OBJC
    dispatch_release(semaphore);
    #endif

    return fileURLForKey;
}

- (void)removeDataForKey:(NSString *)key
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self removeDataForKey:key block:^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    #if !OS_OBJECT_USE_OBJC
    dispatch_release(semaphore);
    #endif
}

- (void)setData:(NSData *)data forKey:(NSString *)key
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self setData:data forKey:key block:^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    #if !OS_OBJECT_USE_OBJC
    dispatch_release(semaphore);
    #endif
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
    __weak TMCache *weakSelf = self;

    dispatch_async(self.queue, ^{
        weakSelf.cache.totalCostLimit = limit;
    });
}

- (NSUInteger)memoryCacheCountLimit
{
    __block NSUInteger limit = 0;

    dispatch_sync(self.queue, ^{
        limit = self.cache.countLimit;
    });

    return limit;
}

- (void)setMemoryCacheCountLimit:(NSUInteger)limit
{
    __weak TMCache *weakSelf = self;

    dispatch_async(self.queue, ^{
        weakSelf.cache.countLimit = limit;
    });
}

- (NSUInteger)diskCacheByteLimit
{
    __block NSUInteger limit = 0;

    dispatch_sync(self.queue, ^{
        limit = _diskCacheByteLimit;
    });

    return limit;
}

- (void)setDiskCacheByteLimit:(NSUInteger)limit
{
    __weak TMCache *weakSelf = self;

    dispatch_async(self.queue, ^{
        TMCache *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        
        strongSelf->_diskCacheByteLimit = limit;

        if (limit > 0)
            [strongSelf trimDiskCacheToSize:limit block:nil];
    });
}

- (NSTimeInterval)diskCacheMaxAge
{
    __block NSTimeInterval maxAge = 0.0;

    dispatch_sync(self.queue, ^{
        maxAge = _diskCacheMaxAge;
    });

    return maxAge;
}

- (void)setDiskCacheMaxAge:(NSTimeInterval)maxAge
{
    __weak TMCache *weakSelf = self;

    dispatch_async(self.queue, ^{
        TMCache *strongSelf = weakSelf;
        if (!strongSelf)
            return;

        strongSelf->_diskCacheMaxAge = maxAge;

        if (maxAge > 0.0) {
            NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceNow:-maxAge];
            [strongSelf trimDiskCacheToDate:date block:nil];
        }
    });
}

- (TMCacheDataBlock)willEvictDataFromMemoryBlock
{
    __block TMCacheDataBlock block = nil;
    
    dispatch_sync(self.queue, ^{
        block = _willEvictDataFromMemoryBlock;
    });
    
    return block;
}

- (void)setWillEvictDataFromMemoryBlock:(TMCacheDataBlock)block
{
    __weak TMCache *weakSelf = self;
    
    dispatch_async(self.queue, ^{
        TMCache *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        
        strongSelf->_willEvictDataFromMemoryBlock = [block copy];
    });
}

- (TMCacheDataBlock)willEvictDataFromDiskBlock
{
    __block TMCacheDataBlock block = nil;
    
    dispatch_sync(self.queue, ^{
        block = _willEvictDataFromMemoryBlock;
    });
    
    return block;
}

- (void)setWillEvictDataFromDiskBlock:(TMCacheDataBlock)block
{
    __weak TMCache *weakSelf = self;
    
    dispatch_async(self.queue, ^{
        TMCache *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        
        strongSelf->_willEvictDataFromDiskBlock = [block copy];
    });
}

@end
