---
name: "Bug report — AppImage (please attach debug log)"
about: "Report crashes or other bugs. Run the AppImage with APPIMAGE_DEBUG=1 and attach the generated log file (the AppImage will create the file automatically and print its path)."
title: "[BUG] "
labels: ["bug"]
---

Please fill out the sections below and be sure to follow the "Collect the AppImage debug log" steps before submitting.

## Collect the AppImage debug log (required)
1. Run the AppImage with debug enabled:
   ```sh
   APPIMAGE_DEBUG=1 ./MyApp.AppImage
   ```
   - The AppImage will create a debug log automatically and will print the path to that log file in the terminal output.
   - Attach that file to this issue.

## Checklist
- [ ] I ran the AppImage with `APPIMAGE_DEBUG=1` environment variable set.
- [ ] I attached the debug log produced by the AppImage.
