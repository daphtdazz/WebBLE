# Todo List

## Autumn 2026

- [x] 🐞 Occasional crash returning from bookmarks view
- [x] 🐞 console open status not remembered on restart
- [x] 🐞 should not scroll console to top on tap at top
- [x] 🐞 pybricks work better https://github.com/daphtdazz/WebBLE/issues/62
- [ ] 🐞 espruino IDE cannot reconnect to a disconnected device, or reconnect easily (assuming this is supposed to be possible)
- [ ] 🏎️ better performance of console when lots of logs
- [x] ✨ double tap divider / drag area of console to hide console
- [x] ✨ drag down on web view to refresh
- [ ] ✨ better stack traces in console 
- [ ] ✨ better way of selecting multiple logs to copy from console
- [ ] ✨ nicer device picker view
- [ ] ✨ console view scroll following new logs
- [ ] ✨ timestamp showable in console logs 
- [x] ✨ better force refresh behaviour (long-tap refresh button)
- [x] ✨ flow for adding link to home screen via Shortcuts app
- [x] ✨ support downloads, primarily for file management in pybricks

## Chunky features

- tabbed browsing??  upgrade cost??
    - background tabs should stop scanning for devices 
        https://webbluetoothcg.github.io/web-bluetooth/#handling-visibility-change

### Downloads

1. ✅ Move logging management into WBWebViewContainerController
2. ✅ Get rid of WBWebViewController
3. ✅ Move refresh indication into WBWebViewContainerController
4. ✅ Create WBWebDelegate, implemented by ViewController instead of webView(WKWebView, didStartProvisionalNavigation:WKNavigation)
   - optional method didStartNavigationTo(URL)
5. ✅ Rename WBWebViewContainerController WBWebViewController
6. ✅ WBWebViewController implement navigation delegate download methods
    - ✅ if the host has already had downloads allowed, allow immediately
    - ✅ otherwise ask for permission
7. WBWebViewController implement download delegate methods
8. ✅ Add download manager interface to preferences (new preferences interface manager class / singleton)
    4. ✅ Track which site hosts have had downloads allowed and when the last download was
5. ✅ Add downloads toobar button which shows a list of the downloads
    ✅ - option to delete each and 🚫 share / export (using UIDocumentPickerViewController(forExportingURLs:)?) (can do via Files)
9. ✅ Ensure when uploading that we can see the downloads.
