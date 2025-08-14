# Creator Tool → Likely Source Mapping

| Creator Tool value                | Likely Source / App               | Filename pattern clues | Typical resolution limits | Notes |
|------------------------------------|------------------------------------|------------------------|---------------------------|-------|
| *(blank)*                          | iPhone Camera, WhatsApp, Signal, Telegram (compressed) | `IMG_####.JPG`, `IMG-YYYYMMDD-WA####.jpg` | Native iPhone full res, WhatsApp ~2048px | Needs other EXIF clues for certainty |
| `Facebook`                         | Facebook app or Messenger         | UUID `.jpg` or `FB_IMG_########.jpg` | Up to ~4096px | Preserves DateTimeOriginal, strips GPS |
| `Instagram`                        | Instagram                         | UUID `.jpg` | 1080px wide for feed, up to 1440px for stories | Cropped/aspect ratio fixed |
| `Apple Photos` / `Photos`          | iOS/macOS Photos edit/export      | Keeps original filename | Original res | Set when image is edited or exported via Photos |
| `Snapchat`                         | Snapchat                          | UUID `.jpg` or `snap_original.jpg` | Device-dependent, often screen aspect | Date often reset to send time |
| `LINE`                              | LINE Messenger                    | `LINE_P####.jpg` | Varies, often compressed | Strips GPS, may keep DateTimeOriginal |
| `Viber`                             | Viber Messenger                   | Random alphanumeric   | ~1600–2000px | Strips most EXIF |
| `WeChat`                            | WeChat                            | `mmexport###########.jpg` | ~1080px wide default | Compression-heavy |
| `Adobe Photoshop …` (any variant)  | Adobe Photoshop (desktop/mobile)   | User-defined or export name | User choice | Full EXIF unless stripped on export |
| `Adobe Lightroom`                  | Adobe Lightroom                   | User-defined | Full EXIF | Adds full XMP data |
| `Snapseed`                         | Google Snapseed                   | Original name | Original res | Often adds Snapseed XMP namespace |
| `VSCO`                             | VSCO                               | Original name | Original res | Adds VSCO-specific XMP tags |
| `Google Photos`                    | Google Photos export/download     | `IMG_####.JPG`, `PXL_########.jpg` | Original res if not compressed | Sometimes replaces Software tag with “Google” |
| `TikTok`                           | TikTok                            | Random alphanumeric   | 1080px tall max | Rare on still images; more for video frames |
| `Twitter`                          | Twitter / X (app or web download) | Random alphanumeric   | 4096px wide max | Strips most EXIF |
| `Pinterest`                        | Pinterest                         | Random alphanumeric   | Varies | Usually stripped EXIF except Creator Tool |
| `Shutterstock Editor`              | Shutterstock online editor        | Stock IDs             | Varies | Adds stock license data |
| `Canva`                            | Canva                             | Original or export name | Export settings | Adds Canva XMP namespace |
| `GIMP 2.x`                         | GIMP                               | User-defined          | Export settings | Linux image editing |
| `Krita`                            | Krita                              | User-defined          | Export settings | Often in creative workflows |
