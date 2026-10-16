import Foundation

/// One preset city of the weather widget.
struct WeatherCity: Identifiable, Hashable {
    let id: String
    let name: LText
    let latitude: Double
    let longitude: Double

    static let all: [WeatherCity] = [
        WeatherCity(id: "moscow", name: LText("Москва", "Moscow"), latitude: 55.7558, longitude: 37.6173),
        WeatherCity(id: "spb", name: LText("Санкт-Петербург", "Saint Petersburg"), latitude: 59.9343, longitude: 30.3351),
        WeatherCity(id: "kyiv", name: LText("Киев", "Kyiv"), latitude: 50.4501, longitude: 30.5234),
        WeatherCity(id: "minsk", name: LText("Минск", "Minsk"), latitude: 53.9006, longitude: 27.5590),
        WeatherCity(id: "ryazan", name: LText("Рязань", "Ryazan"), latitude: 54.6269, longitude: 39.6916),
        WeatherCity(id: "tbilisi", name: LText("Тбилиси", "Tbilisi"), latitude: 41.7151, longitude: 44.8271),
        WeatherCity(id: "yerevan", name: LText("Ереван", "Yerevan"), latitude: 40.1792, longitude: 44.4991),
        WeatherCity(id: "almaty", name: LText("Алматы", "Almaty"), latitude: 43.2220, longitude: 76.8512),
        WeatherCity(id: "dubai", name: LText("Дубай", "Dubai"), latitude: 25.2048, longitude: 55.2708),
        WeatherCity(id: "istanbul", name: LText("Стамбул", "Istanbul"), latitude: 41.0082, longitude: 28.9784),
        WeatherCity(id: "berlin", name: LText("Берлин", "Berlin"), latitude: 52.5200, longitude: 13.4050),
        WeatherCity(id: "london", name: LText("Лондон", "London"), latitude: 51.5072, longitude: -0.1276),
        WeatherCity(id: "paris", name: LText("Париж", "Paris"), latitude: 48.8566, longitude: 2.3522),
        WeatherCity(id: "lisbon", name: LText("Лиссабон", "Lisbon"), latitude: 38.7223, longitude: -9.1393),
        WeatherCity(id: "newyork", name: LText("Нью-Йорк", "New York"), latitude: 40.7128, longitude: -74.0060),
        WeatherCity(id: "losangeles", name: LText("Лос-Анджелес", "Los Angeles"), latitude: 34.0522, longitude: -118.2437),
        WeatherCity(id: "tokyo", name: LText("Токио", "Tokyo"), latitude: 35.6762, longitude: 139.6503),
        WeatherCity(id: "shanghai", name: LText("Пекин", "Beijing"), latitude: 39.9042, longitude: 116.4074),
        WeatherCity(id: "bangkok", name: LText("Бангкок", "Bangkok"), latitude: 13.7563, longitude: 100.5018),
        WeatherCity(id: "sydney", name: LText("Сидней", "Sydney"), latitude: -33.8688, longitude: 151.2093)
    ]

    static func city(_ id: String) -> WeatherCity {
        all.first { $0.id == id } ?? all[0]
    }
}

/// Current weather, cached in the shared container so the sandboxed widget can
/// render it without waiting for the network.
struct WeatherSnapshot: Codable, Equatable {
    var cityID: String
    var temperature: Double
    var apparent: Double
    var windSpeed: Double
    var code: Int
    var updated: Date

    func temperature(unit: String) -> Double {
        unit == "f" ? temperature * 9 / 5 + 32 : temperature
    }

    func apparent(unit: String) -> Double {
        unit == "f" ? apparent * 9 / 5 + 32 : apparent
    }
}

/// Fetches the weather from Open-Meteo (no API key, no account).
enum WeatherService {

    static var directory: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let root = PhotoStore.isSandboxed
            ? home
            : home.appendingPathComponent("Library/Containers/\(PhotoStore.bundleID)/Data", isDirectory: true)
        return root.appendingPathComponent("Library/Application Support/WidgetStudio/data", isDirectory: true)
    }

    static func cacheURL(cityID: String) -> URL {
        directory.appendingPathComponent("weather-\(cityID).json")
    }

    static func cached(cityID: String) -> WeatherSnapshot? {
        guard let data = try? Data(contentsOf: cacheURL(cityID: cityID)) else { return nil }
        return try? JSONDecoder().decode(WeatherSnapshot.self, from: data)
    }

    static func store(_ snapshot: WeatherSnapshot) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: cacheURL(cityID: snapshot.cityID), options: .atomic)
        } catch {
            NSLog("[WidgetStudio] Failed to cache the weather: \(error)")
        }
    }

    /// Downloads the current weather; calls back on the main queue.
    static func fetch(cityID: String, completion: @escaping (WeatherSnapshot?) -> Void) {
        let city = WeatherCity.city(cityID)
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(city.latitude)),
            URLQueryItem(name: "longitude", value: String(city.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,weather_code,wind_speed_10m"),
            URLQueryItem(name: "wind_speed_unit", value: "ms"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        guard let url = components.url else { completion(nil); return }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        URLSession.shared.dataTask(with: request) { data, _, error in
            var snapshot: WeatherSnapshot?
            if let data, error == nil {
                struct Response: Decodable {
                    struct Current: Decodable {
                        let temperature_2m: Double
                        let apparent_temperature: Double
                        let weather_code: Int
                        let wind_speed_10m: Double
                    }
                    let current: Current
                }
                if let decoded = try? JSONDecoder().decode(Response.self, from: data) {
                    snapshot = WeatherSnapshot(cityID: cityID,
                                               temperature: decoded.current.temperature_2m,
                                               apparent: decoded.current.apparent_temperature,
                                               windSpeed: decoded.current.wind_speed_10m,
                                               code: decoded.current.weather_code,
                                               updated: Date())
                    store(snapshot!)
                }
            } else if let error {
                NSLog("[WidgetStudio] Weather request failed: \(error)")
            }
            DispatchQueue.main.async { completion(snapshot) }
        }.resume()
    }

    /// WMO weather code → description and SF Symbol.
    static func description(code: Int) -> (text: LText, symbol: String) {
        switch code {
        case 0: return (LText("Ясно", "Clear"), "sun.max.fill")
        case 1: return (LText("Преимущественно ясно", "Mainly clear"), "sun.max.fill")
        case 2: return (LText("Переменная облачность", "Partly cloudy"), "cloud.sun.fill")
        case 3: return (LText("Облачно", "Overcast"), "cloud.fill")
        case 45, 48: return (LText("Туман", "Fog"), "cloud.fog.fill")
        case 51, 53, 55, 56, 57: return (LText("Морось", "Drizzle"), "cloud.drizzle.fill")
        case 61, 63, 65, 66, 67: return (LText("Дождь", "Rain"), "cloud.rain.fill")
        case 71, 73, 75, 77: return (LText("Снег", "Snow"), "cloud.snow.fill")
        case 80, 81, 82: return (LText("Ливень", "Showers"), "cloud.heavyrain.fill")
        case 85, 86: return (LText("Снегопад", "Snow showers"), "cloud.snow.fill")
        case 95, 96, 99: return (LText("Гроза", "Thunderstorm"), "cloud.bolt.rain.fill")
        default: return (LText("Погода", "Weather"), "cloud.fill")
        }
    }
}
