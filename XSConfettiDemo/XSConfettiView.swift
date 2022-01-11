//
//  XSConfettiView.swift
//  XSConfettiDemo
//
//  Created by 邵晓飞 on 2022/1/11.
//

import UIKit

// MARK: - ConfettiShape

enum ConfettiShape {
    case rectangle
    case circle
}

// MARK: - ConfettiPosition

enum ConfettiPosition {
    case foreground
    case background
}

// MARK: - ConfettiType

class ConfettiType {
    // MARK: Lifecycle

    init(color: UIColor, shape: ConfettiShape, position: ConfettiPosition) {
        self.color = color
        self.shape = shape
        self.position = position
    }

    // MARK: Internal

    let color: UIColor
    let shape: ConfettiShape
    let position: ConfettiPosition
    
    lazy var name = UUID().uuidString
    
    lazy var image: UIImage = {
        let imageRect: CGRect = {
            switch shape {
            case .rectangle:
                return CGRect(x: 0, y: 0, width: 20, height: 13)
            case .circle:
                return CGRect(x: 0, y: 0, width: 10, height: 10)
            }
        }()
        UIGraphicsBeginImageContext(imageRect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        
        switch shape {
        case .rectangle:
            context.fill(imageRect)
        case .circle:
            context.fillEllipse(in: imageRect)
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }()
}

// MARK: - XSConfettiView

class XSConfettiView: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public func startAnimating() {
        for layer in [createForegroundConfettiLayer(), createBackgroundConfettiLayer()] {
            self.layer.addSublayer(layer)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                print("Remove layer: \(layer)")
                layer.removeFromSuperlayer()
            }
        }
    }

    // MARK: Internal

    lazy var confettiTypes: [ConfettiType] = {
        let confettiColors = [
            (r: 149, g: 58, b: 255), (r: 255, g: 195, b: 41), (r: 255, g: 101, b: 26),
            (r: 123, g: 92, b: 255), (r: 76, g: 126, b: 255), (r: 71, g: 192, b: 255),
            (r: 255, g: 47, b: 39), (r: 255, g: 91, b: 134), (r: 233, g: 122, b: 208),
        ].map { UIColor(red: $0.r / 255.0, green: $0.g / 255.0, blue: $0.b / 255.0, alpha: 1) }
        
        return [ConfettiPosition.foreground, ConfettiPosition.background].flatMap { position in
            [ConfettiShape.rectangle, ConfettiShape.circle].flatMap { shape in
                confettiColors.map { color in
                    ConfettiType(color: color, shape: shape, position: position)
                }
            }
        }
    }()

    func createForegroundConfettiLayer() -> CAEmitterLayer {
        let emitterLayer = createConfettiLayer()
        
        addBehaviors(to: emitterLayer)
        addAnimations(to: emitterLayer)
        return emitterLayer
    }
    
    func createBackgroundConfettiLayer() -> CAEmitterLayer {
        let emitterLayer = createConfettiLayer()
        
        for emitterCell in emitterLayer.emitterCells ?? [] {
            emitterCell.scale = 0.5
        }

        emitterLayer.opacity = 0.5
        emitterLayer.speed = 0.95
        
        addBehaviors(to: emitterLayer)
        addAnimations(to: emitterLayer)
        return emitterLayer
    }

    func createConfettiCells() -> [CAEmitterCell] {
        return confettiTypes.map { type in
            let cell = CAEmitterCell()
            cell.name = type.name
            
            cell.beginTime = 0.1
            cell.birthRate = 100
            cell.contents = type.image.cgImage
            cell.emissionRange = CGFloat(Double.pi)
            cell.lifetime = 10
            cell.spin = 4
            cell.spinRange = 8
            cell.velocityRange = 0
            cell.yAcceleration = 0
            
            cell.setValue("plane", forKey: "particleType")
            cell.setValue(Double.pi, forKey: "orientationRange")
            cell.setValue(Double.pi / 2, forKey: "orientationLongitude")
            cell.setValue(Double.pi / 2, forKey: "orientationLatitude")
            
            return cell
        }
    }
    
