### 1.0.2 -- 2013 April 26 ###

- TMCache: cache hits from memory will now update access time on disk
- TMDiskCache: set & remove methods now acquire a `UIBackgroundTaskIdentifier`

### 1.0.1 -- 2013 April 23 ###

- added an optional "cost limit" to `TMMemoryCache`, including new properties and methods
- calling `[TMDiskCache trimToDate:]` with `[NSDate distantPast]` will now clear the cache
- calling `[TMDiskCache trimDiskToSize:]` will now remove files in order of access date
- setting the byte limit on `TMDiskCache` to 0 will no longer clear the cache (0 means no limit)
