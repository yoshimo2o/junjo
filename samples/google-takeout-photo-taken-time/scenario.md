## Scenario

This scenario suggests that `photoTakenTime` from Google Takeout's metadata can be a reliable source for timestamp.

This image `IMAGE005.jpg` was captured using an Intel webcam, which did not embed EXIF metadata - common for early consumer webcams. As a result, the file lacks standard EXIF tags such as `DateTimeOriginal`.

Despite this, the associated Google Takeout metadata correctly identifies the photo’s capture time. This indicates that Google Photos likely inferred the timestamp from the file system’s creation or modification time when no EXIF date information was available.

## ExifTool report

```
ExifTool Version Number         : 13.30
File Name                       : IMAGE005.JPG
Directory                       : /path/removed
File Size                       : 20 kB
File Modification Date/Time     : 2025:07:27 16:47:06+08:00
File Access Date/Time           : 2025:08:03 00:30:26+08:00
File Inode Change Date/Time     : 2025:08:03 00:29:40+08:00
File Permissions                : -rw-r--r--
File Type                       : JPEG
File Type Extension             : jpg
MIME Type                       : image/jpeg
JFIF Version                    : 1.01
Resolution Unit                 : None
X Resolution                    : 1
Y Resolution                    : 1
Exif Byte Order                 : Little-endian (Intel, II)
Software                        : Picasa
Exif Version                    : 0220
Color Space                     : sRGB
Exif Image Width                : 320
Exif Image Height               : 240
Interoperability Index          : R98 - DCF basic file (sRGB)
Interoperability Version        : 0100
Image Unique ID                 : be0381973760142b0000000000000000
XMP Toolkit                     : XMP Core 5.5.0
Image Width                     : 320
Image Height                    : 240
Encoding Process                : Baseline DCT, Huffman coding
Bits Per Sample                 : 8
Color Components                : 3
Y Cb Cr Sub Sampling            : YCbCr4:4:4 (1 1)
Image Size                      : 320x240
Megapixels                      : 0.077
```

## Google Takeout metadata

```json
{
  "title": "IMAGE005.JPG",
  "description": "",
  "imageViews": "16",
  "creationTime": {
    "timestamp": "1473432025",
    "formatted": "Sep 9, 2016, 2:40:25 PM UTC"
  },
  "photoTakenTime": {
    "timestamp": "1026484386",
    "formatted": "Jul 12, 2002, 2:33:06 PM UTC"
  },
  "geoData": {
    "latitude": 0.0,
    "longitude": 0.0,
    "altitude": 0.0,
    "latitudeSpan": 0.0,
    "longitudeSpan": 0.0
  },
  "url": "https://photos.google.com/photo/PlaceHolder09876TestBlockXYZ12345678MnOpQR",
  "googlePhotosOrigin": {
    "photosDesktopUploader": {
    }
  }
}
```
