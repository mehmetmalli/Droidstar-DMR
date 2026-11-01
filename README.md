# DroidStar DMR App for iOS

> **Fork notice:** This repository is a fork of
> [rohithzmoi/Droidstar-DMR](https://github.com/rohithzmoi/Droidstar-DMR), the iOS-focused
> modified DroidStar app maintained by **Rohith Namboothiri (VU3LVO)**. This fork is
> maintained by **Mehmet Malli (TA3JS)**. Credit for all prior work belongs to Rohith and,
> before him, to **Doug McLain (AD8DP)**, author of the
> [original DroidStar](https://github.com/nostar/DroidStar).

## 📢 Important Announcement (from the upstream maintainer, VU3LVO)

**Please note:** I will no longer be maintaining the Android version, at least for the near future. Due to the complexity of maintaining both iOS and Android versions simultaneously, I've made the decision to focus exclusively on iOS development. 

**Special Contributor** A huge thanks and shout-out to VU2TBR (T. Bala) for his valuable feedback and idea contributions. His inputs played a major role in helping me design and refine these features.

---

This project is a fork of [VU3LVO's modified Droidstar app](https://github.com/rohithzmoi/Droidstar-DMR), which is itself a modified version of the [original Droidstar App](https://github.com/nostar/DroidStar) by Doug McLain. The modifications introduce new features and enhancements to improve user experience and functionality.

This project is built with:

- **Qt 6.11.3** (iOS)
- **Xcode 27.0** with an iOS 17.0 deployment target
- **Swift 5.0** (Live Activities / Dynamic Island extension)

## What's New in the Latest Update

I'm thrilled to announce a major update with significant improvements and highly requested features:

- **Complete Major Design Overhaul**: Fresh UI, smoother navigation, and a much cleaner overall experience that modernizes the entire app.

- **Dynamic Island Support for iOS**: One of the most requested features! You can now monitor activity and status right from the Dynamic Island, providing at-a-glance information without opening the app.

- **iPhone Notification Center Display**: Real-time TX/RX status updates are now visible in the notification center, keeping you informed even when multitasking.

- **Lock Screen TX/RX Display**: Monitor transmission and reception activity directly from your iPhone's lock screen for ultimate convenience.

- **Control QSO Log Length**: Adjust how many entries you want to keep directly from the QSO page without digging into settings. Customize your log management with ease.

- **Toggle Self-TX Logging**: A small but powerful quality-of-life improvement for those who prefer cleaner logs. Turn self-transmission logging on or off based on your preference.

And this is just the beginning. More updates are coming soon, including a few surprises I think you'll really enjoy!

## Previous Features

I am excited to share several features and improvements that have been previously released:

- **Automatic Operator Information Display**: The app now automatically fetches the operator's first name (referred to as the "Handle") based on their DMR ID and displays it below the "Call Sign." The operator's "Country" is also displayed next to the "Handle."

- **New QSO Tab**: A new QSO Tab has been introduced, which logs the 250 most recent calls (Last Heard). This tab displays the Call Sign, DMR ID, TGID, Handle, Country, and logged time in local time. The logs are now persistently stored, remaining intact even after restarting the app.

- **TX Button and Net Status Integration**: The QSO Tab now includes a TX button with integrated Net Status, providing real-time feedback on the connection status (Host Connected or Not Connected).

- **Enhanced Export Options**: You can now export QSO logs in CSV or ADIF formats. Additionally, you can selectively choose specific log entries for inclusion in the exported file. You can also share the exported file directly from the app via WhatsApp, email, or any other app on your device.

- **"Last Heard" on Home Page**: The app now features "Last Heard" as two rows on the home page, providing quick access to recent transmissions. The AMBES notification has been moved to the Settings for better organization.

- **Quick Access Buttons**: Added a button in the QSO entries that opens a menu to visit the station's QRZ, BM, and APRS pages directly from the app.

- **Background Functionality for Android & iOS Users**: The app now supports background operation for Android & iOS users, allowing it to continue running while switching between applications. This feature is particularly useful for tasks like checking a station's QRZ page while maintaining uninterrupted RX. iOS users will now be able to connect to Bluetooth devices as well.

- **Simplified User Interface**: The user interface has been simplified by replacing the text "Main" with a "Home" icon for a more intuitive experience.

- **Recent TG-ID Dropdown**: The dropdown records all the recently dialed Talk Group ids and lets you choose from the list. You no longer have to memorize the TG ID.

## Acknowledgments

This project builds on the original work by [Doug McLain](https://github.com/nostar/) and the iOS-focused modifications by [Rohith Namboothiri (VU3LVO)](https://github.com/rohithzmoi). Many thanks to Doug for his excellent foundation and contributions to the digital radio community, and to Rohith for the work this fork is based on.

## License

This project, including modifications, is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.

---

**73 TA3JS - Mehmet** (fork maintainer)