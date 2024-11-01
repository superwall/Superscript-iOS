// This file was autogenerated by some hot garbage in the `uniffi` crate.
// Trust me, you don't want to mess with it!

// swiftlint:disable all
import Foundation

// Depending on the consumer's build setup, the low-level FFI code
// might be in a separate module, or it might be compiled inline into
// this module. This is a bit of light hackery to work with both.
#if canImport(celFFI)
    import celFFI
#endif

private extension RustBuffer {
    // Allocate a new buffer, copying the contents of a `UInt8` array.
    init(bytes: [UInt8]) {
        let rbuf = bytes.withUnsafeBufferPointer { ptr in
            RustBuffer.from(ptr)
        }
        self.init(capacity: rbuf.capacity, len: rbuf.len, data: rbuf.data)
    }

    static func empty() -> RustBuffer {
        RustBuffer(capacity: 0, len: 0, data: nil)
    }

    static func from(_ ptr: UnsafeBufferPointer<UInt8>) -> RustBuffer {
        try! rustCall { ffi_cel_eval_rustbuffer_from_bytes(ForeignBytes(bufferPointer: ptr), $0) }
    }

    // Frees the buffer in place.
    // The buffer must not be used after this is called.
    func deallocate() {
        try! rustCall { ffi_cel_eval_rustbuffer_free(self, $0) }
    }
}

private extension ForeignBytes {
    init(bufferPointer: UnsafeBufferPointer<UInt8>) {
        self.init(len: Int32(bufferPointer.count), data: bufferPointer.baseAddress)
    }
}

// For every type used in the interface, we provide helper methods for conveniently
// lifting and lowering that type from C-compatible data, and for reading and writing
// values of that type in a buffer.

// Helper classes/extensions that don't change.
// Someday, this will be in a library of its own.

private extension Data {
    init(rustBuffer: RustBuffer) {
        self.init(
            bytesNoCopy: rustBuffer.data!,
            count: Int(rustBuffer.len),
            deallocator: .none
        )
    }
}

// Define reader functionality.  Normally this would be defined in a class or
// struct, but we use standalone functions instead in order to make external
// types work.
//
// With external types, one swift source file needs to be able to call the read
// method on another source file's FfiConverter, but then what visibility
// should Reader have?
// - If Reader is fileprivate, then this means the read() must also
//   be fileprivate, which doesn't work with external types.
// - If Reader is internal/public, we'll get compile errors since both source
//   files will try define the same type.
//
// Instead, the read() method and these helper functions input a tuple of data

private func createReader(data: Data) -> (data: Data, offset: Data.Index) {
    (data: data, offset: 0)
}

// Reads an integer at the current offset, in big-endian order, and advances
// the offset on success. Throws if reading the integer would move the
// offset past the end of the buffer.
private func readInt<T: FixedWidthInteger>(_ reader: inout (data: Data, offset: Data.Index)) throws -> T {
    let range = reader.offset ..< reader.offset + MemoryLayout<T>.size
    guard reader.data.count >= range.upperBound else {
        throw UniffiInternalError.bufferOverflow
    }
    if T.self == UInt8.self {
        let value = reader.data[reader.offset]
        reader.offset += 1
        return value as! T
    }
    var value: T = 0
    let _ = withUnsafeMutableBytes(of: &value) { reader.data.copyBytes(to: $0, from: range) }
    reader.offset = range.upperBound
    return value.bigEndian
}

// Reads an arbitrary number of bytes, to be used to read
// raw bytes, this is useful when lifting strings
private func readBytes(_ reader: inout (data: Data, offset: Data.Index), count: Int) throws -> [UInt8] {
    let range = reader.offset ..< (reader.offset + count)
    guard reader.data.count >= range.upperBound else {
        throw UniffiInternalError.bufferOverflow
    }
    var value = [UInt8](repeating: 0, count: count)
    value.withUnsafeMutableBufferPointer { buffer in
        reader.data.copyBytes(to: buffer, from: range)
    }
    reader.offset = range.upperBound
    return value
}

