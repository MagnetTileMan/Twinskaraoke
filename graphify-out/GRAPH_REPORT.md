# Graph Report - .  (2026-05-08)

## Corpus Check
- Large corpus: 102 files · ~556,682 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder, or use --no-semantic to run AST-only.

## Summary
- 680 nodes · 1048 edges · 50 communities (33 shown, 17 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 62 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Audio Playback Engine|Audio Playback Engine]]
- [[_COMMUNITY_Data Models & Protocols|Data Models & Protocols]]
- [[_COMMUNITY_UI Components|UI Components]]
- [[_COMMUNITY_Saved Playlists Store|Saved Playlists Store]]
- [[_COMMUNITY_Account & Login UI|Account & Login UI]]
- [[_COMMUNITY_Unit Tests|Unit Tests]]
- [[_COMMUNITY_Marquee Text & Artists|Marquee Text & Artists]]
- [[_COMMUNITY_Watch Audio Manager|Watch Audio Manager]]
- [[_COMMUNITY_Library Views|Library Views]]
- [[_COMMUNITY_Auth Manager|Auth Manager]]
- [[_COMMUNITY_Home Browse UI|Home Browse UI]]
- [[_COMMUNITY_Art Gallery Detail|Art Gallery Detail]]
- [[_COMMUNITY_Radio Now Playing Model|Radio Now Playing Model]]
- [[_COMMUNITY_About & Credits|About & Credits]]
- [[_COMMUNITY_View Models|View Models]]
- [[_COMMUNITY_Content View & Popup|Content View & Popup]]
- [[_COMMUNITY_App Theme System|App Theme System]]
- [[_COMMUNITY_Video Gallery|Video Gallery]]
- [[_COMMUNITY_App Entry Points|App Entry Points]]
- [[_COMMUNITY_Download Manager|Download Manager]]
- [[_COMMUNITY_Home View Model|Home View Model]]
- [[_COMMUNITY_Search UI|Search UI]]
- [[_COMMUNITY_Search View Model|Search View Model]]
- [[_COMMUNITY_Favorites Manager|Favorites Manager]]
- [[_COMMUNITY_Radio UI|Radio UI]]
- [[_COMMUNITY_Lyrics View|Lyrics View]]
- [[_COMMUNITY_Song Coding Keys|Song Coding Keys]]
- [[_COMMUNITY_AirPlay & Volume|AirPlay & Volume]]
- [[_COMMUNITY_Playlist Detail View|Playlist Detail View]]
- [[_COMMUNITY_Playlists View Model|Playlists View Model]]
- [[_COMMUNITY_Auth Errors|Auth Errors]]
- [[_COMMUNITY_Recently Added Tracker|Recently Added Tracker]]
- [[_COMMUNITY_Playlist Detail Decoding|Playlist Detail Decoding]]
- [[_COMMUNITY_Radio Controller|Radio Controller]]
- [[_COMMUNITY_Karaoke Audio Processor|Karaoke Audio Processor]]
- [[_COMMUNITY_Recently Played Store|Recently Played Store]]
- [[_COMMUNITY_Song Row Component|Song Row Component]]
- [[_COMMUNITY_Art Gallery Save State|Art Gallery Save State]]
- [[_COMMUNITY_Search Coding Keys|Search Coding Keys]]
- [[_COMMUNITY_Playlist Coding Keys|Playlist Coding Keys]]
- [[_COMMUNITY_Genres View Model|Genres View Model]]
- [[_COMMUNITY_Settings View|Settings View]]
- [[_COMMUNITY_Playlist Detail VM|Playlist Detail VM]]
- [[_COMMUNITY_Video Gallery VM|Video Gallery VM]]
- [[_COMMUNITY_Random Songs View|Random Songs View]]
- [[_COMMUNITY_Watch Player View|Watch Player View]]
- [[_COMMUNITY_Guest Identity|Guest Identity]]
- [[_COMMUNITY_Storage Host|Storage Host]]
- [[_COMMUNITY_Media Playback Coordinator|Media Playback Coordinator]]
- [[_COMMUNITY_Watch App Theme|Watch App Theme]]

## God Nodes (most connected - your core abstractions)
1. `url` - 35 edges
2. `AudioManager` - 21 edges
3. `CodingKeys` - 18 edges
4. `AuthManager` - 18 edges
5. `play()` - 14 edges
6. `FullScreenPlayerView` - 12 edges
7. `updateNowPlayingInfo()` - 12 edges
8. `CodingKeys` - 11 edges
9. `DownloadManager` - 11 edges
10. `WatchSongModelTests` - 11 edges

