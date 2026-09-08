import Cocoa
import FlutterMacOS
import app_links

@main
class AppDelegate: FlutterAppDelegate {
  func application(_ sender: NSApplication, openFiles filenames: [String]) {
    for filename in filenames where filename.lowercased().hasSuffix(".trios-modpack") {
      AppLinks.shared.handleLink(link: URL(fileURLWithPath: filename).absoluteString)
    }
    sender.reply(toOpenOrPrint: .success)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
     return false
  }
}
