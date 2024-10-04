//
//  RTCState.swift
//  QboxCallSDK
//
//  Created by Tileubergenov Nurken on 04.09.2024.
//

import Foundation
import WebRTC

public func IceConnectionState(_ state: RTCIceConnectionState) -> String {
  switch state {
  case .new:
    return "New"
  case .checking:
    return "Checking"
  case .connected:
    return "Connected"
  case .completed:
    return "Completed"
  case .failed:
    return "Failed"
  case .disconnected:
    return "Disconnected"
  case .closed:
    return "Closed"
  case .count:
    return "Count"
  @unknown default:
    return "Unknown"
  }
}

public func SignalingState(_ state: RTCSignalingState) -> String {
  switch state {
  case .stable:
    return "Stable"
  case .haveLocalOffer:
    return "Local Offer"
  case .haveLocalPrAnswer:
    return "Local Answer"
  case .haveRemoteOffer:
    return "Remote Offer"
  case .haveRemotePrAnswer:
    return "Remote Answer"
  case .closed:
    return "Closed"
  @unknown default:
    return "Unknown"
  }
}

public func IceGatheringState(_ state: RTCIceGatheringState) -> String {
  switch state {
  case .new:
    return "New"
  case .gathering:
    return "Gathering"
  case .complete:
    return "Complete"
  @unknown default:
    return "Unknown"
  }
}

public func PeerConnectionState(_ state: RTCPeerConnectionState) -> String {
  switch state {
  case .new:
    return "New"
  case .connecting:
    return "Connecting"
  case .connected:
    return "Connected"
  case .disconnected:
    return "Disconnected"
  case .failed:
    return "Failed"
  case .closed:
    return "Closed"
  @unknown default:
    return "Unknown"
  }
}