## Surprising Connections (you probably didn't know these)
- `fetchRandomTrending()` --calls--> `url`  [INFERRED]
  Twinskaraoke/Services/AudioPlayerManager.swift → Twinskaraoke/Features/Account/AboutView.swift
- `reportPlayCount()` --calls--> `url`  [INFERRED]
  Twinskaraoke/Services/AudioPlayerManager.swift → Twinskaraoke/Features/Account/AboutView.swift

## Communities (50 total, 17 thin omitted)

### Community 0 - "Audio Playback Engine"
Cohesion: 0.08
Nodes (41): activateAudioSession(), applyArtwork(), AudioDownloadSession, beginCrossfade(), cancelAutoMix(), configureAudioSessionCategory(), fetchRandomTrending(), handleBackgroundTransition() (+33 more)

### Community 1 - "Data Models & Protocols"
Cohesion: 0.07
Nodes (24): Codable, Equatable, Identifiable, GalleryArt, GalleryArtist, Artist, GalleryVideo, LyricLine (+16 more)

### Community 2 - "UI Components"
Cohesion: 0.06
Nodes (13): ButtonStyle, EqualizerBars, FavoritesArtworkTile, PlaylistArtwork, ImageCacheConfig, LoadingImage, LoadingIndicator, PlayerAmbientBackground (+5 more)

### Community 3 - "Saved Playlists Store"
Cohesion: 0.07
Nodes (6): SavedPlaylistsStore, TwinskaraokeUITests, TwinskaraokeUITestsLaunchTests, Twinskaraoke_Watch_AppUITests, Twinskaraoke_Watch_AppUITestsLaunchTests, XCTestCase

### Community 4 - "Account & Login UI"
Cohesion: 0.07
Nodes (23): AccountView, Color, DiscordIcon, DiscordShape, LoginField, password, username, LoginSheet (+15 more)

### Community 5 - "Unit Tests"
Cohesion: 0.07
Nodes (7): FavoritesManagerTests, GuestIdentityTests, makePlaylist(), RadioNowPlayingDecodingTests, RecentlyPlayedStoreTests, SongModelTests, TimeSpanParserTests

### Community 6 - "Marquee Text & Artists"
Cohesion: 0.07
Nodes (14): MarqueeText, TextSizeKey, BrowseScrollOffsetKey, ArtistAvatar, ArtistDetailView, ArtistDetailViewModel, ArtistRow, ArtistScrollOffsetKey (+6 more)

### Community 7 - "Watch Audio Manager"
Cohesion: 0.18
Nodes (4): AudioManager, PlaybackMode, listLoop, singleLoop

### Community 8 - "Library Views"
Cohesion: 0.13
Nodes (16): VerticalKaraokeLevel, LibraryPlaceholderView, LibraryRow, LibraryView, PlaylistGridCell, PlaylistListRow, PlaylistsGridScreen, PlaylistsSkeletonView (+8 more)

### Community 9 - "Auth Manager"
Cohesion: 0.2
Nodes (4): ASWebAuthenticationPresentationContextProviding, http, AuthManager, DiscordProfile

### Community 10 - "Home Browse UI"
Cohesion: 0.12
Nodes (13): BrowseSongCollectionView, HomePlaceholderSection, HomePlaceholderTile, HomePlaceholderTileView, HomeSkeletonView, HomeSongCard, HomeSongSection, HomeView (+5 more)

### Community 11 - "Art Gallery Detail"
Cohesion: 0.14
Nodes (11): ArtDetailView, ArtGalleryView, ArtistArtsView, ArtistCircleCard, ArtistListRow, ArtThumbnail, FeaturedArtCard, ImageSaver (+3 more)

### Community 12 - "Radio Now Playing Model"
Cohesion: 0.12
Nodes (16): CodingKeys, art, artist, customFields, description, id, listeners, listenUrl (+8 more)

### Community 13 - "About & Credits"
Cohesion: 0.15
Nodes (10): AboutLinkRow, AboutView, AcknowledgementsView, ArtistCreditRow, Credit, CreditsView, iOSAppDevelopmentView, LinkifiedText (+2 more)

### Community 14 - "View Models"
Cohesion: 0.13
Nodes (6): ArtGalleryViewModel, PlaylistDetailViewModel, RandomSongsViewModel, SongsViewModel, SimilarVideosViewModel, ObservableObject

### Community 15 - "Content View & Popup"
Cohesion: 0.14
Nodes (8): ContentView, PopupBarTrailingItems, PopupContent, PopupHostView, PopupModifier, GlassCircle, QueueModeBackground, ViewModifier

