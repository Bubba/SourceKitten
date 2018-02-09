//
//  UID.swift
//  SourceKitten
//
//  Created by Norio Nomura on 2/07/18.
//  Copyright © 2018 SourceKitten. All rights reserved.
//

import Foundation
#if SWIFT_PACKAGE
import SourceKit
#endif

/// Swift representation of sourcekitd_uid_t
public struct UID {
    let uid: sourcekitd_uid_t
    init(_ uid: sourcekitd_uid_t) {
        self.uid = uid
    }

    public init(_ string: String) {
        let uid = sourcekitd_uid_get_from_cstr(string)
        precondition(uid != nil, "Failed to create sourcekitd_uid_t from \(string)")
        self.init(uid!)
    }

    public init<T>(_ rawRepresentable: T) where T: RawRepresentable, T.RawValue == String {
        self.init(rawRepresentable.rawValue)
    }

    var string: String {
        return String(cString: sourcekitd_uid_get_string_ptr(uid)!)
    }
}

extension UID: CustomStringConvertible {
    public var description: String {
        return string
    }
}

extension UID: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension UID: Hashable {
#if (!swift(>=4.1) && swift(>=4.0)) || !swift(>=3.3)
    public var hashValue: Int {
        return uid.hashValue
    }

    public static func == (lhs: UID, rhs: UID) -> Bool {
        return lhs.uid == rhs.uid
    }
#endif
}

extension UID: SourceKitObjectConvertible {
    public func sourceKitObject() throws -> sourcekitd_object_t {
        guard let object = sourcekitd_request_uid_create(uid) else { throw failedToCreate() }
        return object
    }
}
