# Google Play Data Safety Form – Guidance for BlastOff

Use this guide to fill out the **Data Safety** section in Google Play Console.

---

## Section 1: Data Types

Check the following boxes in **"Data collected and shared"**:

### ✅ Check "App Info and Performance"

- **Device or other identifiers** — Device unique ID (`OS.get_unique_id()`) is sent to SilentWolf as the player identifier
    - Collected: Yes
    - Shared: Yes (with SilentWolf)
    - Used for: App functionality (leaderboard player identification)

### ✅ Check "Personal Info"

- **Name (Display name)** — The optional user-chosen display name (max 8 chars) is sent to SilentWolf
    - Collected: Yes
    - Shared: Yes (with SilentWolf)
    - Used for: App functionality (leaderboard display)

### ✅ Check "Other"

- **Score / Game progress data** — High scores are sent to SilentWolf
    - Collected: Yes
    - Shared: Yes (with SilentWolf)
    - Used for: App functionality (leaderboard ranking)
- **App or game interactions** — Stars, play time, powerups used are tracked locally only (not shared)
    - Collected: Yes
    - Shared: No
    - Used for: App functionality (personal statistics)

### ❌ Data NOT collected (leave unchecked)

| Category             | Reason        |
| -------------------- | ------------- |
| Location             | Not collected |
| Financial info       | Not collected |
| Health & fitness     | Not collected |
| Messages             | Not collected |
| Photos & videos      | Not collected |
| Audio files          | Not collected |
| Files & docs         | Not collected |
| Calendar             | Not collected |
| Contacts             | Not collected |
| Web browsing history | Not collected |

---

## Section 2: How Data Is Handled

### Data Collection

- **All data is collected automatically** via the SilentWolf SDK when the app detects a high score or when you view the statistics screen
- Display name is optional — defaults to device ID if not set

### Data Sharing

- **Only SilentWolf** (api.silentwolf.com, by Brass Harpooner) receives data
- No data is shared with any other third parties
- No analytics, crash reporting, or advertising SDKs are present

### Data Security

- **All data in transit**: Encrypted (HTTPS)
- **No data at rest** on external servers is encrypted (standard database storage)

### Data Deletion

- Users can change their display name, which triggers deletion of old scores from the server
- Users can request full data deletion by contacting the developer
- Local data is deleted when the app is uninstalled

---

## Section 3: Policy & Compliance

### Privacy Policy URL

After publishing `PRIVACY.md`, host it at a publicly accessible URL (e.g., your website or a GitHub Pages link), and enter that URL in the Play Console.

If you don't have a website, you can:

- Host it on GitHub Pages
- Use a privacy policy hosting service
- Upload it to a personal site

### Does your app's data handling practices align with the declared policy?

Yes — the `PRIVACY.md` file accurately reflects the data practices described here.

### Does your app collect data from users outside the user's country of residence?

No — data collection is the same for all users regardless of location.

---

## Summary Table for Quick Reference

| Data Type                 | Collected? | Shared? | Shared With | Encrypted?         | User Can Delete?       |
| ------------------------- | ---------- | ------- | ----------- | ------------------ | ---------------------- |
| Device ID                 | Yes        | Yes     | SilentWolf  | HTTPS (in transit) | On request             |
| Display name              | Optional   | Yes     | SilentWolf  | HTTPS (in transit) | Change name            |
| High scores               | Yes        | Yes     | SilentWolf  | HTTPS (in transit) | Change name or request |
| Game stats (stars, time)  | Yes        | No      | —           | Local only         | Uninstall app          |
| Preferences (audio, skin) | Yes        | No      | —           | Local only         | Uninstall app          |