// Reads a float at the current offset.
private func readFloat(_ reader: inout (data: Data, offset: Data.Index)) throws -> Float {
    return try Float(bitPattern: readInt(&reader))
}

// Reads a float at the current offset.
private func readDouble(_ reader: inout (data: Data, offset: Data.Index)) throws -> Double {
    return try Double(bitPattern: readInt(&reader))
}

// Indicates if the offset has reached the end of the buffer.
private func hasRemaining(_ reader: (data: Data, offset: Data.Index)) -> Bool {
    return reader.offset < reader.data.count
}

// Define writer functionality.  Normally this would be defined in a class or
// struct, but we use standalone functions instead in order to make external
// types work.  See the above discussion on Readers for details.

private func createWriter() -> [UInt8] {
    return []
}

private func writeBytes<S>(_ writer: inout [UInt8], _ byteArr: S) where S: Sequence, S.Element == UInt8 {
    writer.append(contentsOf: byteArr)
}

// Writes an integer in big-endian order.
//
// Warning: make sure what you are trying to write
// is in the correct type!
private func writeInt<T: FixedWidthInteger>(_ writer: inout [UInt8], _ value: T) {
    var value = value.bigEndian
    withUnsafeBytes(of: &value) { writer.append(contentsOf: $0) }
}

private func writeFloat(_ writer: inout [UInt8], _ value: Float) {
    writeInt(&writer, value.bitPattern)
}

private func writeDouble(_ writer: inout [UInt8], _ value: Double) {
    writeInt(&writer, value.bitPattern)
}

// Protocol for types that transfer other types across the FFI. This is
// analogous to the Rust trait of the same name.
private protocol FfiConverter {
    associatedtype FfiType
    associatedtype SwiftType

    static func lift(_ value: FfiType) throws -> SwiftType
    static func lower(_ value: SwiftType) -> FfiType
    static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> SwiftType
    static func write(_ value: SwiftType, into buf: inout [UInt8])
}

// Types conforming to `Primitive` pass themselves directly over the FFI.
private protocol FfiConverterPrimitive: FfiConverter where FfiType == SwiftType {}

extension FfiConverterPrimitive {
    #if swift(>=5.8)
        @_documentation(visibility: private)
    #endif
    public static func lift(_ value: FfiType) throws -> SwiftType {
        return value
    }

    #if swift(>=5.8)
        @_documentation(visibility: private)
    #endif
    public static func lower(_ value: SwiftType) -> FfiType {
        return value
    }
}

// Types conforming to `FfiConverterRustBuffer` lift and lower into a `RustBuffer`.
// Used for complex types where it's hard to write a custom lift/lower.
private protocol FfiConverterRustBuffer: FfiConverter where FfiType == RustBuffer {}

extension FfiConverterRustBuffer {
    #if swift(>=5.8)
        @_documentation(visibility: private)
    #endif
    public static func lift(_ buf: RustBuffer) throws -> SwiftType {
        var reader = createReader(data: Data(rustBuffer: buf))
        let value = try read(from: &reader)
        if hasRemaining(reader) {
            throw UniffiInternalError.incompleteData
        }
        buf.deallocate()
        return value
    }

    #if swift(>=5.8)
        @_documentation(visibility: private)
    #endif
    public static func lower(_ value: SwiftType) -> RustBuffer {
        var writer = createWriter()
        write(value, into: &writer)
        return RustBuffer(bytes: writer)
    }
}

// An error type for FFI errors. These errors occur at the UniFFI level, not
// the library level.
private enum UniffiInternalError: LocalizedError {
    case bufferOverflow
    case incompleteData
    case unexpectedOptionalTag
    case unexpectedEnumCase
    case unexpectedNullPointer
    case unexpectedRustCallStatusCode
    case unexpectedRustCallError
    case unexpectedStaleHandle
    case rustPanic(_ message: String)

