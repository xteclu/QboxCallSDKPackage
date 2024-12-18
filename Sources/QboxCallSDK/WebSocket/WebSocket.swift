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
  private let networkErrors = [57 , 60 , 54]
  
  weak var delegate: SocketProviderDelegate?
  private var socketUrl: URL?
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
    socketUrl = url
    startTask()
  }
  
  func startTask() {
    guard let url = socketUrl else { return }
    socket = urlSession.webSocketTask(with: url)
  }
  
  deinit {
    socket = nil
  }
  
  func connect() {
    socket?.resume()
    listen()
  }

  func checkConnection() {
    if state != .Connected {
      socket?.cancel()
      startTask()
      connect()
    }
  }
  
  func send(_ data: [String: Any], completion: @escaping () -> Void) {
    checkConnection()

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
        QBoxLog.debug(moduleName, "DidReceiveMessage() -> Data recieved, string expected")
        
      case .failure:
        QBoxLog.error(moduleName, "DidReceiveMessage() -> socket failure")
        state = .Disconnected
        return
      }
      
      self.listen()
    }
  }
  
  func disconnect() {
    socket?.cancel()
    state = .Disconnected
  }
}

@available(iOS 13.0, *)
extension NativeSocket: URLSessionWebSocketDelegate, URLSessionDelegate  {
  func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
    state = .Connected
  }
  
  func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
    QBoxLog.error(moduleName, "urlSession() -> didCloseWith: [\(closeCode.rawValue)] \(String(describing: reason))")
    state = .Disconnected
  }
  
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
      if let error = error {
        if let error = error as NSError? {
          if networkErrors.contains(error.code) {
            QBoxLog.error(moduleName, "urlSession() -> network error")
          }
          else if error.code == -999 {
            QBoxLog.error(moduleName, "urlSession() -> task canceled")
          }
          else if error.code == -1009 {
            QBoxLog.error(moduleName, "urlSession() -> socket is already closed")
          }
          else {
            QBoxLog.error(moduleName, "urlSession() -> didCompleteWithError code: \(error.code)")
          }
        }
      }
  }
}
