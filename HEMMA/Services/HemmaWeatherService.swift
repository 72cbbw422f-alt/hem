import Foundation

struct HemmaWeatherSnapshot {
    let temperature: Double
    let windSpeed: Double
    let symbol: String
    let description: String
    let updatedAt: Date
}

@MainActor
final class HemmaWeatherService: ObservableObject {
    @Published private(set) var snapshot: HemmaWeatherSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private struct ForecastResponse: Decodable {
        let timeSeries: [TimeEntry]
    }

    private struct TimeEntry: Decodable {
        let validTime: Date
        let parameters: [Parameter]
    }

    private struct Parameter: Decodable {
        let name: String
        let values: [Double]
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        // Hudiksvall city coordinates. This is a town forecast, not a claim
        // about the exact conditions at the user's home address.
        let urlString = "https://opendata-download-metfcst.smhi.se/api/category/pmp3g/version/2/geotype/point/lon/17.105/lat/61.728/data.json"
        guard let url = URL(string: urlString) else {
            errorMessage = "Väderprognosen är inte tillgänglig."
            return
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            request.setValue("Hemma iOS app", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let forecast = try decoder.decode(ForecastResponse.self, from: data)
            guard let entry = forecast.timeSeries.first else { throw URLError(.cannotParseResponse) }
            func value(_ name: String) -> Double? {
                entry.parameters.first(where: { $0.name == name })?.values.first
            }
            guard let temperature = value("t"), let wind = value("ws"), let code = value("Wsymb2") else {
                throw URLError(.cannotParseResponse)
            }
            let condition = Self.condition(for: Int(code))
            snapshot = HemmaWeatherSnapshot(
                temperature: temperature,
                windSpeed: wind,
                symbol: condition.symbol,
                description: condition.description,
                updatedAt: entry.validTime
            )
            errorMessage = nil
        } catch {
            errorMessage = "Väderprognosen kunde inte hämtas just nu."
        }
    }

    private static func condition(for code: Int) -> (symbol: String, description: String) {
        switch code {
        case 1: return ("sun.max.fill", "Klart")
        case 2: return ("sun.max", "Nästan klart")
        case 3: return ("cloud.sun.fill", "Växlande molnighet")
        case 4: return ("cloud.sun", "Halvklart")
        case 5: return ("cloud.fill", "Molnigt")
        case 6: return ("smoke.fill", "Mulet")
        case 7: return ("cloud.fog.fill", "Dimma")
        case 8: return ("cloud.drizzle.fill", "Lätta regnskurar")
        case 9: return ("cloud.rain.fill", "Regnskurar")
        case 10: return ("cloud.heavyrain.fill", "Kraftiga regnskurar")
        case 11, 18: return ("cloud.bolt.rain.fill", "Åska")
        case 12: return ("cloud.sleet.fill", "Lätta snöblandade skurar")
        case 13: return ("cloud.sleet.fill", "Snöblandade skurar")
        case 14: return ("cloud.sleet.fill", "Kraftiga snöblandade skurar")
        case 15: return ("cloud.snow.fill", "Lätta snöbyar")
        case 16: return ("cloud.snow.fill", "Snöbyar")
        case 17: return ("cloud.snow.fill", "Kraftiga snöbyar")
        default: return ("cloud.fill", "Väderprognos")
        }
    }
}
