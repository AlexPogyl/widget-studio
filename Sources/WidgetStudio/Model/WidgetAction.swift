import Foundation

/// The "open an app when the widget is clicked" action.
///
/// A WidgetKit widget cannot launch another application by itself, so the widget
/// opens a `widgetstudio://launch?path=…` URL; macOS hands that URL to Widget
/// Studio, which then opens the chosen application. Only the URL plumbing lives
/// here — it is shared by the app and by the widget extension.
enum WidgetAction {
    static let scheme = "widgetstudio"
    static let host = "launch"
    static let pathKey = "path"

    static func launchURL(applicationPath: String) -> URL? {
        guard !applicationPath.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [URLQueryItem(name: pathKey, value: applicationPath)]
        return components.url
    }

    static func applicationPath(from url: URL) -> String? {
        guard url.scheme == scheme, url.host == host,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        return components.queryItems?.first { $0.name == pathKey }?.value
    }
}
