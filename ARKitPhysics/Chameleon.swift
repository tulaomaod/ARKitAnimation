//
//  Chameleon.swift
//  ARKitPhysics
//
//  Created by mac126 on 2018/4/8.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit
import SceneKit

class Chameleon: SCNScene {

    open let contentRootNode = SCNNode()
    // Animations
    private var idleAnimation: SCNAnimation?
    private var turnLeftAnimation: SCNAnimation?
    private var turnRightAnimation: SCNAnimation?
    
    private var chameleonIsTurning: Bool = false
    
    // 状态变量
    private var modelLoaded: Bool = false
    
    override init() {
        super.init()
        
        loadModel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 加载模型
    private func loadModel() {
        guard let virtualObjectScene = SCNScene(named: "chameleon", inDirectory: "art.scnassets") else { return  }
        
        // 隐藏
        // hide()
        
        // 设置节点
        let wrapperNode = SCNNode()
        for node in virtualObjectScene.rootNode.childNodes {
            wrapperNode.addChildNode(node)
        }
        
        self.rootNode.addChildNode(contentRootNode)
        contentRootNode.addChildNode(wrapperNode)
        
        // 加载动画
        preloadAnimations()
        
        modelLoaded = true
    }
    
    // MARK: - public api
    func hide() {
        contentRootNode.isHidden = true
    }
    
    func show() {
        contentRootNode.isHidden = false
    }
    
    func isVisible() -> Bool {
        return !contentRootNode.isHidden
    }
    
    func setTransform(_ transform: simd_float4x4) {
        contentRootNode.simdTransform = transform
    }
    
    // MARK: - 转向和初始动画
    private func preloadAnimations() {
        
        idleAnimation = SCNAnimation.fromFile(named: "anim_idle", inDirectory: "art.scnassets")
        idleAnimation?.repeatCount = -1
        
        turnLeftAnimation = SCNAnimation.fromFile(named: "anim_turnleft", inDirectory: "art.scnassets")
        turnLeftAnimation?.repeatCount = 1
        turnLeftAnimation?.blendInDuration = 0.3
        turnLeftAnimation?.blendOutDuration = 0.3

        
        turnRightAnimation = SCNAnimation.fromFile(named: "anim_turnright", inDirectory: "art.scnassets")
        turnRightAnimation?.repeatCount = 1
        turnRightAnimation?.blendInDuration = 0.3
        turnRightAnimation?.blendOutDuration = 0.3
        
        // 开始初始动画
        if let anim = idleAnimation {
            contentRootNode.childNodes[0].addAnimation(anim, forKey: anim.keyPath)
        }
        
        chameleonIsTurning = false
    }
    
    /// 播放动画
    private func playAnimation(animation: SCNAnimation) {
        let modelBaseNode = contentRootNode.childNodes[0]
        modelBaseNode.addAnimation(animation, forKey: animation.keyPath)
        
        chameleonIsTurning = true
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        SCNTransaction.animationDuration = animation.duration
//        modelBaseNode.transform = SCNMatrix4Mult(modelBaseNode.presentation.transform, SCNMatrix4MakeRotation(rotationAngle, 0, 1, 0))
        SCNTransaction.completionBlock = {
            self.chameleonIsTurning = false
        }
        SCNTransaction.commit()
    }
    
    public func turnLeft() {
        playAnimation(animation: turnLeftAnimation!)
    }
    
    public func turnRight() {
        playAnimation(animation: turnRightAnimation!)
    }
}
