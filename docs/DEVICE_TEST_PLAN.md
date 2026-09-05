# Physical-device acceptance plan

The following tests are still required and are not recorded as passed.

1. **First launch:** Confirm a useful welcome screen before any folder grant. Enter and exit demo mode; real and demo data must never mix.
2. **Source:** Choose a local folder, grant access, and load `pcdrdata.sqlite3`. Test a subfolder path. Cancellation, an invalid path, an unreadable file, and an unexpected schema must produce clear messages.
3. **Persistence:** Fully close and reopen the app, then restart the tablet/iPhone. Verify the stored grant and settings. On Android, install a genuinely signed update over the existing version.
4. **Data changes:** Modify a device in the inspection app, save the inspection, and return to the viewer. Confirm that the new state loads. With an active WAL, the viewer must reject the read instead of presenting stale data as current.
5. **Customers:** Test databases containing one named customer, multiple named customers, and no named customers. The same device ID owned by different customers must not be merged.
6. **Filters:** Select multiple locations, select location-search results, change the search, retain the selection, and select an empty location. The dashboard and device list must use the same location scope.
7. **Reference date:** Select a manual date, refresh, and restart. Return to automatic mode and test a date change across a daylight-saving transition.
8. **Forecast:** Test all five horizons, partial current months, year boundaries, empty months, horizontal scrolling, and selecting a bar. Overdue entries must not be counted again in the forecast.
9. **Device list:** Combine text and result filters, test every ascending/descending sort, keep invalid dates at the end, and preserve leading ID zeroes. Test all five page sizes and the final incomplete page.
10. **Display:** Test phones and tablets, portrait/landscape, the on-screen keyboard, larger text, and TalkBack/VoiceOver. The main page must scroll completely. Errors and long customer names must not be clipped.
11. **Source protection:** Compare the source hash before and after reading. The app must not modify or delete any inspection-app file or original WAL/journal file.
12. **Release:** Test offline mode and verify the app name/icon, bundle ID, signature, and build number. Validate the Android AAB or iOS archive with the publisher's store tooling.
