/*
 * Copyright © 2025 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import WinSDK

public struct D3DColor: Equatable {
    public typealias RawValue = Array<Float>
    @usableFromInline
    internal var rawValue: RawValue
    
    @inlinable
    public var red: Float {
        get {
            return rawValue[0]
        }
        set {
            rawValue[0] = newValue
        }
    }

    @inlinable
    public var green: Float {
        get {
            return rawValue[1]
        }
        set {
            rawValue[1] = newValue
        }
    }

    @inlinable
    public var blue: Float {
        get {
            return rawValue[2]
        }
        set {
            rawValue[2] = newValue
        }
    }

    @inlinable
    public var alpha: Float {
        get {
            return rawValue[3]
        }
        set {
            rawValue[3] = newValue
        }
    }

    @inlinable
    public subscript(_ index: Int) -> Float {
        get {
            return rawValue[index]
        }
        set {
            rawValue[index] = newValue
        }
    }

    @inlinable
    internal var tuple: (Float, Float, Float, Float) {
        return (rawValue[0], rawValue[1], rawValue[2], rawValue[3])
    }

    @inlinable
    internal init(_ tuple: (Float, Float, Float, Float)) {
        self.rawValue = [tuple.0, tuple.1, tuple.2, tuple.3]
    }

    @inlinable
    public init(red: Float, green: Float, blue: Float, alpha: Float) {
        self.rawValue = [red, green, blue, alpha]
    }

    @inlinable
    internal init(_ rawValue: RawValue) {
        self.rawValue = rawValue
    }

    @inlinable public static var black: D3DColor {D3DColor(red: 0, green: 0, blue: 0, alpha: 1)}
    @inlinable public static var white: D3DColor {D3DColor(red: 1, green: 1, blue: 1, alpha: 1)}
    @inlinable public static var clear: D3DColor {D3DColor(red: 1, green: 1, blue: 1, alpha: 0)}

    @inlinable public static var red: D3DColor {D3DColor(red: 1, green: 0, blue: 0, alpha: 1)}
    @inlinable public static var green: D3DColor {D3DColor(red: 0, green: 1, blue: 0, alpha: 1)}
    @inlinable public static var blue: D3DColor {D3DColor(red: 0, green: 0, blue: 1, alpha: 1)}
}
