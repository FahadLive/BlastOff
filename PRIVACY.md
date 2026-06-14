# Privacy Policy

**Last updated:** June 14, 2026

## Introduction

BlastOff ("we", "our", "the app") is a casual infinite runner game developed and published by **drapelive**. This privacy policy explains how we collect, use, and share your data when you use our app.

## Data We Collect

### Data Transferred to Third-Party Services

The app uses **SilentWolf** (by Brass Harpooner) as a backend service for leaderboard functionality. When you achieve a high score or view the statistics screen, the following data is sent to SilentWolf's servers at `api.silentwolf.com`:

| Data                                            | Purpose                                           | Required?             |
| ----------------------------------------------- | ------------------------------------------------- | --------------------- |
| Device unique identifier (`OS.get_unique_id()`) | Player identification and leaderboard association | Yes                   |
| High score value                                | Leaderboard ranking                               | Yes                   |
| Display name (user-chosen, max 8 characters)    | Leaderboard display                               | Optional              |
| Godot Engine version & plugin version           | Technical compatibility                           | Yes (in HTTP headers) |

### Data Stored Locally on Device

The following data is saved locally on your device using a `ConfigFile` at `user://blastoff_data.cfg` and is **never** transmitted to any server:

| Data                                              | Section               |
| ------------------------------------------------- | --------------------- |
| High score                                        | Gameplay              |
| Total stars collected, spent, and current balance | Gameplay / Statistics |
| Display name                                      | Settings              |
| Audio volume preferences (per bus)                | Settings              |
| Control type preference (guide/touch)             | Settings              |
| Background selection preference                   | Settings              |
| Current rocket skin and color                     | Gameplay              |
| Difficulty level                                  | Gameplay              |
| Total play time                                   | Statistics            |
| Powerups used count                               | Statistics            |

SilentWolf also stores a session file at `user://swsession.save` containing session lookup and validator tokens (if authentication features are used).

## How We Use Your Data

- **Leaderboard functionality**: Your device ID, display name, and scores are used to display rankings and your position on the leaderboard.
- **Game experience**: Locally stored data is used to persist your settings, progress, and preferences across sessions.
- **Statistics**: Play time, stars earned/spent, and powerups used are tracked locally for your personal view.

## Third-Party Services

**SilentWolf** (Brass Harpooner) — https://silentwolf.com

SilentWolf provides leaderboard and player data storage services. Their servers receive your device ID, scores, display name, and technical metadata. SilentWolf's privacy policy and terms of service are available at their website.

No other third-party services (analytics, crash reporting, advertising, or tracking SDKs) are used in this app.

## Data Security

All network communication with SilentWolf's API is encrypted using HTTPS. The app includes an API key in request headers for server authentication. No additional analytics, tracking, or advertising SDKs are present.

## Data Retention

- **Server-side**: Your scores and display name remain on SilentWolf's servers until you change your display name (which triggers deletion of old scores) or upon request.
- **Local data**: Data stored on your device persists until you uninstall the app or clear app data.

## Your Rights and Choices

- **Change display name**: You can change your display name at any time in the app. Changing your display name will delete your previous scores from the leaderboard.
- **Opt out of leaderboard**: Leaderboard functionality is disabled if the API key is not available.
- **Data deletion**: To request deletion of your data from SilentWolf's servers, please contact us.

## Children's Privacy

This app does not knowingly collect personal information from children. The only identifier used is a device-generated unique ID, not a real name or email address (unless you choose to register with SilentWolf's authentication forms).

## Changes to This Policy

We may update this privacy policy from time to time. Changes will be reflected on the app's Store Listing page.

## Contact

For questions about this privacy policy or data deletion requests, please contact the developer through the Google Play Store listing.