### Community 16 - "App Theme System"
Cohesion: 0.19
Nodes (9): AM, AMSectionHeader, Color, Font, Radius, Shadow, ShadowStyle, Spacing (+1 more)

### Community 17 - "Video Gallery"
Cohesion: 0.17
Nodes (9): FeaturedVideoCard, FullscreenAVPlayer, SimilarVideoRow, VideoGalleryCell, VideoGalleryView, VideoPlayerScreen, VideosResponse, VideoThumbnail (+1 more)

### Community 18 - "App Entry Points"
Cohesion: 0.24
Nodes (7): App, Twinskaraoke_Watch_AppApp, TwinskaraokeApp, allColors(), dominantColors(), init(), UIColor

### Community 21 - "Search UI"
Cohesion: 0.22
Nodes (6): BrowseCategoriesView, CategoryTile, GenreDetailView, SearchResultRow, SearchRowSkeleton, SearchView

### Community 22 - "Search View Model"
Cohesion: 0.27
Nodes (3): GenreDetail, SearchViewModel, TopChartViewModel

### Community 24 - "Radio UI"
Cohesion: 0.25
Nodes (7): RadioHistoryRow, RadioShowTile, RadioShowTileView, RadioSkeletonView, RadioStationTile, RadioStationTileView, RadioView

### Community 25 - "Lyrics View"
Cohesion: 0.22
Nodes (5): InstrumentalDots, IntroDots, LyricLineRow, LyricsBouncingDots, LyricsView

### Community 26 - "Song Coding Keys"
Cohesion: 0.22
Nodes (9): CodingKeys, absolutePath, cloudflareID, coverArt, coverArtists, duration, id, originalArtists (+1 more)

### Community 27 - "AirPlay & Volume"
Cohesion: 0.22
Nodes (3): AirPlayRoutePickerView, SystemVolumeBridge, UIViewRepresentable

### Community 28 - "Playlist Detail View"
Cohesion: 0.25
Nodes (4): FavoriteSongEnvelope, PlaylistMoreMenu, PlaylistRow, PlaylistSongsResponse

### Community 30 - "Auth Errors"
Cohesion: 0.25
Nodes (7): Error, AuthError, cancelled, invalidCallback, parse, Endpoint, K

### Community 32 - "Playlist Detail Decoding"
Cohesion: 0.29
Nodes (7): CodingKeys, items, song, songData, songDTO, songListDTOs, songs

### Community 34 - "Karaoke Audio Processor"
Cohesion: 0.29
Nodes (5): KaraokeAudioProcessor, KaraokeMode, bassEnhance, vocalRemoval, TapFormat

### Community 36 - "Song Row Component"
Cohesion: 0.33
Nodes (5): SongRow, SongRowSize, compact, regular, SongRowSkeleton

### Community 37 - "Art Gallery Save State"
Cohesion: 0.4
Nodes (5): SaveStatus, failed, idle, saving, success

### Community 38 - "Search Coding Keys"
Cohesion: 0.4
Nodes (5): CodingKeys, count, id, name, songCount

### Community 39 - "Playlist Coding Keys"
Cohesion: 0.4
Nodes (5): CodingKey, CodingKeys, song, songData, songDTO

## Knowledge Gaps
- **66 isolated node(s):** `card`, `station`, `song`, `songData`, `songDTO` (+61 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **17 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `url` connect `Playlists View Model` to `Audio Playback Engine`, `Data Models & Protocols`, `UI Components`, `Radio Controller`, `Account & Login UI`, `Marquee Text & Artists`, `Genres View Model`, `Auth Manager`, `Playlist Detail VM`, `Video Gallery VM`, `About & Credits`, `View Models`, `Home View Model`, `Search View Model`, `Favorites Manager`?**
  _High betweenness centrality (0.167) - this node is a cross-community bridge._
- **Why does `SavedPlaylistsStore` connect `Saved Playlists Store` to `View Models`?**
  _High betweenness centrality (0.094) - this node is a cross-community bridge._
- **Why does `AuthManager` connect `Auth Manager` to `Art Gallery Detail`, `Auth Errors`, `View Models`?**
  _High betweenness centrality (0.064) - this node is a cross-community bridge._
- **Are the 33 inferred relationships involving `url` (e.g. with `.loadLatestSingle()` and `.fetchData()`) actually correct?**
  _`url` has 33 INFERRED edges - model-reasoned connections that need verification._
- **What connects `card`, `station`, `song` to the rest of the system?**
  _66 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Audio Playback Engine` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Should `Data Models & Protocols` be split into smaller, more focused modules?**
  _Cohesion score 0.07 - nodes in this community are weakly interconnected._