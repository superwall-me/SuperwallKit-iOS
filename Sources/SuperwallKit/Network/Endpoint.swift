//
//  Endpoint.swift
//  Superwall
//
//  Created by Yusuf Tör on 04/03/2022.
//

import Foundation

struct Endpoint<Kind: EndpointKind, Response: Decodable> {
  enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
  }

  struct Components {
    let host: EndpointHost?
    let path: String
    var queryItems: [URLQueryItem]?
    var bodyData: Data?
  }

  var retryCount = 6
  var retryInterval: Seconds?
  var components: Components?
  var url: URL?
  var method: HttpMethod = .get

  func makeRequest(
    with data: Kind.RequestData,
    factory: ApiFactory
  ) async -> URLRequest? {
    let url: URL

    if let components = components {
      let defaultComponents = factory.makeDefaultComponents(host: components.host ?? .base)
      var component = URLComponents()
      component.scheme = defaultComponents.scheme
      component.host = defaultComponents.host
      component.port = defaultComponents.port
      component.queryItems = components.queryItems
      component.path = components.path

      // If either the path or the query items passed contained
      // invalid characters, we'll get a nil URL back:
      guard let componentUrl = component.url else {
        return nil
      }
      url = componentUrl
    } else if let selfUrl = self.url {
      url = selfUrl
    } else {
      return nil
    }

    var request = URLRequest(url: url)
    request.cachePolicy = .reloadRevalidatingCacheData
    request.httpMethod = method.rawValue

    if let bodyData = components?.bodyData {
      request.httpBody = bodyData
    }
    await Kind.prepare(&request, with: data)
    return request
  }
}

// MARK: - EventsResponse
extension Endpoint where
  Kind == EndpointKinds.Superwall,
  Response == EventsResponse {
  static func events(eventsRequest: EventsRequest) -> Self {
    let bodyData = try? JSONEncoder.toSnakeCase.encode(eventsRequest)

    return Endpoint(
      components: Components(
        host: .collector,
        path: Api.version1 + "events",
        bodyData: bodyData
      ),
      method: .post
    )
  }

  static func sessionEvents(_ session: SessionEventsRequest) -> Self {
    let bodyData = try? JSONEncoder.toSnakeCase.encode(session)

    return Endpoint(
      components: Components(
        host: .collector,
        path: Api.version1 + "session_events",
        bodyData: bodyData
      ),
      method: .post
    )
  }
}

// MARK: - Paywall
extension Endpoint where
  Kind == EndpointKinds.Superwall,
  Response == Paywall {
  static func paywall(
    withIdentifier identifier: String? = nil,
    fromPlacement placement: PlacementData? = nil,
    retryCount: Int,
    appUserId: String?,
    apiKey: String,
    config: Config?,
    locale: String
  ) -> Self {
    var bodyData: Data?

    if let identifier = identifier {
      return paywall(
        byIdentifier: identifier,
        retryCount: retryCount,
        apiKey: apiKey,
        config: config,
        locale: locale
      )
    } else if let placement = placement {
      let bodyDict = ["event": placement.jsonData]
      bodyData = try? JSONEncoder.toSnakeCase.encode(bodyDict)
    } else if let appUserId = appUserId {
      let body = PaywallRequestBody(appUserId: appUserId)
      bodyData = try? JSONEncoder.toSnakeCase.encode(body)
    }

    return Endpoint(
      retryCount: retryCount,
      components: Components(
        host: .base,
        path: Api.version1 + "paywall",
        bodyData: bodyData
      ),
      method: .post
    )
  }

  static private func paywall(
    byIdentifier identifier: String,
    retryCount: Int,
    apiKey: String,
    config: Config?,
    locale: String
  ) -> Self {
    // WARNING: Do not modify anything about this request without considering our cache eviction code
    // we must know all the exact urls we need to invalidate so changing the order, inclusion, etc of any query
    // parameters will cause issues
    var queryItems = [URLQueryItem(name: "pk", value: apiKey)]

    // In the config endpoint we return all the locales, this code will check if:
    // 1. The device locale (ex: en_US) exists in the locales list
    // 2. The shortend device locale (ex: en) exists in the locale list
    // If either exist (preferring the most specific) include the locale in the
    // the url as a query param.
    if let config = config {
      if config.locales.contains(locale) {
        let localeQuery = URLQueryItem(
          name: "locale",
          value: locale
        )
        queryItems.append(localeQuery)
      } else {
        let shortLocale = locale.split(separator: "_")[0]
        if config.locales.contains(String(shortLocale)) {
          let localeQuery = URLQueryItem(
            name: "locale",
            value: String(shortLocale)
          )
          queryItems.append(localeQuery)
        }
      }
    }

    return Endpoint(
      retryCount: retryCount,
      components: Components(
        host: .base,
        path: Api.version1 + "paywall/\(identifier)",
        queryItems: queryItems
      ),
      method: .get
    )
  }
}

// MARK: - PaywallsResponse
extension Endpoint where
  Kind == EndpointKinds.Superwall,
  Response == Paywalls {
  static func paywalls() -> Self {
    return Endpoint(
      components: Components(
        host: .base,
        path: Api.version1 + "paywalls"
      ),
      method: .get
    )
  }
}

// MARK: - ConfigResponse
extension Endpoint where
  Kind == EndpointKinds.Superwall,
  Response == Config {
  static func config(
    maxRetry: Int,
    apiKey: String
  ) -> Self {
    let queryItems = [URLQueryItem(name: "pk", value: apiKey)]

    return Endpoint(
      retryCount: maxRetry,
      components: Components(
        host: .base,
        path: Api.version1 + "static_config",
        queryItems: queryItems
      ),
      method: .get
    )
  }
}

// MARK: - ConfirmedAssignmentResponse
extension Endpoint where
  Kind == EndpointKinds.Superwall,
  Response == ConfirmedAssignmentResponse {
  static func assignments() -> Self {
    return Endpoint(
      components: Components(
        host: .base,
        path: Api.version1 + "assignments"
      ),
      method: .get
    )
  }

  static func confirmAssignments(
    _ confirmableAssignments: AssignmentPostback
  ) -> Self {
    let bodyData = try? JSONEncoder.toSnakeCase.encode(confirmableAssignments)

    return Endpoint(
      components: Components(
        host: .base,
        path: Api.version1 + "confirm_assignments",
        bodyData: bodyData
      ),
      method: .post
    )
  }
}

// MARK: - GeoWrapper
extension Endpoint where
  Kind == EndpointKinds.Superwall,
  Response == GeoWrapper {
  static func geo(
    maxRetry: Int
  ) -> Self {
    return Endpoint(
      retryCount: maxRetry,
      components: Components(
        host: .geo,
        path: Api.version1 + "geo"
      ),
      method: .get
    )
  }
}

// MARK: - Ad Services
extension Endpoint where
  Kind == EndpointKinds.Superwall,
  Response == AdServicesResponse {
  static func adServices(token: String) -> Self {
    let body = ["token": token]
    let bodyData = try? JSONEncoder.toSnakeCase.encode(body)

    return Endpoint(
      retryCount: 3,
      retryInterval: 5,
      components: Components(
        host: .base,
        path: Api.version1 + "apple-search-ads/token",
        bodyData: bodyData
      ),
      method: .post
    )
  }
}
