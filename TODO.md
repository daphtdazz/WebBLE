# Todo List

## Autumn 2026

- [x] 🐞 Occasional crash returning from bookmarks view
- [x] 🐞 console open status not remembered on restart
- [x] 🐞 should not scroll console to top on tap at top
- [x] 🐞 pybricks work better https://github.com/daphtdazz/WebBLE/issues/62
- [x] 🐞 espruino IDE cannot reconnect to a disconnected device, or reconnect easily (assuming this is supposed to be possible)
- [ ] 🏎️ better performance of console when lots of logs
- [ ] 🔒 check user activation from native before scanning
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
- [ ] ✨ way to hide the title and tool bar without scrolling
- [ ] 📜 Add documentation page

## Chunky features

- tabbed browsing??  upgrade cost??
    - background tabs should stop scanning for devices
        https://webbluetoothcg.github.io/web-bluetooth/#handling-visibility-change

## Details about items


### Check User Activation

- check result of `navigator.userActivation.isActive` run in the web view before starting scan and showing the picker.


### Documentation

Webpage on greenparksoftware.co.uk link from toolbar

- how to show the address / tool bar when they hide (tap top / bottom of the screen)
- how to show the console (double tap two fingers / tap on toolbar button)
- how to hide it (double tap on the divider)
- how to force refresh


### Reconnections

- `getDevices()` should return list of allowed devices for the realm
- `.gatt.connect()` should work after `.gatt.disconnect()` if device is in range
- `device.forget()` to remove from storage
- External ID of device should persist over reload, so probably a session UUIDv4 XORed with the internal device ID.
- BluetoothPermissionStorage is passed to the various routines as the storage for allowed devices. It is different for each "current environment settings object", which is 1-to-1 with the global javascript object, i.e. the window. this is the "bluetooth" keyed extra permission data used for "powerful" features
- it should be usable by the Permissions API to query (and revoke access) for allowed devices following a reload see [here](https://bluetooth.spec.whatwg.org/#permission-api-integration). That would require the ID of the device to persist over a reload.
- requestDevice *may* add a device to permission storage
- `getDevices()` fetches devices from permission storage

```
navigator.permissions.query({
  name: "bluetooth",
  deviceId: sessionStorage.lastDevice,
})
```


```
BluetoothPermissionStorage.allowedDevices = [
  {
    required DOMString deviceId;
    required boolean mayUseGATT;
    // An allowedServices of "all" means all services are allowed.
    required (DOMString or sequence<UUID>) allowedServices;
    required sequence<unsigned short> allowedManufacturerData;
  }
]
```



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
