//
//  SocketProvider.swift
//  QboxCallSDK
//
//  Created by Tileubergenov Nurken on 02.09.2024.
//

import Foundation


public enum SocketState: String {
  case None, Connected, Disconnected
}

protocol SocketProvider: AnyObject {
  var state: SocketState { get }
  var delegate: SocketProviderDelegate? { get set }
  func connect()
  func disconnect()
  func send(_ data: [String: Any], completion: @escaping () -> Void)
}

protocol SocketProviderDelegate: AnyObject {
  func socketDidChange(state: SocketState)
  func socketDidRecieve(data: [String: Any])
}
