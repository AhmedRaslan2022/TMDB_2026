import Foundation

/// Spacing scale (pt). Stick to the scale — no ad-hoc values in views.
public enum AppSpacing {
    /// 4 — tight intra-element gaps.
    public static let xs: CGFloat = 4
    /// 8 — default gap between related elements.
    public static let sm: CGFloat = 8
    /// 12 — gap between loosely related elements.
    public static let md: CGFloat = 12
    /// 16 — standard screen edge padding.
    public static let lg: CGFloat = 16
    /// 24 — section separation.
    public static let xl: CGFloat = 24
    /// 32 — large structural separation.
    public static let xxl: CGFloat = 32
}

/// Corner radius scale (pt).
public enum AppRadius {
    /// 8 — chips, small controls.
    public static let sm: CGFloat = 8
    /// 12 — cards, posters.
    public static let md: CGFloat = 12
    /// 16 — sheets, prominent containers.
    public static let lg: CGFloat = 16
}