    public var errorDescription: String? {
        switch self {
        case .bufferOverflow: return "Reading the requested value would read past the end of the buffer"
        case .incompleteData: return "The buffer still has data after lifting its containing value"
        case .unexpectedOptionalTag: return "Unexpected optional tag; should be 0 or 1"
        case .unexpectedEnumCase: return "Raw enum value doesn't match any cases"
        case .unexpectedNullPointer: return "Raw pointer value was null"
        case .unexpectedRustCallStatusCode: return "Unexpected RustCallStatus code"
        case .unexpectedRustCallError: return "CALL_ERROR but no errorClass specified"
        case .unexpectedStaleHandle: return "The object in the handle map has been dropped already"
        case let .rustPanic(message): return message
        }
    }
}

private extension NSLock {
    func withLock<T>(f: () throws -> T) rethrows -> T {
        lock()
        defer { self.unlock() }
        return try f()
    }
}

private let CALL_SUCCESS: Int8 = 0
private let CALL_ERROR: Int8 = 1
private let CALL_UNEXPECTED_ERROR: Int8 = 2
private let CALL_CANCELLED: Int8 = 3

private extension RustCallStatus {
    init() {
        self.init(
            code: CALL_SUCCESS,
            errorBuf: RustBuffer(
                capacity: 0,
                len: 0,
                data: nil
            )
        )
    }
}

