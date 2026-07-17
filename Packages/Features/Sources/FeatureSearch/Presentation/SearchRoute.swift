/// Pushable destinations reachable from the Search tab. The app target maps
/// these to views — features never resolve routes themselves.
public enum SearchRoute: Hashable, Sendable {
    /// Movie details for a TMDB movie ID.
    case movieDetails(movieID: Int)
}
