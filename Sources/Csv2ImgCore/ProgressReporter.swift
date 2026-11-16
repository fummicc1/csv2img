import Foundation

/// Forwards progress only when it moves by a whole percent, so a large table does not flood observers with one update per row.
final class ProgressReporter {
    private let total: Int
    private let progress: (Double) -> Void
    private var completed = 0
    private var lastReportedPercent = 0

    init(total: Int, progress: @escaping (Double) -> Void) {
        self.total = total
        self.progress = progress
    }

    func advance() {
        guard total > 0 else { return }
        completed += 1
        let percent = completed * 100 / total
        guard percent > lastReportedPercent || completed == total else { return }
        lastReportedPercent = percent
        progress(Double(completed) / Double(total))
    }
}