private func rustCall<T>(_ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T {
    let neverThrow: ((RustBuffer) throws -> Never)? = nil
    return try makeRustCall(callback, errorHandler: neverThrow)
}

private func rustCallWithError<T, E: Swift.Error>(
    _ errorHandler: @escaping (RustBuffer) throws -> E,
    _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T
) throws -> T {
    try makeRustCall(callback, errorHandler: errorHandler)
}

private func makeRustCall<T, E: Swift.Error>(
    _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T,
    errorHandler: ((RustBuffer) throws -> E)?
) throws -> T {
    uniffiEnsureInitialized()
    var callStatus = RustCallStatus()
    let returnedVal = callback(&callStatus)
    try uniffiCheckCallStatus(callStatus: callStatus, errorHandler: errorHandler)
    return returnedVal
}

private func uniffiCheckCallStatus<E: Swift.Error>(
    callStatus: RustCallStatus,
    errorHandler: ((RustBuffer) throws -> E)?
) throws {
    switch callStatus.code {
    case CALL_SUCCESS:
        return

    case CALL_ERROR:
        if let errorHandler = errorHandler {
            throw try errorHandler(callStatus.errorBuf)
        } else {
            callStatus.errorBuf.deallocate()
            throw UniffiInternalError.unexpectedRustCallError
        }

    case CALL_UNEXPECTED_ERROR:
        // When the rust code sees a panic, it tries to construct a RustBuffer
        // with the message.  But if that code panics, then it just sends back
        // an empty buffer.
        if callStatus.errorBuf.len > 0 {
            throw try UniffiInternalError.rustPanic(FfiConverterString.lift(callStatus.errorBuf))
        } else {
            callStatus.errorBuf.deallocate()
            throw UniffiInternalError.rustPanic("Rust panic")
        }

    case CALL_CANCELLED:
        fatalError("Cancellation not supported yet")

    default:
        throw UniffiInternalError.unexpectedRustCallStatusCode
    }
}

private func uniffiTraitInterfaceCall<T>(
    callStatus: UnsafeMutablePointer<RustCallStatus>,
    makeCall: () throws -> T,
    writeReturn: (T) -> Void
) {
    do {
        try writeReturn(makeCall())
    } catch {
        callStatus.pointee.code = CALL_UNEXPECTED_ERROR
        callStatus.pointee.errorBuf = FfiConverterString.lower(String(describing: error))
    }
}

private func uniffiTraitInterfaceCallWithError<T, E>(
    callStatus: UnsafeMutablePointer<RustCallStatus>,
    makeCall: () throws -> T,
    writeReturn: (T) -> Void,
    lowerError: (E) -> RustBuffer
) {
    do {
        try writeReturn(makeCall())
    } catch let error as E {
        callStatus.pointee.code = CALL_ERROR
        callStatus.pointee.errorBuf = lowerError(error)
    } catch {
        callStatus.pointee.code = CALL_UNEXPECTED_ERROR
        callStatus.pointee.errorBuf = FfiConverterString.lower(String(describing: error))
    }
}

private class UniffiHandleMap<T> {
    private var map: [UInt64: T] = [:]
    private let lock = NSLock()
    private var currentHandle: UInt64 = 1

    func insert(obj: T) -> UInt64 {
        lock.withLock {
            let handle = currentHandle
            currentHandle += 1
            map[handle] = obj
            return handle
        }
    }

    func get(handle: UInt64) throws -> T {
        try lock.withLock {
            guard let obj = map[handle] else {
                throw UniffiInternalError.unexpectedStaleHandle
            }
            return obj
        }
    }

    @discardableResult
    func remove(handle: UInt64) throws -> T {
        try lock.withLock {
            guard let obj = map.removeValue(forKey: handle) else {
                throw UniffiInternalError.unexpectedStaleHandle
            }
            return obj
        }
    }

    var count: Int {
        map.count
    }
}

// Public interface members begin here.

#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
private struct FfiConverterString: FfiConverter {
    typealias SwiftType = String
    typealias FfiType = RustBuffer

    public static func lift(_ value: RustBuffer) throws -> String {
        defer {
            value.deallocate()
        }
        if value.data == nil {
            return String()
        }
        let bytes = UnsafeBufferPointer<UInt8>(start: value.data!, count: Int(value.len))
        return String(bytes: bytes, encoding: String.Encoding.utf8)!
    }

    public static func lower(_ value: String) -> RustBuffer {
        return value.utf8CString.withUnsafeBufferPointer { ptr in
            // The swift string gives us int8_t, we want uint8_t.
            ptr.withMemoryRebound(to: UInt8.self) { ptr in
                // The swift string gives us a trailing null byte, we don't want it.
                let buf = UnsafeBufferPointer(rebasing: ptr.prefix(upTo: ptr.count - 1))
                return RustBuffer.from(buf)
            }
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> String {
        let len: Int32 = try readInt(&buf)
        return try String(bytes: readBytes(&buf, count: Int(len)), encoding: String.Encoding.utf8)!
    }

    public static func write(_ value: String, into buf: inout [UInt8]) {
        let len = Int32(value.utf8.count)
        writeInt(&buf, len)
        writeBytes(&buf, value.utf8)
    }
}

public protocol HostContext: AnyObject {
    func computedProperty(name: String, args: String) async -> String

    func deviceProperty(name: String, args: String) async -> String
}

open class HostContextImpl:
    HostContext
{
    fileprivate let pointer: UnsafeMutableRawPointer!

    /// Used to instantiate a [FFIObject] without an actual pointer, for fakes in tests, mostly.
    #if swift(>=5.8)
        @_documentation(visibility: private)
    #endif
    public struct NoPointer {
        public init() {}
    }

    // TODO: We'd like this to be `private` but for Swifty reasons,
    // we can't implement `FfiConverter` without making this `required` and we can't
    // make it `required` without making it `public`.
    public required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        self.pointer = pointer
    }

    // This constructor can be used to instantiate a fake object.
    // - Parameter noPointer: Placeholder value so we can have a constructor separate from the default empty one that may be implemented for classes extending [FFIObject].
    //
    // - Warning:
    //     Any object instantiated with this constructor cannot be passed to an actual Rust-backed object. Since there isn't a backing [Pointer] the FFI lower functions will crash.
    #if swift(>=5.8)
        @_documentation(visibility: private)
    #endif
    public init(noPointer _: NoPointer) {
        pointer = nil
    }

    #if swift(>=5.8)
        @_documentation(visibility: private)
    #endif
    public func uniffiClonePointer() -> UnsafeMutableRawPointer {
        return try! rustCall { uniffi_cel_eval_fn_clone_hostcontext(self.pointer, $0) }
    }

    // No primary constructor declared for this class.

    deinit {
        guard let pointer = pointer else {
            return
        }

        try! rustCall { uniffi_cel_eval_fn_free_hostcontext(pointer, $0) }
    }

    open func computedProperty(name: String, args: String) async -> String {
        return
            try! await uniffiRustCallAsync(
                rustFutureFunc: {
                    uniffi_cel_eval_fn_method_hostcontext_computed_property(
                        self.uniffiClonePointer(),
                        FfiConverterString.lower(name), FfiConverterString.lower(args)
                    )
                },
                pollFunc: ffi_cel_eval_rust_future_poll_rust_buffer,
                completeFunc: ffi_cel_eval_rust_future_complete_rust_buffer,
                freeFunc: ffi_cel_eval_rust_future_free_rust_buffer,
                liftFunc: FfiConverterString.lift,
                errorHandler: nil
            )
    }

    open func deviceProperty(name: String, args: String) async -> String {
        return
            try! await uniffiRustCallAsync(
                rustFutureFunc: {
                    uniffi_cel_eval_fn_method_hostcontext_device_property(
                        self.uniffiClonePointer(),
                        FfiConverterString.lower(name), FfiConverterString.lower(args)
                    )
                },
                pollFunc: ffi_cel_eval_rust_future_poll_rust_buffer,
                completeFunc: ffi_cel_eval_rust_future_complete_rust_buffer,
                freeFunc: ffi_cel_eval_rust_future_free_rust_buffer,
                liftFunc: FfiConverterString.lift,
                errorHandler: nil
            )
    }
}

// Magic number for the Rust proxy to call using the same mechanism as every other method,
// to free the callback once it's dropped by Rust.
private let IDX_CALLBACK_FREE: Int32 = 0
// Callback return codes
private let UNIFFI_CALLBACK_SUCCESS: Int32 = 0
private let UNIFFI_CALLBACK_ERROR: Int32 = 1
private let UNIFFI_CALLBACK_UNEXPECTED_ERROR: Int32 = 2

// Put the implementation in a struct so we don't pollute the top-level namespace
private enum UniffiCallbackInterfaceHostContext {
    // Create the VTable using a series of closures.
    // Swift automatically converts these into C callback functions.
    static var vtable: UniffiVTableCallbackInterfaceHostContext = .init(
        computedProperty: { (
            uniffiHandle: UInt64,
            name: RustBuffer,
            args: RustBuffer,
            uniffiFutureCallback: @escaping UniffiForeignFutureCompleteRustBuffer,
            uniffiCallbackData: UInt64,
            uniffiOutReturn: UnsafeMutablePointer<UniffiForeignFuture>
        ) in
            let makeCall = {
                () async throws -> String in
                guard let uniffiObj = try? FfiConverterTypeHostContext.handleMap.get(handle: uniffiHandle) else {
                    throw UniffiInternalError.unexpectedStaleHandle
                }
                return try await uniffiObj.computedProperty(
                    name: FfiConverterString.lift(name),
                    args: FfiConverterString.lift(args)
                )
            }

            let uniffiHandleSuccess = { (returnValue: String) in
                uniffiFutureCallback(
                    uniffiCallbackData,
                    UniffiForeignFutureStructRustBuffer(
                        returnValue: FfiConverterString.lower(returnValue),
                        callStatus: RustCallStatus()
                    )
                )
            }
            let uniffiHandleError = { statusCode, errorBuf in
                uniffiFutureCallback(
                    uniffiCallbackData,
                    UniffiForeignFutureStructRustBuffer(
                        returnValue: RustBuffer.empty(),
                        callStatus: RustCallStatus(code: statusCode, errorBuf: errorBuf)
                    )
                )
            }
            let uniffiForeignFuture = uniffiTraitInterfaceCallAsync(
                makeCall: makeCall,
                handleSuccess: uniffiHandleSuccess,
                handleError: uniffiHandleError
            )
            uniffiOutReturn.pointee = uniffiForeignFuture
        },
        deviceProperty: { (
            uniffiHandle: UInt64,
            name: RustBuffer,
            args: RustBuffer,
            uniffiFutureCallback: @escaping UniffiForeignFutureCompleteRustBuffer,
            uniffiCallbackData: UInt64,
            uniffiOutReturn: UnsafeMutablePointer<UniffiForeignFuture>
        ) in
            let makeCall = {
                () async throws -> String in
                guard let uniffiObj = try? FfiConverterTypeHostContext.handleMap.get(handle: uniffiHandle) else {
                    throw UniffiInternalError.unexpectedStaleHandle
                }
                return try await uniffiObj.deviceProperty(
                    name: FfiConverterString.lift(name),
                    args: FfiConverterString.lift(args)
                )
            }

            let uniffiHandleSuccess = { (returnValue: String) in
                uniffiFutureCallback(
                    uniffiCallbackData,
                    UniffiForeignFutureStructRustBuffer(
                        returnValue: FfiConverterString.lower(returnValue),
                        callStatus: RustCallStatus()
                    )
                )
            }
            let uniffiHandleError = { statusCode, errorBuf in
                uniffiFutureCallback(
                    uniffiCallbackData,
                    UniffiForeignFutureStructRustBuffer(
                        returnValue: RustBuffer.empty(),
                        callStatus: RustCallStatus(code: statusCode, errorBuf: errorBuf)
                    )
                )
            }
            let uniffiForeignFuture = uniffiTraitInterfaceCallAsync(
                makeCall: makeCall,
                handleSuccess: uniffiHandleSuccess,
                handleError: uniffiHandleError
            )
            uniffiOutReturn.pointee = uniffiForeignFuture
        },
        uniffiFree: { (uniffiHandle: UInt64) in
            let result = try? FfiConverterTypeHostContext.handleMap.remove(handle: uniffiHandle)
            if result == nil {
                print("Uniffi callback interface HostContext: handle missing in uniffiFree")
            }
        }
    )
}

private func uniffiCallbackInitHostContext() {
    uniffi_cel_eval_fn_init_callback_vtable_hostcontext(&UniffiCallbackInterfaceHostContext.vtable)
}

#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
public struct FfiConverterTypeHostContext: FfiConverter {
    fileprivate static var handleMap = UniffiHandleMap<HostContext>()

    typealias FfiType = UnsafeMutableRawPointer
    typealias SwiftType = HostContext

    public static func lift(_ pointer: UnsafeMutableRawPointer) throws -> HostContext {
        return HostContextImpl(unsafeFromRawPointer: pointer)
    }

    public static func lower(_ value: HostContext) -> UnsafeMutableRawPointer {
        guard let ptr = UnsafeMutableRawPointer(bitPattern: UInt(truncatingIfNeeded: handleMap.insert(obj: value))) else {
            fatalError("Cast to UnsafeMutableRawPointer failed")
        }
        return ptr
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> HostContext {
        let v: UInt64 = try readInt(&buf)
        // The Rust code won't compile if a pointer won't fit in a UInt64.
        // We have to go via `UInt` because that's the thing that's the size of a pointer.
        let ptr = UnsafeMutableRawPointer(bitPattern: UInt(truncatingIfNeeded: v))
        if ptr == nil {
            throw UniffiInternalError.unexpectedNullPointer
        }
        return try lift(ptr!)
    }

    public static func write(_ value: HostContext, into buf: inout [UInt8]) {
        // This fiddling is because `Int` is the thing that's the same size as a pointer.
        // The Rust code won't compile if a pointer won't fit in a `UInt64`.
        writeInt(&buf, UInt64(bitPattern: Int64(Int(bitPattern: lower(value)))))
    }
}

#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
public func FfiConverterTypeHostContext_lift(_ pointer: UnsafeMutableRawPointer) throws -> HostContext {
    return try FfiConverterTypeHostContext.lift(pointer)
}

#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
public func FfiConverterTypeHostContext_lower(_ value: HostContext) -> UnsafeMutableRawPointer {
    return FfiConverterTypeHostContext.lower(value)
}

private let UNIFFI_RUST_FUTURE_POLL_READY: Int8 = 0
private let UNIFFI_RUST_FUTURE_POLL_MAYBE_READY: Int8 = 1

private let uniffiContinuationHandleMap = UniffiHandleMap<UnsafeContinuation<Int8, Never>>()

private func uniffiRustCallAsync<F, T>(
    rustFutureFunc: () -> UInt64,
    pollFunc: (UInt64, @escaping UniffiRustFutureContinuationCallback, UInt64) -> Void,
    completeFunc: (UInt64, UnsafeMutablePointer<RustCallStatus>) -> F,
    freeFunc: (UInt64) -> Void,
    liftFunc: (F) throws -> T,
    errorHandler: ((RustBuffer) throws -> Swift.Error)?
) async throws -> T {
    // Make sure to call uniffiEnsureInitialized() since future creation doesn't have a
    // RustCallStatus param, so doesn't use makeRustCall()
    uniffiEnsureInitialized()
    let rustFuture = rustFutureFunc()
    defer {
        freeFunc(rustFuture)
    }
    var pollResult: Int8
    repeat {
        pollResult = await withUnsafeContinuation {
            pollFunc(
                rustFuture,
                uniffiFutureContinuationCallback,
                uniffiContinuationHandleMap.insert(obj: $0)
            )
        }
    } while pollResult != UNIFFI_RUST_FUTURE_POLL_READY

    return try liftFunc(makeRustCall(
        { completeFunc(rustFuture, $0) },
        errorHandler: errorHandler
    ))
}

// Callback handlers for an async calls.  These are invoked by Rust when the future is ready.  They
// lift the return value or error and resume the suspended function.
private func uniffiFutureContinuationCallback(handle: UInt64, pollResult: Int8) {
    if let continuation = try? uniffiContinuationHandleMap.remove(handle: handle) {
        continuation.resume(returning: pollResult)
    } else {
        print("uniffiFutureContinuationCallback invalid handle")
    }
}

private func uniffiTraitInterfaceCallAsync<T>(
    makeCall: @escaping () async throws -> T,
    handleSuccess: @escaping (T) -> Void,
    handleError: @escaping (Int8, RustBuffer) -> Void
) -> UniffiForeignFuture {
    let task = Task {
        do {
            try handleSuccess(await makeCall())
        } catch {
            handleError(CALL_UNEXPECTED_ERROR, FfiConverterString.lower(String(describing: error)))
        }
    }
    let handle = UNIFFI_FOREIGN_FUTURE_HANDLE_MAP.insert(obj: task)
    return UniffiForeignFuture(handle: handle, free: uniffiForeignFutureFree)
}

private func uniffiTraitInterfaceCallAsyncWithError<T, E>(
    makeCall: @escaping () async throws -> T,
    handleSuccess: @escaping (T) -> Void,
    handleError: @escaping (Int8, RustBuffer) -> Void,
    lowerError: @escaping (E) -> RustBuffer
) -> UniffiForeignFuture {
    let task = Task {
        do {
            try handleSuccess(await makeCall())
        } catch let error as E {
            handleError(CALL_ERROR, lowerError(error))
        } catch {
            handleError(CALL_UNEXPECTED_ERROR, FfiConverterString.lower(String(describing: error)))
        }
    }
    let handle = UNIFFI_FOREIGN_FUTURE_HANDLE_MAP.insert(obj: task)
    return UniffiForeignFuture(handle: handle, free: uniffiForeignFutureFree)
}

// Borrow the callback handle map implementation to store foreign future handles
// TODO: consolidate the handle-map code (https://github.com/mozilla/uniffi-rs/pull/1823)
private var UNIFFI_FOREIGN_FUTURE_HANDLE_MAP = UniffiHandleMap<UniffiForeignFutureTask>()

// Protocol for tasks that handle foreign futures.
//
// Defining a protocol allows all tasks to be stored in the same handle map.  This can't be done
// with the task object itself, since has generic parameters.
protocol UniffiForeignFutureTask {
    func cancel()
}

extension Task: UniffiForeignFutureTask {}

private func uniffiForeignFutureFree(handle: UInt64) {
    do {
        let task = try UNIFFI_FOREIGN_FUTURE_HANDLE_MAP.remove(handle: handle)
        // Set the cancellation flag on the task.  If it's still running, the code can check the
        // cancellation flag or call `Task.checkCancellation()`.  If the task has completed, this is
        // a no-op.
        task.cancel()
    } catch {
        print("uniffiForeignFutureFree: handle missing from handlemap")
    }
}

// For testing
public func uniffiForeignFutureHandleCountCel() -> Int {
    UNIFFI_FOREIGN_FUTURE_HANDLE_MAP.count
}

public func evaluateAst(ast: String) -> String {
    return try! FfiConverterString.lift(try! rustCall {
        uniffi_cel_eval_fn_func_evaluate_ast(
            FfiConverterString.lower(ast), $0
        )
    })
}

public func evaluateAstWithContext(definition: String, context: HostContext) -> String {
    return try! FfiConverterString.lift(try! rustCall {
        uniffi_cel_eval_fn_func_evaluate_ast_with_context(
            FfiConverterString.lower(definition),
            FfiConverterTypeHostContext.lower(context), $0
        )
    })
}

public func evaluateWithContext(definition: String, context: HostContext) -> String {
    return try! FfiConverterString.lift(try! rustCall {
        uniffi_cel_eval_fn_func_evaluate_with_context(
            FfiConverterString.lower(definition),
            FfiConverterTypeHostContext.lower(context), $0
        )
    })
}

public func parseToAst(expression: String) -> String {
    return try! FfiConverterString.lift(try! rustCall {
        uniffi_cel_eval_fn_func_parse_to_ast(
            FfiConverterString.lower(expression), $0
        )
    })
}

private enum InitializationResult {
    case ok
    case contractVersionMismatch
    case apiChecksumMismatch
}

// Use a global variable to perform the versioning checks. Swift ensures that
// the code inside is only computed once.
private var initializationResult: InitializationResult = {
    // Get the bindings contract version from our ComponentInterface
    let bindings_contract_version = 26
    // Get the scaffolding contract version by calling the into the dylib
    let scaffolding_contract_version = ffi_cel_eval_uniffi_contract_version()
    if bindings_contract_version != scaffolding_contract_version {
        return InitializationResult.contractVersionMismatch
    }
    if uniffi_cel_eval_checksum_func_evaluate_ast() != 54749 {
        return InitializationResult.apiChecksumMismatch
    }
    if uniffi_cel_eval_checksum_func_evaluate_ast_with_context() != 28567 {
        return InitializationResult.apiChecksumMismatch
    }
    if uniffi_cel_eval_checksum_func_evaluate_with_context() != 37319 {
        return InitializationResult.apiChecksumMismatch
    }
    if uniffi_cel_eval_checksum_func_parse_to_ast() != 40465 {
        return InitializationResult.apiChecksumMismatch
    }
    if uniffi_cel_eval_checksum_method_hostcontext_computed_property() != 23284 {
        return InitializationResult.apiChecksumMismatch
    }
    if uniffi_cel_eval_checksum_method_hostcontext_device_property() != 48756 {
        return InitializationResult.apiChecksumMismatch
    }

    uniffiCallbackInitHostContext()
    return InitializationResult.ok
}()

private func uniffiEnsureInitialized() {
    switch initializationResult {
    case .ok:
        break
    case .contractVersionMismatch:
        fatalError("UniFFI contract version mismatch: try cleaning and rebuilding your project")
    case .apiChecksumMismatch:
        fatalError("UniFFI API checksum mismatch: try cleaning and rebuilding your project")
    }
}

// swiftlint:enable all