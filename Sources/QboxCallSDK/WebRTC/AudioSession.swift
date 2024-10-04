//
//  AudioSession.swift
//  QboxCallSDK
//
//  Created by Tileubergenov Nurken on 03.09.2024.
//

import Foundation
import WebRTC


class AudioSession: NSObject {
  private let moduleName = "RTCAudioSession"
  
  override init() {
    super.init()
  }
  
  func configure() {
    let session = RTCAudioSession.sharedInstance()
    session.lockForConfiguration()
    
    do {
      try session.setCategory(AVAudioSession.Category.playAndRecord)
//      try session.setActive(true)  // Can be dangerous, if not set to false after
      try session.setMode(AVAudioSession.Mode.voiceChat)
      try session.setPreferredSampleRate(44100.0)
      try session.setPreferredIOBufferDuration(0.005)
    } catch {
      QBoxLog.error(moduleName, "configure() - > error: \(error)")
    }
    
    session.unlockForConfiguration()
  }
  
  func disable() {
    let session = RTCAudioSession.sharedInstance()
    session.lockForConfiguration()
    
    do {
      try session.setActive(false)
    } catch {
      QBoxLog.error(moduleName, "disable() - > error: \(error)")
    }
    
    session.unlockForConfiguration()
  }
  
  func setSpeaker(_ isForced: Bool) {
    RTCDispatcher.dispatchAsync(on: .typeAudioSession) {
      let session = RTCAudioSession.sharedInstance()
      
      let portOverride = isForced ? AVAudioSession.PortOverride.speaker : AVAudioSession.PortOverride.none
      
      session.lockForConfiguration()
      
      do {
        try session.setCategory(AVAudioSession.Category.playAndRecord)
        try session.overrideOutputAudioPort(portOverride)
      } catch {
        QBoxLog.error("RTCAudioSession", "setSpeaker(\(isForced)) - > error: \(error)")
      }
      
      session.unlockForConfiguration()
    }
  }
}
