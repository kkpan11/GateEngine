/*
 * Copyright © 2025 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

/// Represents a location in 3D space
#if GameMathUseSIMD
public struct Position3: Vector3, SIMD, Sendable {
    public typealias Scalar = Float
    public typealias MaskStorage = SIMD3<Float>.MaskStorage
    public typealias ArrayLiteralElement = Scalar
    
    @usableFromInline
    var _storage = Float.SIMD4Storage()

    @inlinable
    public init(arrayLiteral elements: Self.ArrayLiteralElement...) {
        for index in elements.indices {
            _storage[index] = elements[index]
        }
    }
    
    @inlinable
    public var x: Scalar {
        get {
            return _storage[0]
        }
        set {
            _storage[0] = newValue
        }
    }
    @inlinable
    public var y: Scalar {
        get {
            return _storage[1]
        }
        set {
            _storage[1] = newValue
        }
    }
    @inlinable
    public var z: Scalar {
        get {
            return _storage[2]
        }
        set {
            _storage[2] = newValue
        }
    }
    
    @inlinable
    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}
#else
public struct Position3: Vector3, Sendable {
    public var x: Float
    public var y: Float
    public var z: Float
    
    @inlinable
    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}
#endif

public extension Position3 {
    @inlinable
    init(_ x: Float, _ y: Float, _ z: Float) {
        self.init(x: x, y: y, z: z)
    }
}

public extension Position3 {
    @inlinable
    var xy: Position2 {
        get {
            return Position2(x, y)
        }
        set {
            self.x = newValue.x
            self.y = newValue.y
        }
    }
    
    @inlinable
    var xz: Position2 {
        get {
            return Position2(x, z)
        }
        set {
            self.x = newValue.x
            self.z = newValue.y
        }
    }
}

public extension Position3 {
    /** The distance between `from` and `self`
    - parameter from: A value representing the source position.
     */
    @inlinable
    func distance(from: Self) -> Float {
        let difference = self - from
        let distance = difference.dot(difference)
        return distance.squareRoot()
    }
    
    @inlinable
    func squaredDistance(from: Self) -> Float {
        let difference = self - from
        return pow(difference.x, 2) + pow(difference.y, 2) + pow(difference.z, 2)
    }

    /** Returns true when the distance from `self` and  `rhs` is less then `threshold`
    - parameter rhs: A value representing the destination position.
    - parameter threshold: The maximum distance that is considered "near".
     */
    @inlinable
    func isNear(_ rhs: Self, threshold: Float) -> Bool {
        return self.distance(from: rhs) < threshold
    }
}

public extension Position3 {
    /** Creates a position a specified distance from self in a particular direction
    - parameter distance: The units away from `self` to create the new position.
    - parameter direction: The angle away from self to create the new position.
     */
    @inlinable
    func moved(_ distance: Float, toward direction: Direction3) -> Self {
        return self + (direction.normalized * distance)
    }

    /** Moves `self` by a specified distance from in a particular direction
    - parameter distance: The units away to move.
    - parameter direction: The angle to move.
     */
    @inlinable
    mutating func move(_ distance: Float, toward direction: Direction3) {
        self = moved(distance, toward: direction)
    }
}

public extension Position3 {
    /** Creates a position by rotating self around an anchor point.
    - parameter origin: The anchor to rotate around.
    - parameter rotation: The direction and angle to rotate.
     */
    @inlinable
    func rotated(around anchor: Self = .zero, by rotation: Quaternion) -> Self {
        let d = self.distance(from: anchor)
        return anchor.moved(d, toward: rotation.forward)
    }

    /** Rotates `self` around an anchor position.
     - parameter origin: The anchor to rotate around.
     - parameter rotation: The direction and angle to rotate.
     */
    @inlinable
    mutating func rotate(around anchor: Self = .zero, by rotation: Quaternion) {
        self = rotated(around: anchor, by: rotation)
    }
}

#if !GameMathUseSIMD
public extension Position3 {
    static let zero = Self(0)
}
#endif

extension Position3: Hashable {}
extension Position3: Codable {
    @inlinable
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode([x, y, z])
    }

    @inlinable
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let values = try container.decode(Array<Float>.self)
        self.init(values[0], values[1], values[2])
    }
}

