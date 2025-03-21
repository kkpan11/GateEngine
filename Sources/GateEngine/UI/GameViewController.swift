/*
 * Copyright © 2025 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import Foundation

public struct GameViewSnapshot: Sendable {
    let frame: Rect
    let bounds: Rect
    let backgroundColor: Color?
    
    static var empty: GameViewSnapshot {
        return .init(frame: .zero, bounds: .zero, backgroundColor: nil)
    }
}
internal extension GameView {
    func snapshot() -> GameViewSnapshot {
        return GameViewSnapshot(
            frame: self.frame, 
            bounds: self.bounds, 
            backgroundColor: self.backgroundColor
        )
    }
}

public final class GameView: View {
    @usableFromInline
    var _drawables: [any Drawable] = []
    
    override final func shouldDraw() -> Bool {
        if let gameViewController, gameViewController.shouldSkipRendering {
            return false
        }
        return super.shouldDraw()
    }
    
    public override func canBeHit() -> Bool {
        return true
    }
    
    private var pendingBackgroundColor: Color? = nil
    public override var backgroundColor: Color? {
        get {
            if let pendingBackgroundColor {
                return pendingBackgroundColor
            }
            switch mode {
            case .screen:
                return window?.clearColor
            case .offScreen:
                return _renderTarget?.clearColor
            }
        }
        set {
            switch mode {
            case .screen:
                if let window {
                    window.clearColor = newValue ?? .clear
                }else{
                    self.pendingBackgroundColor = newValue
                }
            case .offScreen:
                if let _renderTarget {
                    _renderTarget.clearColor = newValue ?? .clear
                }else{
                    self.pendingBackgroundColor = newValue
                }
            }
            super.backgroundColor = newValue
        }
    }
    
    public override func touchesBegan(_ touches: Set<Touch>) {
        self.gameViewController?.touchesBegan(touches)
    }
    public override func touchesMoved(_ touches: Set<Touch>) {
        self.gameViewController?.touchesMoved(touches)
    }
    public override func touchesEnded(_ touches: Set<Touch>) {
        self.gameViewController?.touchesEnded(touches)
    }
    public override func touchesCanceled(_ touches: Set<Touch>) {
        self.gameViewController?.touchesCanceled(touches)
    }
    
    public override func surfaceTouchesBegan(_ touches: Set<SurfaceTouch>, mouse: Mouse) {
        self.gameViewController?.surfaceTouchesBegan(touches, mouse: mouse)
    }
    public override func surfaceTouchesMoved(_ touches: Set<SurfaceTouch>, mouse: Mouse) {
        self.gameViewController?.surfaceTouchesMoved(touches, mouse: mouse)
    }
    public override func surfaceTouchesEnded(_ touches: Set<SurfaceTouch>, mouse: Mouse) {
        self.gameViewController?.surfaceTouchesEnded(touches, mouse: mouse)
    }
    public override func surfaceTouchesCanceled(_ touches: Set<SurfaceTouch>, mouse: Mouse) {
        self.gameViewController?.surfaceTouchesCanceled(touches, mouse: mouse)
    }
    
    public override func cursorEntered(_ cursor: Mouse) {
        self.gameViewController?.cursorEntered(cursor)
    }
    public override func cursorMoved(_ cursor: Mouse) {
        self.gameViewController?.cursorMoved(cursor)
    }
    public override func cursorExited(_ cursor: Mouse) {
        self.gameViewController?.cursorExited(cursor)
    }
    
    public override func cursorButtonDown(button: MouseButton, mouse: Mouse) {
        self.gameViewController?.cursorButtonDown(button: button, mouse: mouse)
    }
    public override func cursorButtonUp(button: MouseButton, mouse: Mouse) {
        self.gameViewController?.cursorButtonUp(button: button, mouse: mouse)
    }
    
    public override func scrolled(_ delta: Position2, isPlatformGeneratedMomentum isMomentum: Bool) {
        self.gameViewController?.scrolled(delta, isPlatformGeneratedMomentum: isMomentum)
    }
    
    enum Mode {
        case screen
        case offScreen
    }
    var mode: Mode = .screen
    
    private var deltaTimeAccumulator: Double = 0
    private var previousTime: Double = 0
    
    override final func draw(_ rect: Rect, into canvas: inout UICanvas) {
        var frame = frame
        if mode == .offScreen {
            super.draw(rect, into: &canvas)
            frame = rect
            self._renderTarget?.size = frame.size
        }
        
        if let gameViewController {
            guard let _deltaTime = Game.getNextDeltaTime(
                accumulator: &deltaTimeAccumulator, 
                previous: &previousTime
            ) else {
                return
            }
            
            let deltaTime = Float(_deltaTime)
            gameViewController.render(context: gameViewController.context, into: self, withTimePassed: deltaTime)
            gameViewController.context.updateRendering(into: self, deltaTime: deltaTime)
            
            if mode == .offScreen {
                canvas.insert(
                    DrawCommand(
                        resource: .geometry(.rectOriginTopLeft),
                        transforms: [
                            Transform3(
                                position: Position3(
                                    x: frame.x,
                                    y: frame.y,
                                    z: 0
                                ),
                                scale: Size3(
                                    frame.width,
                                    frame.height,
                                    1
                                )
                            )
                        ], 
                        material: Material(texture: renderTargetTexture, tintColor: Self.colorOffscreenRendered ? .yellow : .white),
                        vsh: .standard,
                        fsh: Self.colorOffscreenRendered ? .textureSampleTintColor : .textureSample,
                        flags: .userInterface
                    )
                )
            }
        }
    }
    
    @usableFromInline
    internal var _renderTarget: RenderTarget? = nil
    @usableFromInline
    internal var renderTarget: any RenderTargetProtocol {
        return _renderTarget ?? self.window!
    }
    internal var renderTargetTexture: Texture {
        return _renderTarget?.texture ?? self.window!.texture
    }
    
    public override func didChangeSuperview() {
        if self.superView == nil {
            _renderTarget = nil
            return
        }
        if _viewController?.isRootViewController == true {
            self.mode = .screen
            _renderTarget = nil
            if let pendingBackgroundColor {
                if window != nil {
                    self.backgroundColor = pendingBackgroundColor
                }
            }
        }else{
            self.mode = .offScreen
            Game.shared.attributes.insert(.renderingIsPermitted)
            _renderTarget = RenderTarget(backgroundColor: self.backgroundColor ?? .clear)
            Game.shared.attributes.remove(.renderingIsPermitted)
        }
        self.pendingBackgroundColor = nil
    }
}
extension GameView {
    @_transparent
    public var gameViewController: GameViewController? {
        return _viewController as? GameViewController
    }
    @_transparent
    public func insert(_ canvas: Canvas) {
        if canvas.hasContent {
            self.renderTarget.insert(canvas)
        }
    }
    
    @_transparent
    public func insert(_ scene: Scene) {
        if scene.hasContent {
            self.renderTarget.insert(scene)
        }
    }
}

open class GameViewController: ViewController {
    @usableFromInline
    internal let context = ECSContext()

    @inlinable @inline(__always)
    public var gameView: GameView {
        return unsafeDowncast(self.view, to: GameView.self)
    } 
    
    final public override func loadView() {
        self.view = GameView()
        Task {
            await self.setup(context: self.context)
        }
    }
    
    internal var shouldSkipRendering: Bool = false
    
    internal override func _update(withTimePassed deltaTime: Float) async {
        await super._update(withTimePassed: deltaTime)
        self.shouldSkipRendering = (await context.shouldRenderAfterUpdate(withTimePassed: deltaTime) == false)
    }
    
    @MainActor
    open func setup(context: ECSContext) async {
        
    }
    
    open func render(context: ECSContext, into view: GameView, withTimePassed deltaTime: Float) {
        
    }
    
    open func touchesBegan(_ touches: Set<Touch>) {
        
    }
    open func touchesMoved(_ touches: Set<Touch>) {
        
    }
    open func touchesEnded(_ touches: Set<Touch>) {
        
    }
    open func touchesCanceled(_ touches: Set<Touch>) {
        
    }
    
    open func surfaceTouchesBegan(_ touches: Set<SurfaceTouch>, mouse: Mouse) {
        
    }
    open func surfaceTouchesMoved(_ touches: Set<SurfaceTouch>, mouse: Mouse) {
        
    }
    open func surfaceTouchesEnded(_ touches: Set<SurfaceTouch>, mouse: Mouse) {
        
    }
    open func surfaceTouchesCanceled(_ touches: Set<SurfaceTouch>, mouse: Mouse) {
        
    }
    
    open func cursorEntered(_ cursor: Mouse) {
        
    }
    open func cursorMoved(_ cursor: Mouse) {
        
    }
    open func cursorExited(_ cursor: Mouse) {
        
    }
    
    open func cursorButtonDown(button: MouseButton, mouse: Mouse) {
        
    }
    open func cursorButtonUp(button: MouseButton, mouse: Mouse) {
        
    }
    
    open func scrolled(_ delta: Position2, isPlatformGeneratedMomentum isMomentum: Bool) {
        
    }
}

extension GameView {
    /**
     Move a 3D point into this view's coordinate space.
     
     - returns: A 2D position representing the location of a 3D object in this view's bounds.
     */
    public func convert(_ position: Position3, from camera: Camera) -> Position2 {
        let size = self.bounds.size
        let matricies = camera.matricies(withViewportSize: size * self.interfaceScale)
        var position = position * matricies.viewProjection()
        position.x /= position.z
        position.y /= position.z
        
        position.x = size.width * (position.x + 1) / 2
        position.y = size.height * (1.0 - ((position.y + 1) / 2))
        
//        position.x /= self.interfaceScale
//        position.y /= self.interfaceScale
        
        return Position2(position.x, position.y)
    }
    
    /**
     Move a 2D point into a 3D space.
     
     - returns: A Ray3D representing the location of a 2D point located on the view. The ray's direction is toward the 3D space accounting for perspective distortion.
     */
    public func convert(_ position: Position2, to camera: Camera) -> Ray3D {
        switch camera.fieldOfView {
        case .perspective(let fieldOfView):
            let size = self.bounds.size
            let halfSize = size / 2
            let aspectRatio = size.aspectRatio
            
            let inverseView = camera.matricies(withViewportSize: size * interfaceScale).view.inverse
            let halfFOV = tan(fieldOfView.rawValueAsRadians * 0.5)
            let near = camera.clippingPlane.near
            let far = camera.clippingPlane.far
            
            let dx = halfFOV * (position.x / halfSize.width - 1.0) * aspectRatio
            let dy = halfFOV * (1.0 - position.y / halfSize.height)
            
            let p1 = Position3(dx * near, dy * near, near) * inverseView
            let p2 = Position3(dx * far, dy * far, far) * inverseView
            
            return Ray3D(from: p1, toward: p2)
        case .orthographic(_):
            fatalError("Not implemented")
        }
    }
}

