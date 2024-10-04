//
//  WebSocket.swift
//  QboxCallSDK
//
//  Created by Tileubergenov Nurken on 02.09.2024.
//

import Foundation

@available(iOS 13.0, *)
class NativeSocket: NSObject, SocketProvider {
  private let moduleName = "NativeSocket"
  
  weak var delegate: SocketProviderDelegate?
  private var socket: URLSessionWebSocketTask?
  var state = SocketState.None {
    didSet {
      guard state != oldValue  else { return }
      QBoxLog.debug(moduleName, "state: \(state.rawValue)")
      delegate?.socketDidChange(state: state)
    }
  }
  
  private lazy var urlSession: URLSession = URLSession(
    configuration: .default,
    delegate: self,
    delegateQueue: nil
  )
  
  init(url urlString: String) {
    super.init()
    guard let url = URL(string: urlString) else {
      QBoxLog.error(moduleName, "init() -> incorrect url: \(urlString)")
      return
    }
    socket = urlSession.webSocketTask(with: url)
  }
  
  deinit {
    socket = nil
  }
  
  func connect() {
    socket?.resume()
    listen()
  }
  
  func send(_ data: [String: Any], completion: @escaping () -> Void) {
    guard let json = try? JSONSerialization.data(withJSONObject: data) else {
      QBoxLog.error(moduleName, "send() -> JSON exception, data: \(data)")
      return
    }
    let message = String(data: json, encoding: String.Encoding.utf8) ?? ""
    
    socket?.send(.string(message)) { _ in
      DispatchQueue.main.async { completion() }
    }
  }
  
  private func listen() {
    socket?.receive { [weak self] message in
      guard let self else { return }
      
      switch message {
      case .success(.string(let text)):
        guard
          let data = text.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
          QBoxLog.error(moduleName, "DidReceiveMessage() -> json serialize failed, data: \(text)")
          return
        }
        delegate?.socketDidRecieve(data: json)
        
      case .success:
        QBoxLog.debug(moduleName, "listen() -> Data recieved, string expected")
        
      case .failure:
        self.disconnect()
        return
      }
      
      self.listen()
    }
  }
  
  func disconnect() {
    socket?.cancel()
    state = SocketState.Disconnected
  }
}

@available(iOS 13.0, *)
extension NativeSocket: URLSessionWebSocketDelegate, URLSessionDelegate  {
  func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
    state = SocketState.Connected
  }
  
  func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
    disconnect()
  }
  
}
