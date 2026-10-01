# 1.0 test cases

## Selecting devices from greenparksoftware.co.uk

1. request device when one in range. Cancel. Turn off device. Request again. Should not appear in menu.
  - ok 1, 1.1-2
2. request device when no devices in range. "Done" should be disabled, "Cancel" should cancel. 
  - ok 1, 1.1-2
3. request device, see device appear, turn off device, device should disappear... 
  - na 1, replace with 4.
4. request device, see device appear, turn off device and select it before it has a chance to disappear.
  - behaviour is that we should attempt to connect, but that it will continue attempting even if device doesn't come back
  - ok 1, 
5. connect to a device, send a command, turn off device, disconnect sent, request new device should be clear of that old device
  - fail 1, it wasn't clear, but came clear after cancelling and trying again.
  - same behaviour 1.1-2
6. select device after it has been switched off. Cancel connection attempt. Request, no device shown.
  - as per 5.


## Browser controls

1. Forward / back greyed out when nowhere to go
  - ok 1, 1.1-2
2. Back and forward work when not greyed out
  - ok 1, 1.1-2
3. refresh works after successful navigation
  - ok 1, 1.1-2
4. refresh works after failed navigation (to reattempt the page)
  - ok 1, 1.1-2
5. address bar show current full URL
  - ok 1, 1.1-2
6. on failed navigation, address bar shows URL of location we attempted to navigate to.
  - ok 1, 1.1-2

# 1.1 test cases

1. navigate to a new page, hit add bookmark button, check tick is displayed, check new page is bookmarked, close app, reenter bm page check bookmark still there
    - ok 1.1-1
2. go to bookmarks page. tap on bookmark. should get loaded.
    - ok 1.1-1
3. go to bookmarks page. tap on back. go back to web view but nothing should have changed otherwise
    - ok 1.1-1
4. bm page, swipe left on a bookmark, hit delete, bookmark should disappear, quit application (swipe up from app picker screen), re-enter bm page, bookmark should be gone.
    - ok 1.1-1
5. bm page, click edit to edit, move bookmarks around, without hitting done close app and re-enter and check order is as it last was.
    - ok 1.1-1
6. navigate to a duff URI to get failed navigation screen. shouldn't be able to add a bookmark.
    - FAIL 1.1-1, ok 1.1-2
7. delete all bookmarks. make sure things still work
    - ok 1.1-1
8. ensure all default bookmarks load
    - ok 1.1-2

# 1.2 test cases

1. quit app after failed navigation. Ensure return to last non-failed navigation.
        - ok 1.2.1
2. scroll to bottom of longish page, tap to bring up bars, scroll to bottom again and bars should not disappear.
        - ok 1.2.1
3. tapping top of page scrolls to top, then shows bars
        - ok 1.2.1
4. home bar indicator disappears when bars disappear, reappears when bars reappear
        - ok 1.2.1

# 1.4 manual test cases

1. requestDevice, see popup come up, then navigate to a different page or refresh. popup should go away.

# 1.8 manual test cases

1. Follow "add to home screen" flow and ensure it all works
