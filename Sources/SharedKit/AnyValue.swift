import struct Foundation.Data
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder

/// A codable value.
public enum AnyValue: Hashable, Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case data(mimeType: String? = nil, Data)
    case array([AnyValue])
    case object([String: AnyValue])

    /// Create a `Value` from a `Codable` value.
    /// - Parameter value: The codable value
    /// - Returns: A value
    public init<T: Codable>(_ value: T) throws {
        if let valueAsValue = value as? AnyValue {
            self = valueAsValue
        } else {
            let data = try JSONEncoder().encode(value)
            self = try JSONDecoder().decode(AnyValue.self, from: data)
        }
    }

    /// Returns whether the value is `null`.
    public var isNull: Bool {
        return self == .null
    }

    /// Returns the `Bool` value if the value is a `bool`,
    /// otherwise returns `nil`.
    public var boolValue: Bool? {
        guard case let .bool(value) = self else { return nil }
        return value
    }

    /// Returns the `Int` value if the value is an `integer`,
    /// otherwise returns `nil`.
    public var intValue: Int? {
        guard case let .int(value) = self else { return nil }
        return value
    }

    /// Returns the `Double` value if the value is a `double`,
    /// otherwise returns `nil`.
    public var doubleValue: Double? {
        guard case let .double(value) = self else { return nil }
        return value
    }

    /// Returns the `String` value if the value is a `string`,
    /// otherwise returns `nil`.
    public var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
    }

    /// Returns the data value and optional MIME type if the value is `data`,
    /// otherwise returns `nil`.
    public var dataValue: (mimeType: String?, Data)? {
        guard case let .data(mimeType: mimeType, data) = self else { return nil }
        return (mimeType: mimeType, data)
    }

    /// Returns the `[AnyValue]` value if the value is an `array`,
    /// otherwise returns `nil`.
    public var arrayValue: [AnyValue]? {
        guard case let .array(value) = self else { return nil }
        return value
    }

    /// Returns the `[String: AnyValue]` value if the value is an `object`,
    /// otherwise returns `nil`.
    public var objectValue: [String: AnyValue]? {
        guard case let .object(value) = self else { return nil }
        return value
    }
}

// MARK: - Codable

extension AnyValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            if Data.isDataURL(string: value),
               case let (mimeType, data)? = Data.parseDataURL(value)
            {
                self = .data(mimeType: mimeType, data)
            } else {
                self = .string(value)
            }
        } else if let value = try? container.decode([AnyValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: AnyValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Value type not found")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case let .data(mimeType, value):
            try container.encode(value.dataURLEncoded(mimeType: mimeType))
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}

extension AnyValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .null:
            return ""
        case .bool(let value):
            return value.description
        case .int(let value):
            return value.description
        case .double(let value):
            return value.description
        case .string(let value):
            return value.description
        case let .data(mimeType, value):
            return value.dataURLEncoded(mimeType: mimeType)
        case .array(let value):
            return value.description
        case .object(let value):
            return value.description
        }
    }
}

// MARK: - ExpressibleByNilLiteral

extension AnyValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

// MARK: - ExpressibleByBooleanLiteral

extension AnyValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension AnyValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

// MARK: - ExpressibleByFloatLiteral

extension AnyValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

// MARK: - ExpressibleByStringLiteral

extension AnyValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

// MARK: - ExpressibleByArrayLiteral

extension AnyValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: AnyValue...) {
        self = .array(elements)
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension AnyValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, AnyValue)...) {
        var dictionary: [String: Value] = [:]
        for (key, value) in elements {
            dictionary[key] = value
        }
        self = .object(dictionary)
    }
}

// MARK: - ExpressibleByStringInterpolation

extension AnyValue: ExpressibleByStringInterpolation {
    public struct StringInterpolation: StringInterpolationProtocol {
        var stringValue: String

        public init(literalCapacity: Int, interpolationCount: Int) {
            self.stringValue = ""
            self.stringValue.reserveCapacity(literalCapacity + interpolationCount)
        }

        public mutating func appendLiteral(_ literal: String) {
            self.stringValue.append(literal)
        }

        public mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T) {
            self.stringValue.append(value.description)
        }
    }

    public init(stringInterpolation: StringInterpolation) {
        self = .string(stringInterpolation.stringValue)
    }
}
