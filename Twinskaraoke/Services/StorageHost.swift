import Foundation

/// Picks the audio storage host based on the user's region. Mainland China
/// users hit `storage.neurokaraoke.com.cn` (CDN node inside the GFW); everyone
/// else uses the global `storage.neurokaraoke.com`. Image and API hosts are
/// unaffected — only large audio downloads need the regional CDN.
enum StorageHost {
  static var base: String {
    isChinaRegion ? "https://storage.neurokaraoke.com.cn" : "https://storage.neurokaraoke.com"
  }
  private static var isChinaRegion: Bool {
    if let override = UserDefaults.standard.string(forKey: "nk.storageRegion") {
      return override == "cn"
    }
    let region: String
    if #available(iOS 16.0, macOS 13.0, *) {
      region = Locale.current.region?.identifier ?? Locale.current.identifier
    } else {
      region = Locale.current.regionCode ?? Locale.current.identifier
    }
    return region.uppercased() == "CN"
  }
}
