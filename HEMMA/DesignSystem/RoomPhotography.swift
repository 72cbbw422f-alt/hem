import Foundation

enum RoomPhotography {
    // Public Unsplash image URLs. The app loads these photos on demand and keeps
    // the interface usable with its gradient fallback when offline.
    static let livingRoom = URL(string: "https://images.unsplash.com/photo-1768332572728-2fff6ecbd6b6?auto=format&fit=crop&w=1400&q=85")!
    static let kitchen = URL(string: "https://images.unsplash.com/photo-1621328778483-77056460b842?auto=format&fit=crop&w=1100&q=85")!
    static let bedroom = URL(string: "https://images.unsplash.com/photo-1777383504729-bd8364d28de8?auto=format&fit=crop&w=1100&q=85")!
    static let hallway = URL(string: "https://images.unsplash.com/photo-1778172884832-78a5de5ec3d2?auto=format&fit=crop&w=1100&q=85")!

    static func image(for roomName: String) -> URL {
        let name = roomName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if name.contains("kok") || name.contains("kitchen") { return kitchen }
        if name.contains("sov") || name.contains("bed") { return bedroom }
        if name.contains("hall") || name.contains("entr") { return hallway }
        return livingRoom
    }
}
