## 1.3.1

* Fix incorrect file name when the file is Live Photo on iOS

## 1.3.0

* Added support for retrieving the original file name

## 1.2.5

* Fix unable to get path of slow motion videos

## 1.2.4

* Fix old thumbnail of edited photos and videos

## 1.2.3

* Fix crash when generating thumbnail for unsupported photos or videos on Android

## 1.2.2

* Fix thumbnails not loading on android 10

## 1.2.1+4

* Use DispatchSemaphore instead of DispatchGroup

## 1.2.1+3

* Fix path is null on iOS 13 (simulator) because [PHImageFileURLKey] is not provided anymore

## 1.2.0+2

* Fix crash on android when getting the thumbnail

## 1.2.0+1

* Cache video duration for fast retrieval on iOS

## 1.2.0

iOS
* Return video `duration` with `getMediaFile`
* Duration can also be returned with `getAlbums` if the argument `loadIOSPath` is true

Android
* Return video `duration` and `mimeType` of files with `getMediaFile` and getAlbums

## 1.1.1

* On iOS, fix crash when retrieving albums

## 1.1.0+1

* Added a new api to get media file based on file id
* For iOS only, new flag [loadIOSPaths] added to optimize the speed of querying the files.

## 1.0.0+2

* Remove meta dependency

## 1.0.0+1

* Update docs

## 1.0.0

* Initial release
