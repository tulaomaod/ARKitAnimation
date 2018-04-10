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

    private var bobRootNode: SCNNode!
    // Animations
    private var idleAnimation: SCNAnimation?
    private var jumpAnimation: SCNAnimation?
    private var startIdleAnimation: SCNAnimation?
    
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
        guard let virtualObjectScene = SCNScene(named: "animation-start-idle", inDirectory: "art.scnassets") else { return  }
        
        // 隐藏
        hide()
        
        // 设置节点
        bobRootNode = virtualObjectScene.rootNode.childNode(withName: "Bob_root", recursively: true)

        // 加载动画
        preloadAnimations()
        
        modelLoaded = true
    }
    
    // MARK: - public api
    func hide() {
        bobRootNode.isHidden = true
    }
    
    func show() {
        bobRootNode.isHidden = false
    }
    
    func setTransform(_ transform: simd_float4x4) {
        contentRootNode.simdTransform = transform
    }
    
    // MARK: - 转向和初始动画
    private func preloadAnimations() {
        
        startIdleAnimation = SCNAnimation.fromFile(named: "animation-start-idle", inDirectory: "art.scnassets")
        startIdleAnimation?.repeatCount = -1
        
        idleAnimation = SCNAnimation.fromFile(named: "animation-idle", inDirectory: "art.scnassets")
        idleAnimation?.repeatCount = 1
        idleAnimation?.blendInDuration = 0.3
        idleAnimation?.blendOutDuration = 0.3

        
        jumpAnimation = SCNAnimation.fromFile(named: "animation-jump", inDirectory: "art.scnassets")
        jumpAnimation?.repeatCount = 1
        jumpAnimation?.blendInDuration = 0.3
        jumpAnimation?.blendOutDuration = 0.3
        
        // 开始初始动画
        if let anim = startIdleAnimation {
            bobRootNode.addAnimation(anim, forKey: anim.keyPath)
        }
    }
}
