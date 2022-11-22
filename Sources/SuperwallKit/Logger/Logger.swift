//
//  File.swift
//  
//
//  Created by brian on 7/28/21.
//

import Foundation

enum Logger {
	static func shouldPrint(
    logLevel: LogLevel,
    scope: LogScope
  ) -> Bool {
    let exceedsCurrentLogLevel = logLevel.rawValue >= (Superwall.options.logging.level?.rawValue ?? 99)
    let isInScope = Superwall.options.logging.scopes.contains(scope)
    let allLogsActive = Superwall.options.logging.scopes.contains(.all)

    return exceedsCurrentLogLevel
      && (isInScope || allLogsActive)
	}

	static func debug(
    logLevel: LogLevel,
    scope: LogScope,
    message: String? = nil,
    info: [String: Any]? = nil,
    error: Swift.Error? = nil
  ) {
    Task.detached(priority: .utility) {
      var output: [String] = []
      var dumping: [String: Any] = [:]

      if let message = message {
        output.append(message)
      }

      if let info = info {
        output.append(info.debugDescription)
        dumping["info"] = info
      }

      if let error = error {
        output.append(error.localizedDescription)
        dumping["error"] = error
      }

      await Superwall.shared.delegateAdapter.handleLog(
        level: logLevel.description,
        scope: scope.rawValue,
        message: message,
        info: info,
        error: error
      )

      guard shouldPrint(logLevel: logLevel, scope: scope) else {
        return
      }
      let dateString = Date().isoString
        .replacingOccurrences(of: "T", with: " ")
        .replacingOccurrences(of: "Z", with: "")

      dump(
        dumping,
        name: "[Superwall]  [\(dateString)]  \(logLevel.description)  \(scope.rawValue)  \(message ?? "")",
        indent: 0,
        maxDepth: 100,
        maxItems: 100
      )
    }
	}
}