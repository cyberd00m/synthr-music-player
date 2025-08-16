# Synthr Music Player

A modern music player app for iOS that can connect to Navidrome music servers.

## Features

- **Navidrome Server Integration**: Connect to your Navidrome music server
- **Music Playback**: Full music player with queue management
- **Background Audio**: Continue playing music when the app is in the background
- **Lock Screen Controls**: Control playback from the lock screen and Control Center
- **Search**: Search through your music library
- **Offline Downloads**: Download songs, albums, and artists for offline listening
- **Modern UI**: Beautiful, intuitive interface

## Navidrome Server Connection

### Prerequisites

1. A running Navidrome server (https://www.navidrome.org/)
2. Valid username and password for your Navidrome instance
3. The server URL (e.g., `navidrome.example.com` or `192.168.1.100:4533`)

### How to Connect

1. Open the app and navigate to the "Server" tab
2. Enter your Navidrome server details:
   - **Server URL**: Your server's address (e.g., `navidrome.example.com`)
   - **Username**: Your Navidrome username
   - **Password**: Your Navidrome password
3. Tap "Connect to Server"
4. Wait for the connection to establish

### Connection Status

The app will show different connection states:
- **Disconnected**: No server connection
- **Connecting**: Attempting to connect
- **Connected**: Successfully connected to Navidrome
- **Failed**: Connection failed (check credentials and server status)

### Data Synchronization

Once connected, the app will automatically:
- Fetch your music library from Navidrome
- Display albums, artists, and tracks
- Provide streaming URLs for music playback
- Show album artwork (if available)

## Usage

### Data Source

The app connects directly to your Navidrome server to access your music library. No local music files are stored or required.

### Music Playback

- Tap on albums or artists to add them to the queue
- Use the mini-player bar for basic controls
- Navigate to "Now Playing" for full player interface
- **Background Playback**: Music continues playing when you switch to other apps or lock your device
- **Lock Screen Controls**: Use the lock screen or Control Center to play/pause, skip tracks, and adjust volume

### Offline Downloads

- **Long-press** on any song, album, or artist to access download options
- Download individual tracks, entire albums, or all tracks by an artist
- Downloaded content is available for offline listening
- View download progress and manage storage in Settings
- Downloaded tracks are automatically used when available (no internet required)

### Search

- Use the search tab to find specific music
- Search by song title, artist, or album name
- Results update in real-time as you type

## Technical Details

### API Compatibility

The app uses the Subsonic API that Navidrome implements, making it compatible with:
- Navidrome
- Other Subsonic-compatible servers

### Data Models

The app converts Navidrome's data format to internal models:
- `NavidromeTrack` → `Track`
- `NavidromeAlbum` → `Album`
- `NavidromeArtist` → `Artist`

### Error Handling

- Graceful error handling with user-friendly error messages
- User-friendly error messages
- Retry functionality for failed connections

## Troubleshooting

### Connection Issues

1. **Check Server URL**: Ensure the URL is correct and accessible
2. **Verify Credentials**: Double-check username and password
3. **Network Access**: Ensure your device can reach the server
4. **Server Status**: Verify Navidrome is running and accessible

### Common Errors

- **"Authentication failed"**: Check username/password
- **"Connection failed"**: Verify server URL and network connectivity
- **"Invalid response"**: Server may be down or unreachable

## Development

### Architecture

- **NavidromeManager**: Handles server communication
- **UnifiedDataManager**: Manages data sources (local vs. server)
- **SwiftUI Views**: Modern, responsive user interface

### Key Components

- `NavidromeManager.swift`: Server connection and API calls
- `UnifiedDataManager.swift`: Data management and synchronization
- `ServerConnectionView.swift`: Connection interface
- `MainTabView.swift`: Main app navigation

## License

This project is part of the Synthr Music Player application.
