/// Pushable destinations reachable from the Profile tab. The app target maps
/// these to views — features never resolve routes themselves.
public enum ProfileRoute: Hashable, Sendable {
    /// App settings (theme, language, cache — Sprint 5).
    case settings
}
