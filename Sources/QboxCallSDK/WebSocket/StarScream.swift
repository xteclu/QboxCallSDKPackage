//
//  StarScream.swift
//  QboxCallSDK
//
//  Created by Tileubergenov Nurken on 02.09.2024.
//

import Foundation
import Starscream


class StarscreamSocket: SocketProvider {
  let moduleName = "StarscreamSocket"
  
  weak var delegate: SocketProviderDelegate?
  private let socket: WebSocket
  var state = SocketState.None {
    didSet {
      guard state != oldValue  else { return }
      QBoxLog.debug(moduleName, "state: \(state.rawValue)")
      delegate?.socketDidChange(state: state)
    }
  }
  
  init(url: String) {
    let request = URLRequest(url: URL(string: url)!)
    socket = WebSocket(request: request)
    socket.delegate = self
  }
  
  func connect() {
    socket.connect()
  }
  
  func disconnect() {
    socket.disconnect()
  }
  
  func send(_ data: [String: Any], completion: @escaping () -> Void) {
    guard let json = try? JSONSerialization.data(withJSONObject: data) else {
      QBoxLog.error(moduleName, "send() -> JSON exception, data: \(data)")
      return
    }
    let message = String(data: json, encoding: String.Encoding.utf8) ?? ""
    socket.write(string: message) {
      DispatchQueue.main.async { completion() }
    }
  }
}

extension StarscreamSocket: WebSocketDelegate {
  func websocketDidConnect(socket: any Starscream.WebSocketClient) {
    state = SocketState.Connected
  }
  
  func websocketDidDisconnect(socket: any Starscream.WebSocketClient, error: (any Error)?) {
    if let error = error {
      QBoxLog.error(moduleName, String(describing: error))
    }
    state = SocketState.Disconnected
  }
  
  func websocketDidReceiveMessage(socket: any Starscream.WebSocketClient, text: String) {
    guard
      let data = text.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      QBoxLog.error(moduleName, "DidReceiveMessage() -> json serialize failed, data: \(text)")
      return
    }
    
    delegate?.socketDidRecieve(data: json)
  }
  
  func websocketDidReceiveData(socket: any Starscream.WebSocketClient, data: Data) {}
  
}
