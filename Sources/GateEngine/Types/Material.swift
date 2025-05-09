/*
 * Copyright © 2025 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import GameMath
import Shaders

public protocol CustomUniformType {}
extension Int: CustomUniformType {}
extension Bool: CustomUniformType {}
extension Float: CustomUniformType {}
extension Position2: CustomUniformType {}
extension Direction2: CustomUniformType {}
extension Size2: CustomUniformType {}
extension Position3: CustomUniformType {}
extension Direction3: CustomUniformType {}
extension Size3: CustomUniformType {}
extension Matrix3x3: CustomUniformType {}
extension Matrix4x4: CustomUniformType {}
extension Array: CustomUniformType where Element == Matrix4x4 {}

public struct Material {
    private var customUniformValues: [String: any CustomUniformType] = [:]
    internal func sortedCustomUniforms() -> [Dictionary<String, any CustomUniformType>.Element] {
        return customUniformValues.sorted(by: { $0.key.compare($1.key) == .orderedAscending })
    }
    public mutating func setCustomUniformValue(
        _ value: (any CustomUniformType)?,
        forUniform name: String
    ) {
        customUniformValues[name] = value
    }

    public func hasCustomUniformValue(named key: String) -> Bool {
        return customUniformValues.keys.contains(key)
    }
    
    @usableFromInline
    internal var channels: [Channel] = [Channel(color: .defaultDiffuseMapColor)]
    @discardableResult
    public mutating func channel<ResultType>(_ index: UInt8, _ block: (_ channel: inout Channel) -> ResultType) -> ResultType {
        precondition(
            index <= channels.count,
            "index must be an existing channel or the next channel."
        )
        if index == channels.count {
            channels.append(Channel(color: .clear))
        }
        return block(&channels[Int(index)])
    }

    internal init() {

    }

    public init(color: Color) {
        self.channels[0] = Channel(color: color)
    }

    public init(texture: Texture, sampleFilter: Channel.SampleFilter = .linear, tintColor: Color = .white) {
        self.channels[0] = Channel(color: tintColor, texture: texture, sampleFilter: sampleFilter)
    }
    
    public init(texture: Texture) {
        self.channels[0] = Channel(color: .defaultDiffuseMapColor, texture: texture)
    }

    public init(_ config: (_ material: inout Self) -> Void) {
        config(&self)
    }

    public struct Channel: Equatable {
        public var color: Color
        public var texture: Texture? = nil
        public var scale: Size2 = .one
        public var offset: Position2 = .zero
        public var sampleFilter: SampleFilter = .linear
        public enum SampleFilter: Equatable {
            case linear
            case nearest
        }
        
        /**
         Updates the `scale` and `offset` to match where rect should be in UV space
            - parameter rect: The pixel coordinates of the texture 
         */
        @MainActor
        public mutating func setSubRect(_ subRect: Rect) {
            guard let texture else {
                preconditionFailure("Assign a texture to the channel first.")
            }
            precondition(
                texture.sizeIsAvailable, 
                "The texture must have an available size. Provide a sizeHint when creating the texture."
            )
            let xRoundingOffset: Float = (1 / texture.size.width) * 0.5
            let yRoundingOffset: Float = (1 / texture.size.height) * 0.5
            self.scale = Size2(
                subRect.size.width / Float(texture.size.width),
                subRect.size.height / Float(texture.size.height)
            )
            if Game.shared.renderer.api.origin == .bottomLeft {
                self.offset = Position2(
                    (subRect.position.x + xRoundingOffset) / Float(texture.size.width),
                    (subRect.position.y - yRoundingOffset) / Float(texture.size.height)
                )
                if texture.isRenderTarget {
                    self.scale.y *= -1
                }
            } else {
                self.offset = Position2(
                    (subRect.position.x + xRoundingOffset) / Float(texture.size.width),
                    (subRect.position.y + yRoundingOffset) / Float(texture.size.height)
                )
            }
        }
    }

    @MainActor public var isReady: Bool {
        for channel in channels {
            if let t = channel.texture, t.state != .ready {
                return false
            }
        }
        return true
    }

    @MainActor internal var renderTargets: [any _RenderTargetProtocol] {
        var renderTargets: [any _RenderTargetProtocol] = []
        for channel in channels {
            if let texture = channel.texture, let renderTarget = texture.renderTarget {
                #if DEBUG
                assert(renderTargets.contains(where: { $0 === renderTarget }) == false)
                #endif
                renderTargets.append(renderTarget)
            }
        }
        return renderTargets
    }
}
