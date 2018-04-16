//
//  Extension.swift
//  ARKitPhysics
//
//  Created by mac126 on 2018/4/8.
//  Copyright © 2018年 mac126. All rights reserved.
//

import Foundation
import SceneKit

extension SCNAnimation {
    
    /// 获取模型动画
    static func fromFile(named name: String, inDirectory: String) -> SCNAnimation? {
        let animScene = SCNScene(named: name, inDirectory: inDirectory)
        var animation: SCNAnimation?
        
        animScene?.rootNode.enumerateChildNodes({ (child, stop) in
            if !child.animationKeys.isEmpty { // 节点动画key不为空
                let player = child.animationPlayer(forKey: child.animationKeys[0])
                animation = player?.animation
                
                // 停止
                stop.initialize(to: true)
            }
        })
        // ？？ 关键路径
        animation?.keyPath = name
        
        return animation
    }
}
