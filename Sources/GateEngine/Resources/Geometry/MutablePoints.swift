/*
 * Copyright © 2025 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

public class MutableLines: Lines {
    public var rawLines: RawLines? = nil {
        didSet {
            load()
        }
    }

    public init(rawLines: RawLines? = nil) {
        self.rawLines = rawLines
        super.init(optionalRawLines: rawLines)
    }

    private func load() {
        Task(priority: .high) {
            guard let cache = Game.shared.resourceManager.geometryCache(for: cacheKey) else {
                return
            }
            if let rawLines, rawLines.indices.isEmpty == false {
                cache.geometryBackend = await Game.shared.resourceManager.geometryBackend(
                    from: rawLines
                )
                Task { @MainActor in
                    cache.state = .ready
                }
            }else{
                cache.geometryBackend = nil
                cache.state = .pending
            }
        }
    }
}
