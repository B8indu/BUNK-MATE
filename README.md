Bunk-Mate: Mobile App
Are you tired of missing out on activities or simply wanting to take a day off from college? The Bunk Mate app is here to help! It allows you to effortlessly track your attendance while keeping you informed about the remaining classes needed to meet your attendance requirements.

Installation
To get started, simply download the latest release of the app from this link and install it on your device!

Building from Source
To build the APK from source code:

flutter build apk --release --no-tree-shake-icons
Note: The --no-tree-shake-icons flag is required due to a Flutter build issue with icon tree shaking in the current version.

How to Use Bunk Mate
Maximize your experience with the Attendance Tracker app by following these steps:

1. Create an Account
Sign up within the app to create your personal account.

2. Log In
Use your newly created credentials to log into your account.

3. Add Your Timetable
You’ll be prompted to enter your timetable details. Provide:

Timetable name
Start and end dates
Required attendance percentage
You can also choose to select a timetable shared by other users!

4. Manage Your Courses
After adding your timetable, navigate to the courses page via the navigation bar to view and manage your courses and their schedules.

5. Update Attendance Status
Easily update your attendance on the status page:

Single-click to mark a day as bunked
Double-click to mark as skipped
Deep-press to mark as present
By default, days are marked as present, so you only need to update your status when you bunk or skip a class.

For Developers
Setup Instructions
To install the Attendance Tracker app locally, follow these steps:

Clone the repository to your local machine.
Run flutter run to install and launch the app.
