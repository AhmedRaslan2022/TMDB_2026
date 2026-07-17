/// Pushable destinations reachable from the Favorites tab. The app target
/// maps these to views — features never resolve routes themselves.
public enum FavoritesRoute: Hashable, Sendable {
    /// Movie details for a TMDB movie ID.
    case movieDetails(movieID: Int)
}