    func createConfettiLayer() -> CAEmitterLayer {
        let emitterLayer = CAEmitterLayer()
        
        emitterLayer.birthRate = 0
        emitterLayer.emitterCells = createConfettiCells()
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.minY - bounds.size.width / 5)
        emitterLayer.emitterSize = CGSize(width: bounds.size.width / 5, height: bounds.size.width / 5)
        emitterLayer.emitterShape = .sphere
        emitterLayer.frame = bounds
        
        emitterLayer.beginTime = CACurrentMediaTime()
        return emitterLayer
    }
    
    func createBehavior(type: String) -> NSObject {
        let behaviorClass = NSClassFromString("CAEmitterBehavior") as! NSObject.Type
        let behaviorWithType = behaviorClass.method(for: NSSelectorFromString("behaviorWithType:"))!
        let castedBehaviorWithType = unsafeBitCast(behaviorWithType, to: (@convention(c) (Any?, Selector, Any?) -> NSObject).self)
        return castedBehaviorWithType(behaviorClass, NSSelectorFromString("behaviorWithType"), type)
    }
    
    func horizontalWaveBehavior() -> Any {
        let behavior = createBehavior(type: "wave")
        behavior.setValue([100, 0, 0], forKeyPath: "force")
        behavior.setValue(0.5, forKeyPath: "frequency")
        return behavior
    }
    
    func verticalWaveBehavior() -> Any {
        let behavior = createBehavior(type: "wave")
        behavior.setValue([0, 500, 0], forKeyPath: "force")
        behavior.setValue(3, forKeyPath: "frequency")
        return behavior
    }
    
    func attractorBehavior(for emitterLayer: CAEmitterLayer) -> Any {
        let behavior = createBehavior(type: "attractor")
        behavior.setValue("attractor", forKeyPath: "name")
        
        behavior.setValue(-290, forKey: "falloff")
        behavior.setValue(300, forKey: "radius")
        behavior.setValue(10, forKey: "stiffness")
        
        behavior.setValue(CGPoint(x: emitterLayer.emitterPosition.x,
                                  y: emitterLayer.emitterPosition.y),
                          forKey: "position")
        behavior.setValue(-70, forKey: "zPosition")
        
        return behavior
    }
    
    func addBehaviors(to layer: CAEmitterLayer) {
        layer.setValue([
            horizontalWaveBehavior(),
            verticalWaveBehavior(),
            attractorBehavior(for: layer),
        ], forKey: "emitterBehaviors")
    }
    
    func addAttractorAnimation(to layer: CALayer) {
        let animation = CAKeyframeAnimation()
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.duration = 3
        animation.keyTimes = [0, 0.4]
        animation.values = [80, 5]
        
        layer.add(animation, forKey: "emitterBehaviors.attractor.stiffness")
    }
    
    func addBirthrateAnimation(to layer: CALayer) {
        let animation = CABasicAnimation()
        animation.duration = 1
        animation.fromValue = 1
        animation.toValue = 0

        layer.add(animation, forKey: "birthRate")
    }
    
    func addAnimations(to layer: CAEmitterLayer) {
        addAttractorAnimation(to: layer)
        addBirthrateAnimation(to: layer)
        addGravityAnimation(to: layer)
    }
    
    func dragBehavior() -> Any {
        let behavior = createBehavior(type: "drag")
        behavior.setValue("drag", forKey: "name")
        behavior.setValue(2, forKey: "drag")

        return behavior
    }
    
    func addDragAnimation(to layer: CALayer) {
        let animation = CABasicAnimation()
        animation.duration = 0.35
        animation.fromValue = 0
        animation.toValue = 2

        layer.add(animation, forKey: "emitterBehaviors.drag.drag")
    }
    
    func addGravityAnimation(to layer: CALayer) {
        let animation = CAKeyframeAnimation()
        animation.duration = 6
        animation.keyTimes = [0.05, 0.1, 0.5, 1]
        animation.values = [0, 100, 2000, 4000]

        for image in confettiTypes {
            layer.add(animation, forKey: "emitterCells.\(image.name).yAcceleration")
        }
    }
}
