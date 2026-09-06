import Foundation
import CoreGraphics

enum TrackResult {
    case newCounted
    case alreadyCounted
    case lost
}

@MainActor
final class BanknoteTracker {
    private struct TrackedObject {
        let id: UUID
        var lastBoundingBox: NormalizedRect
        var lastSeen: Date
        var confidence: Double
        var counted: Bool
        var denomination: Denomination?
    }

    private var tracked: [UUID: TrackedObject] = [:]
    private let maxDistance: CGFloat = 0.25
    private let maxUnseenInterval: TimeInterval = 1.5

    func reset() {
        tracked.removeAll()
    }

    @discardableResult
    func track(_ banknote: RecognizedBanknote, now: Date = Date()) -> TrackResult {
        purgeStale(now: now)
        if let existing = findClosest(to: banknote.boundingBox, denomination: banknote.denomination) {
            tracked[existing.id]?.lastBoundingBox = banknote.boundingBox
            tracked[existing.id]?.lastSeen = now
            tracked[existing.id]?.confidence = banknote.confidence
            tracked[existing.id]?.denomination = banknote.denomination
            if tracked[existing.id]?.counted == true {
                return .alreadyCounted
            } else {
                tracked[existing.id]?.counted = true
                return .newCounted
            }
        }
        let id = UUID()
        tracked[id] = TrackedObject(
            id: id,
            lastBoundingBox: banknote.boundingBox,
            lastSeen: now,
            confidence: banknote.confidence,
            counted: true,
            denomination: banknote.denomination
        )
        return .newCounted
    }

    private func purgeStale(now: Date) {
        tracked = tracked.filter { now.timeIntervalSince($0.value.lastSeen) < maxUnseenInterval }
    }

    private func findClosest(to box: NormalizedRect, denomination: Denomination) -> TrackedObject? {
        var best: TrackedObject?
        var bestDist = maxDistance
        for obj in tracked.values {
            if let den = obj.denomination, den != denomination { continue }
            let dist = iouDistance(box, obj.lastBoundingBox)
            if dist < bestDist {
                bestDist = dist
                best = obj
            }
        }
        return best
    }

    private func iouDistance(_ a: NormalizedRect, _ b: NormalizedRect) -> CGFloat {
        let cx1 = a.x + a.width / 2
        let cy1 = a.y + a.height / 2
        let cx2 = b.x + b.width / 2
        let cy2 = b.y + b.height / 2
        return hypot(cx1 - cx2, cy1 - cy2)
    }

    var activeCount: Int { tracked.count }
}
