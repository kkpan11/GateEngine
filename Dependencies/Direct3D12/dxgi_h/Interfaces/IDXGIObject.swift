/*
 * Copyright © 2025 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import WinSDK

public class DGIObject: IUnknown {
    @inlinable
    override class var interfaceID: WinSDK.IID {RawValue.interfaceID}
}

extension DGIObject {
    @usableFromInline
    typealias RawValue = WinSDK.IDXGIObject
}
extension DGIObject.RawValue {
    @inlinable
    static var interfaceID: WinSDK.IID {WinSDK.IID_IDXGIObject}
}

//MARK: - Original Style API
#if !Direct3D12ExcludeOriginalStyleAPI

@available(*, unavailable, renamed: "DGIObject")
public typealias IDXGIObject = DGIObject

#endif
