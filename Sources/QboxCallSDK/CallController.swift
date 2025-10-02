//
//  CallController.swift
//  QboxCallSDK
//
//  Created by Tileubergenov Nurken on 02.09.2024.
//

import WebRTC

public protocol CallControllerDelegate: AnyObject {
  func callController(peerConnectionDidChange state: RTCPeerConnectionState)
  func callController(socketDidChange state: SocketState)
}

extension CallControllerDelegate {
  func callController(peerConnectionDidChange state: RTCPeerConnectionState) {}
  func callController(socketDidChange state: SocketState) {}
}

public class CallSettings {
  var isSpeakerEnabled: Bool
  var isMicrophoneEnabled: Bool
  var isAuthZone: Bool
  
  public init(
    isSpeakerEnabled SpeakerParam: Bool = false,
    isMicrophoneEnabled MicrophoneParam: Bool = false,
    isAuthZone AuthZoneParam: Bool = false
  ) {
    isSpeakerEnabled = SpeakerParam
    isMicrophoneEnabled = MicrophoneParam
    isAuthZone = AuthZoneParam
  }
}

public class CallController {
  let moduleName = "CallController"
  
  public weak var delegate: CallControllerDelegate?
  private let iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
  private var socket: SocketProvider?
  private var rtc: RTCClient?
  private var token: String?
  private var url: String
  private var settings: CallSettings
  private var isUsed: Bool = false
  public var socketState: SocketState {
    get {
      return socket?.state ?? SocketState.None
    }
  }
  
    public required init(url socketUrl: String, settings initialSettings: CallSettings = CallSettings()) {
        url = socketUrl
        settings = initialSettings
    }

  
  public func startCall(token socketToken: String? = nil, with initialSettings: CallSettings? = nil) -> Bool {
    if socketToken != nil { token = socketToken }
    settings = initialSettings ?? settings

    setSocket()
    guard let socket = socket else {
      return false
    }
    
    setRTC()
    guard let _ = rtc?.connection else {
      return false
    }
    
    socket.connect()
    
    return true
  }
  
  private func dispose() {
    isUsed = false

    rtc?.close()
    
    socket?.disconnect()
  }
  
  public func disconnect() {
    dispose()
  }
  
  public func endCall() {
    QBoxLog.debug(moduleName, "socket.send() -> event: hangup")
    socket?.send(["event": "hangup"]) {
      [weak self] in
      guard let self else { return }

      QBoxLog.debug(self.moduleName, "dispose()")
      self.dispose()
    }
  }
  
  private func setRTC() {
    rtc = RTCClient(iceServers: iceServers)
    rtc?.delegate = self
    QBoxLog.debug(moduleName, "setRTC() -> done")
  }
  
  private func setSocket() {
    guard let token = token else {
      QBoxLog.error(moduleName, "startCall() -> token is nil")
      return
    }
    
    let url = url.replacingOccurrences(of: "https", with: "wss") + "/websocket?token=" + token
    
    if #available(iOS 13.0, *) {
      QBoxLog.debug(moduleName, "setSocket() -> using NativeSocket")
      socket = NativeSocket(url: url)
    } else {
      QBoxLog.debug(moduleName, "setSocket() -> using StarscreamSocket")
      socket = StarscreamSocket(url: url)
    }
    socket?.delegate = self
    
    QBoxLog.debug(moduleName, "setSocket() -> done")
  }
}
// MARK: - Control methods
extension CallController{
  public func setAudioInput(isEnabled: Bool) {
    rtc?.setAudioInput(isEnabled)
    settings.isMicrophoneEnabled = isEnabled
  }
  
  public func setAudioOutput(isEnabled: Bool) {
    rtc?.setAudioOutput(isEnabled)
  }
  
  public func setSpeaker(isEnabled: Bool) {
    rtc?.setSpeaker(isEnabled)
    settings.isSpeakerEnabled = isEnabled
  }
  
  public func sendDTMF(digit: String) {
    QBoxLog.debug(moduleName, "socket.send() -> event: dtmf, digit: \(digit)")
    socket?.send([
      "event": "dtmf",
      "dtmf": ["digit": digit]
    ]) {}
  }
}
// MARK: - Socket Delegate
extension CallController: SocketProviderDelegate {
  func socketDidChange(state: SocketState) {
    switch state {
    case .Connected:
      if isUsed {
        break
      }
      
      isUsed = true

      rtc?.offer {
        [weak self] sessionDescription in
        guard let self else { return }
        QBoxLog.debug("CallController", "socket.send() -> event: call (with sessionDescription)")
          socket?.send([
            "event": "call",
            "call": [
              "sdp": [
                "sdp": sessionDescription.sdp,
                "type": stringifySDPType(sessionDescription.type)
              ],
              "auth_zone": settings.isAuthZone
            ]
          ]) {}

      }
      
    case .Disconnected:
      break
//      socket = nil
    case .None:
      break
    }
    
    delegate?.callController(socketDidChange: state)
  }
  
  func socketDidRecieve(data: [String : Any]) {
    let event = data["event"] as? String
    switch event {
    case "answer":
      guard
        let answer = data["answer"] as? [String: Any],
        let sdpData = answer["sdp"] as? [String: Any],
        let sdp = sdpData["sdp"] as? String
      else { return }
      
      let remote = RTCSessionDescription(type: .answer, sdp: sdp)
      QBoxLog.debug(moduleName, "socketDidRecieve() -> Answer")
      rtc?.set(remoteSdp: remote)
    
    case "candidate":
      guard
        let candidateData = data["candidate"] as? [String: Any]
      else { return }
      
      let sdpCandidate = candidateData["candidate"] as? String ?? ""
      let sdpMid = candidateData["sdpMid"] as? String ?? nil
      let LineIndex = candidateData["sdpMLineIndex"] as? Int ?? 0
      let candidate = RTCIceCandidate(sdp: sdpCandidate, sdpMLineIndex: Int32(LineIndex), sdpMid: sdpMid)
      QBoxLog.debug(moduleName, "socketDidRecieve() -> Candidate: \(sdpCandidate)")
      rtc?.set(remoteCandidate: candidate)
      
    case "hangup":
      QBoxLog.debug(moduleName, "socketDidRecieve() -> Hangup")
      dispose()
      
    default:
      break
    }
  }
}
// MARK: - RTCClient Delegate
extension CallController: RTCClientDelegate {
  func rtcClient(didDiscover localCandidate: RTCIceCandidate) {
    let data: [String: Any] = [
      "candidate": localCandidate.sdp,
      "sdpMid": localCandidate.sdpMid ?? "0",
      "sdpMLineIndex": Int(localCandidate.sdpMLineIndex)
    ]
    QBoxLog.debug(moduleName, "socket.send() -> event: candidate")
    socket?.send([
      "event": "candidate",
      "candidate": data
    ]) {}
  }
  
  func rtcClient(didAdd stream: RTCMediaStream) {
  }
  
  func rtcClient(didChange state: RTCPeerConnectionState) {
    switch state {
    case RTCPeerConnectionState.connected:
      setAudioInput(isEnabled: settings.isMicrophoneEnabled)
      setSpeaker(isEnabled: settings.isSpeakerEnabled)
    case RTCPeerConnectionState.closed:
      break
    default:
      break
    }
    
    delegate?.callController(peerConnectionDidChange: state)
  }
}
