/*
 * Copyright © 2025 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

#if canImport(WinSDK) && canImport(XAudio2)
import WinSDK
import XAudio2

internal class XAListenerReference: SpatialAudioListenerBackend {
    init() {}

    func setPosition(_ position: Position3) {
        fatalError()
    }

    func setOrientation(forward: Direction3, up: Direction3) {
        fatalError()
    }
}
#endif