extension GameViewController {
    @_transparent
    public var entities: ContiguousArray<Entity> {
        return context.sortedEntities()
    }
    @_transparent
    public func insertEntity(_ entity: Entity) {
        context.insertEntity(entity)
    }
    @_transparent
    public func removeEntity(_ entity: Entity) {
        context.removeEntity(entity)
    }
    @_transparent @discardableResult
    public func removeEntity(named name: String) -> Entity? {
        return context.removeEntity(named: name)
    }
    @_transparent @discardableResult
    public func removeEntity(where block: (Entity) -> (Bool)) -> Entity? {
        return context.removeEntity(where: block)
    }
    @_transparent
    public func entity(named name: String) -> Entity? {
        return context.entity(named: name)
    }
    @_transparent
    public func entity(withID id: ObjectIdentifier) -> Entity? {
        return context.entity(withID: id)
    }
    @_transparent
    public func firstEntity(withComponent component: any Component.Type) -> Entity? {
        return context.firstEntity(withComponent: component)
    }
    @_transparent
    public func system<T: System>(ofType systemType: T.Type) -> T {
        return context.system(ofType: systemType)
    }
    @_transparent
    public func hasSystem<T: System>(ofType systemType: T.Type) -> Bool {
        return context.hasSystem(ofType: systemType)
    }
    @_transparent
    public func system<T: RenderingSystem>(ofType systemType: T.Type) -> T {
        return context.system(ofType: systemType)
    }
    @_transparent
    public func insertSystem(_ newSystem: System) {
        context.insertSystem(newSystem)
    }
    @_transparent
    public func insertSystem(_ newSystem: RenderingSystem) {
        context.insertSystem(newSystem)
    }
    @_transparent @discardableResult
    public func insertSystem<T: System>(_ system: T.Type) -> T {
        return context.insertSystem(system)
    }
    @_transparent @discardableResult
    public func insertSystem<T: RenderingSystem>(_ system: T.Type) -> T {
        return context.insertSystem(system)
    }
    @_transparent
    public func removeSystem(_ system: System) {
        context.removeSystem(system)
    }
    @_transparent
    public func removeSystem(_ system: RenderingSystem) {
        context.removeSystem(system)
    }
    @_transparent @discardableResult
    public func removeSystem<T: System>(_ system: T.Type) -> T? {
        return context.removeSystem(system)
    }
    @_transparent @discardableResult
    public func removeSystem<T: RenderingSystem>(_ system: T.Type) -> T? {
        return context.removeSystem(system)
    }
}

@MainActor extension GameViewController {
    @_transparent
    func system<T: PlatformSystem>(ofType systemType: T.Type) -> T {
        return context.system(ofType: systemType)
    }
    @_transparent @discardableResult
    func insertSystem<T: PlatformSystem>(_ system: T.Type) -> T {
        return context.insertSystem(system)
    }
    @_transparent
    func insertSystem(_ newSystem: PlatformSystem) {
        context.insertSystem(newSystem)
    }
    @_transparent
    func removeSystem(_ system: PlatformSystem) {
        context.removeSystem(system)
    }
    @_transparent @discardableResult
    func removeSystem<T: PlatformSystem>(_ system: T.Type) -> T? {
        return context.removeSystem(system)
    }
}
