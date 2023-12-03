import Foundation

public enum PdfSize: String, Codable, Equatable, CaseIterable, Sendable {
    case a0
    case a1
    case a2
    case a3
    case a4
    case a5

    case b0
    case b1
    case b2
    case b3
    case b4
    case b5

    public enum Orientation: Codable, Equatable, CaseIterable, Sendable {
        case portrait
        case landscape
    }

    public func size(orientation: Orientation) -> CGSize {
        let landscape = switch self {
        case .a0:
            CGSize(width: 3370, height: 2384)
        case .a1:
            CGSize(width: 2384, height: 1684)
        case .a2:
            CGSize(width: 1684, height: 1191)
        case .a3:
            CGSize(width: 1191, height: 842)
        case .a4:
            CGSize(width: 842, height: 595)
        case .a5:
            CGSize(width: 595, height: 420)
        case .b0:
            CGSize(width: 4127, height: 2920)
        case .b1:
            CGSize(width: 2920, height: 2064)
        case .b2:
            CGSize(width: 2064, height: 1460)
        case .b3:
            CGSize(width: 1460, height: 1032)
        case .b4:
            CGSize(width: 1032, height: 729)
        case .b5:
            CGSize(width: 729, height: 516)
        }
        if orientation == .landscape {
            return landscape
        }
        return .init(width: landscape.height, height: landscape.width)
    }
}
