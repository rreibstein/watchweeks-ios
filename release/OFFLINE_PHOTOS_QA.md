# Offline release photos

Previously viewed release photos can reuse an on-device HTTP cache when the
photo host permits caching. There is no bulk download. The app uses feed-approved
photos only; if an editorial update removes a photo or changes its URL, the new
guide will no longer request the old URL. A 4xx response evicts that URL. If
the app cannot refresh offline, it can only show the last saved edition.

Check in an actual device build:

1. Open a known brand-credited photo in a city card and its full-screen view.
2. Enable Airplane Mode, force-quit, and relaunch. Check the loaded photo and an
   unviewed release. The first can use cache; the unviewed item shows a placeholder.
3. Test the flow with a host response that allows cache, another that sends
   no-store, a replaced URL, and a withdrawn image returning 404.
4. Browse a large carousel and check that scrolling remains responsive and iOS
   can purge the bounded cache under storage pressure.

Don't promote until device QA and the release image host's cache rules are known.
