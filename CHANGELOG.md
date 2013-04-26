### 1.0.2 -- 2013 April 26 ###

- [fix] TMCache: cache hits from memory will now update access time on disk
- [fix] TMDiskCache: set & remove methods now acquire a `UIBackgroundTaskIdentifier`
- [fix] TMDiskCache: will/didAddObject blocks actually get executed
- [fix] TMDiskCache: `trimToSize:` now correctly removes objects in order of size
- [fix] TMMemoryCache: `trimToCost:` now correctly removes objects in order of cost
- [new] TMDiskCache: added method `trimToSizeByDate:`
- [new] TMMemoryCache: added method `trimToCostByDate:`
- [new] TMDiskCache: added properties `willRemoveAllObjectsBlock` & `didRemoveAllObjectsBlock`
- [new] TMCache: added unit tests

### 1.0.1 -- 2013 April 23 ###

- added an optional "cost limit" to `TMMemoryCache`, including new properties and methods
- calling `[TMDiskCache trimToDate:]` with `[NSDate distantPast]` will now clear the cache
- calling `[TMDiskCache trimDiskToSize:]` will now remove files in order of access date
- setting the byte limit on `TMDiskCache` to 0 will no longer clear the cache (0 means no limit)
