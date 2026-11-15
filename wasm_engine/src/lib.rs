// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 The Sinter Authors

//! The C interface that Sinter uses to compile, instantiate, and run
//! modules of exactly WebAssembly Core 2.0.
//!
//! An engine compiles modules. A module gives the number of its imports
//! and the facts of its exports. An instance of a module lives in a new
//! store of its own, has no import, and runs under limits of fuel,
//! memory, and table elements. The declarations are in
//! `include/sinter_wasm_engine.h`.

#![warn(unsafe_op_in_unsafe_fn)]

#[cfg(panic = "abort")]
compile_error!("the engine needs unwinding panics; do not build it with panic = \"abort\"");

mod engine;
mod instance;
mod store;

use engine::Compiled;
use instance::{FAILURE_FAULT, Failure, Limits, Misuse, Running};
use store::{Linked, Part, Source};

/// A byte sequence that the engine owns. Free it with
/// `sinter_wasm_bytes_free`.
#[repr(C)]
pub struct SinterWasmBytes {
    data: *mut u8,
    len: usize,
}

impl SinterWasmBytes {
    fn empty() -> SinterWasmBytes {
        SinterWasmBytes {
            data: std::ptr::null_mut(),
            len: 0,
        }
    }

    fn of_text(text: &str) -> SinterWasmBytes {
        let boxed: Box<[u8]> = text.as_bytes().into();
        let len = boxed.len();
        SinterWasmBytes {
            data: Box::into_raw(boxed) as *mut u8,
            len,
        }
    }
}

/// A failure of an instantiation or of an invocation: its code, and its
/// message for the codes that have one.
#[repr(C)]
pub struct SinterWasmFailure {
    code: u32,
    message: SinterWasmBytes,
}

/// A value of type `i32` (kind 0) or `i64` (kind 1), as its bits.
#[repr(C)]
#[derive(Clone, Copy)]
pub struct SinterWasmValue {
    kind: u32,
    bits: u64,
}

/// The limits of one instance.
#[repr(C)]
#[derive(Clone, Copy)]
pub struct SinterWasmLimits {
    fuel: u64,
    memory: u64,
    table: u64,
}

/// An engine of exactly WebAssembly Core 2.0.
pub struct SinterWasmEngine {
    engine: wasmtime::Engine,
    native_stack: usize,
}

/// A compiled module.
pub struct SinterWasmModule {
    compiled: Compiled,
}

/// An instance of a module in a store of its own.
pub struct SinterWasmInstance {
    running: Running,
}

/// A store of several instances, linked by their imports.
pub struct SinterWasmStore {
    linked: Linked,
}

/// The value of one import of an instance in a store: kind 0 is the
/// export `name` of the instance `instance` of the store; kind 1 is a
/// new global of type `i32`, mutable when `mutable` is not 0, with the
/// value `value`; kind 2 is a new function that traps.
#[repr(C)]
pub struct SinterWasmImport {
    kind: u32,
    instance: u64,
    name: *const u8,
    name_len: usize,
    mutable: i32,
    value: i32,
}

/// The result code of a call that succeeded.
const DONE: i32 = 0;
/// The result code of a call whose code failed; the failure says why.
const FAILED: i32 = 1;
/// The result code of a call that its precondition does not allow; the
/// message says why.
const MISUSE: i32 = 2;
/// The result code of a call that stopped on an internal fault of the
/// engine.
const FAULT: i32 = 3;

fn guard<T>(fault: T, body: impl FnOnce() -> T) -> T {
    std::panic::catch_unwind(std::panic::AssertUnwindSafe(body)).unwrap_or(fault)
}

/// # Safety
///
/// `out` must be null or valid for a write.
unsafe fn put<T>(out: *mut T, value: T) {
    if !out.is_null() {
        unsafe { out.write(value) };
    }
}

/// # Safety
///
/// `data` must be valid for `len` bytes, or `len` must be 0.
unsafe fn borrow<'a>(data: *const u8, len: usize) -> &'a [u8] {
    if len == 0 || data.is_null() {
        &[]
    } else {
        unsafe { std::slice::from_raw_parts(data, len) }
    }
}

/// # Safety
///
/// `data` must be valid for `len` bytes, or `len` must be 0.
unsafe fn utf8<'a>(data: *const u8, len: usize) -> Option<&'a str> {
    std::str::from_utf8(unsafe { borrow(data, len) }).ok()
}

/// # Safety
///
/// `out` must be null or valid for a write.
unsafe fn put_failure(out: *mut SinterWasmFailure, failure: Failure) {
    let message = if failure.message.is_empty() {
        SinterWasmBytes::empty()
    } else {
        SinterWasmBytes::of_text(&failure.message)
    };
    unsafe {
        put(
            out,
            SinterWasmFailure {
                code: failure.code,
                message,
            },
        )
    };
}

/// # Safety
///
/// `out` must be null or valid for a write.
unsafe fn put_message(out: *mut SinterWasmBytes, message: &str) {
    unsafe { put(out, SinterWasmBytes::of_text(message)) };
}

const FAULT_MESSAGE: &str = "the WebAssembly engine stopped on an internal fault";

/// Free a byte sequence that the engine gave.
///
/// # Safety
///
/// `bytes` must be a byte sequence that the engine gave and that was
/// not freed before.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_bytes_free(bytes: SinterWasmBytes) {
    guard((), move || {
        if !bytes.data.is_null() {
            let slice = std::ptr::slice_from_raw_parts_mut(bytes.data, bytes.len);
            drop(unsafe { Box::from_raw(slice) });
        }
    })
}

/// Make an engine whose WebAssembly code has `stack` bytes of call
/// stack. Returns null on failure, with the message in `message`.
///
/// # Safety
///
/// `message` must be null or valid for a write.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_engine_new(
    stack: u64,
    message: *mut SinterWasmBytes,
) -> *mut SinterWasmEngine {
    let made = guard(Err(FAULT_MESSAGE.to_owned()), move || {
        let stack = usize::try_from(stack).map_err(|_| "the stack size is too large".to_owned())?;
        let native_stack =
            engine::native_stack(stack).ok_or_else(|| "the stack size is too large".to_owned())?;
        engine::new_engine(stack)
            .map(|engine| (engine, native_stack))
            .map_err(|error| format!("{error:#}"))
    });
    match made {
        Ok((engine, native_stack)) => Box::into_raw(Box::new(SinterWasmEngine {
            engine,
            native_stack,
        })),
        Err(text) => {
            unsafe { put_message(message, &text) };
            std::ptr::null_mut()
        }
    }
}

/// Free an engine. Its modules stay valid.
///
/// # Safety
///
/// `engine` must be null, or an engine that was not freed before.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_engine_free(engine: *mut SinterWasmEngine) {
    guard((), move || {
        if !engine.is_null() {
            drop(unsafe { Box::from_raw(engine) });
        }
    })
}

/// Compile the `len` bytes at `bytes` as a module. Returns null when
/// they are not a module of WebAssembly Core 2.0 for the engine, with
/// the message of the engine in `message`.
///
/// # Safety
///
/// `engine` must be a live engine; `bytes` must be valid for `len`
/// bytes; `message` must be null or valid for a write.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_module_new(
    engine: *const SinterWasmEngine,
    bytes: *const u8,
    len: usize,
    message: *mut SinterWasmBytes,
) -> *mut SinterWasmModule {
    let compiled = guard(Err(FAULT_MESSAGE.to_owned()), move || {
        let engine = unsafe { &*engine };
        engine::compile(
            &engine.engine,
            engine.native_stack,
            unsafe { borrow(bytes, len) }.to_vec(),
        )
    });
    match compiled {
        Ok(compiled) => Box::into_raw(Box::new(SinterWasmModule { compiled })),
        Err(text) => {
            unsafe { put_message(message, &text) };
            std::ptr::null_mut()
        }
    }
}

/// Free a module. Its instances stay valid.
///
/// # Safety
///
/// `module` must be null, or a module that was not freed before.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_module_free(module: *mut SinterWasmModule) {
    guard((), move || {
        if !module.is_null() {
            drop(unsafe { Box::from_raw(module) });
        }
    })
}

/// The number of imports of a module.
///
/// # Safety
///
/// `module` must be a live module.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_module_import_count(module: *const SinterWasmModule) -> usize {
    unsafe { &*module }.compiled.imports.len()
}

/// The number of exports of a module.
///
/// # Safety
///
/// `module` must be a live module.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_module_export_count(module: *const SinterWasmModule) -> usize {
    unsafe { &*module }.compiled.exports.len()
}

/// The facts of export `index` of a module, in the order of its export
/// section: its name, its kind (0 function, 1 memory, 2 table, 3
/// global), and, for a function, the codes of its parameter types and
/// of its result types (0 `i32`, 1 `i64`, 2 `f32`, 3 `f64`, 4 `v128`, 5
/// `funcref`, 6 `externref`). The pointers stay valid while the module
/// lives. Returns 0, or 2 when `index` is not less than the number of
/// exports.
///
/// # Safety
///
/// `module` must be a live module, and each out pointer must be valid
/// for a write.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_module_export(
    module: *const SinterWasmModule,
    index: usize,
    name: *mut *const u8,
    name_len: *mut usize,
    kind: *mut u32,
    params: *mut *const u8,
    params_len: *mut usize,
    results: *mut *const u8,
    results_len: *mut usize,
) -> i32 {
    let module = unsafe { &*module };
    match module.compiled.exports.get(index) {
        None => MISUSE,
        Some(export) => {
            unsafe {
                put(name, export.name.as_ptr());
                put(name_len, export.name.len());
                put(kind, export.kind);
                put(params, export.params.as_ptr());
                put(params_len, export.params.len());
                put(results, export.results.as_ptr());
                put(results_len, export.results.len());
            }
            DONE
        }
    }
}

/// The facts of import `index` of a module, in the order of its import
/// section: its module name and its name; its kind (as the kind of an
/// export); for a function, the codes of its parameter and result
/// types; for a memory or a table, its minimum, and its maximum when
/// `has_maximum` is 1; for a table, the code of the type of its
/// elements in `global_type`; for a global, the code of its value type,
/// and 1 in `mutable` when it is mutable. The pointers stay valid while the
/// module lives. Returns 0, or 2 when `index` is not less than the
/// number of imports.
///
/// # Safety
///
/// `module` must be a live module, and each out pointer must be valid
/// for a write.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_module_import(
    module: *const SinterWasmModule,
    index: usize,
    module_name: *mut *const u8,
    module_name_len: *mut usize,
    name: *mut *const u8,
    name_len: *mut usize,
    kind: *mut u32,
    params: *mut *const u8,
    params_len: *mut usize,
    results: *mut *const u8,
    results_len: *mut usize,
    minimum: *mut u64,
    maximum: *mut u64,
    has_maximum: *mut i32,
    global_type: *mut u8,
    mutable: *mut i32,
) -> i32 {
    let module = unsafe { &*module };
    match module.compiled.imports.get(index) {
        None => MISUSE,
        Some(import) => {
            unsafe {
                put(module_name, import.module.as_ptr());
                put(module_name_len, import.module.len());
                put(name, import.name.as_ptr());
                put(name_len, import.name.len());
                put(kind, import.kind);
                put(params, import.params.as_ptr());
                put(params_len, import.params.len());
                put(results, import.results.as_ptr());
                put(results_len, import.results.len());
                put(minimum, import.minimum);
                put(maximum, import.maximum.unwrap_or(0));
                put(has_maximum, i32::from(import.maximum.is_some()));
                put(global_type, import.global_type);
                put(mutable, i32::from(import.mutable));
            }
            DONE
        }
    }
}

/// Make a new store under `limits`, and an instance of `module` in it
/// with no import. Returns the instance, or null with the result code
/// in `code`: 1 when the instantiation failed, with the failure in
/// `failure`; 2 when the module has imports, with the message in
/// `failure`; 3 on an internal fault.
///
/// # Safety
///
/// `module` must be a live module; `code` and `failure` must be null or
/// valid for a write.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_instance_new(
    module: *const SinterWasmModule,
    limits: SinterWasmLimits,
    code: *mut i32,
    failure: *mut SinterWasmFailure,
) -> *mut SinterWasmInstance {
    let made = guard(None, move || {
        let compiled = &unsafe { &*module }.compiled;
        let limits = Limits {
            fuel: limits.fuel,
            memory: limits.memory,
            table: limits.table,
        };
        Some(Running::new(
            &compiled.module,
            compiled.native_stack,
            compiled.imports.len(),
            limits,
        ))
    });
    let (result, cause) = match made {
        Some(Ok(Ok(running))) => {
            return Box::into_raw(Box::new(SinterWasmInstance { running }));
        }
        Some(Ok(Err(cause))) => (FAILED, cause),
        Some(Err(Misuse(text))) => (
            MISUSE,
            Failure {
                code: FAILURE_FAULT,
                message: text,
            },
        ),
        None => (
            FAULT,
            Failure {
                code: FAILURE_FAULT,
                message: FAULT_MESSAGE.to_owned(),
            },
        ),
    };
    unsafe {
        put(code, result);
        put_failure(failure, cause);
    }
    std::ptr::null_mut()
}

/// Free an instance and its store.
///
/// # Safety
///
/// `instance` must be null, or an instance that was not freed before.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_instance_free(instance: *mut SinterWasmInstance) {
    guard((), move || {
        if !instance.is_null() {
            drop(unsafe { Box::from_raw(instance) });
        }
    })
}

/// Invoke the function export `name` of an instance with `arguments`.
/// `result_kind` is the result type of the function: 0 none, 1 `i32`,
/// 2 `i64`. Returns 0 with the result in `result` when the function has
/// one; 1 when the invocation failed, with the failure in `failure`; 2
/// when the instance exports no function of that name, or when the
/// arguments do not have its parameter types, or when its result types
/// are not those of `result_kind`, with the message in `failure`; 3 on
/// an internal fault.
///
/// # Safety
///
/// `instance` must be a live instance that no other thread uses;
/// `name` must be valid for `name_len` bytes and `arguments` for
/// `arguments_len` values; the out pointers must be null or valid for a
/// write.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_instance_invoke(
    instance: *mut SinterWasmInstance,
    name: *const u8,
    name_len: usize,
    arguments: *const SinterWasmValue,
    arguments_len: usize,
    result_kind: u32,
    result: *mut SinterWasmValue,
    failure: *mut SinterWasmFailure,
) -> i32 {
    let outcome = guard(None, move || {
        let running = &mut unsafe { &mut *instance }.running;
        let Some(name) = (unsafe { utf8(name, name_len) }) else {
            return Some(Err(Misuse("the name is not valid UTF-8".to_owned())));
        };
        let results: &[wasmtime::ValType] = match result_kind {
            0 => &[],
            1 => &[wasmtime::ValType::I32],
            2 => &[wasmtime::ValType::I64],
            _ => return Some(Err(Misuse("the result kind is unknown".to_owned()))),
        };
        let given: &[SinterWasmValue] = if arguments_len == 0 || arguments.is_null() {
            &[]
        } else {
            unsafe { std::slice::from_raw_parts(arguments, arguments_len) }
        };
        let values: Option<Vec<wasmtime::Val>> = given
            .iter()
            .map(|value| instance::value_of(value.kind, value.bits))
            .collect();
        let Some(values) = values else {
            return Some(Err(Misuse("an argument has an unknown kind".to_owned())));
        };
        let name = name.to_owned();
        Some(running.invoke(&name, &values, results))
    });
    match outcome {
        Some(Ok(Ok(value))) => {
            if let Some((kind, bits)) = value.as_ref().and_then(instance::bits_of) {
                unsafe { put(result, SinterWasmValue { kind, bits }) };
            }
            DONE
        }
        Some(Ok(Err(cause))) => {
            unsafe { put_failure(failure, cause) };
            FAILED
        }
        Some(Err(Misuse(text))) => {
            unsafe {
                put_failure(
                    failure,
                    Failure {
                        code: FAILURE_FAULT,
                        message: text,
                    },
                )
            };
            MISUSE
        }
        None => {
            unsafe {
                put_failure(
                    failure,
                    Failure {
                        code: FAILURE_FAULT,
                        message: FAULT_MESSAGE.to_owned(),
                    },
                )
            };
            FAULT
        }
    }
}

fn answer(outcome: Option<Result<(), Misuse>>, message: *mut SinterWasmBytes) -> i32 {
    match outcome {
        Some(Ok(())) => DONE,
        Some(Err(Misuse(text))) => {
            unsafe { put_message(message, &text) };
            MISUSE
        }
        None => {
            unsafe { put_message(message, FAULT_MESSAGE) };
            FAULT
        }
    }
}

/// # Safety
///
/// `data` must be valid for `len` bytes, or `len` must be 0.
unsafe fn memory_name<'a>(data: *const u8, len: usize) -> Result<&'a str, Misuse> {
    unsafe { utf8(data, len) }.ok_or_else(|| Misuse("the name is not valid UTF-8".to_owned()))
}

/// The number of bytes of the memory export `name` of an instance, in
/// `size`. Returns 0; 2 when the instance exports no memory of that
/// name, with the message in `message`; 3 on an internal fault.
///
/// # Safety
///
/// `instance` must be a live instance that no other thread uses;
/// `name` must be valid for `name_len` bytes; the out pointers must be
/// null or valid for a write.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_instance_memory_size(
    instance: *mut SinterWasmInstance,
    name: *const u8,
    name_len: usize,
    size: *mut u64,
    message: *mut SinterWasmBytes,
) -> i32 {
    let outcome = guard(None, move || {
        let running = &mut unsafe { &mut *instance }.running;
        Some(
            unsafe { memory_name(name, name_len) }
                .and_then(|name| running.memory_size(name))
                .map(|bytes| unsafe { put(size, bytes) }),
        )
    });
    answer(outcome, message)
}

/// Copy the `length` bytes from `address` of the memory export `name`
/// of an instance to `out`, or, when `out` is null, only check that
/// they lie inside that memory. Returns 0; 2 when the instance exports
/// no memory of that name or when the bytes do not lie inside it, with
/// the message in `message`; 3 on an internal fault.
///
/// # Safety
///
/// `instance` must be a live instance that no other thread uses;
/// `name` must be valid for `name_len` bytes; `out` must be null or
/// valid for `length` bytes; `message` must be null or valid for a
/// write.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_instance_read(
    instance: *mut SinterWasmInstance,
    name: *const u8,
    name_len: usize,
    address: u64,
    length: u64,
    out: *mut u8,
    message: *mut SinterWasmBytes,
) -> i32 {
    let outcome = guard(None, move || {
        let running = &mut unsafe { &mut *instance }.running;
        Some(unsafe { memory_name(name, name_len) }.and_then(|name| {
            if out.is_null() {
                running.check(name, address, length)
            } else {
                let length = usize::try_from(length)
                    .map_err(|_| Misuse("the length is too large".to_owned()))?;
                let target = unsafe { std::slice::from_raw_parts_mut(out, length) };
                running.read(name, address, target)
            }
        }))
    });
    answer(outcome, message)
}

/// Put the `len` bytes at `data` into the memory export `name` of an
/// instance, from `address` on. Returns 0; 2 when the instance exports
/// no memory of that name or when the bytes do not lie inside it, with
/// the message in `message`; 3 on an internal fault.
///
/// # Safety
///
/// `instance` must be a live instance that no other thread uses;
/// `name` must be valid for `name_len` bytes and `data` for `len`
/// bytes; `message` must be null or valid for a write.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_instance_write(
    instance: *mut SinterWasmInstance,
    name: *const u8,
    name_len: usize,
    address: u64,
    data: *const u8,
    len: usize,
    message: *mut SinterWasmBytes,
) -> i32 {
    let outcome = guard(None, move || {
        let running = &mut unsafe { &mut *instance }.running;
        Some(
            unsafe { memory_name(name, name_len) }
                .and_then(|name| running.write(name, address, unsafe { borrow(data, len) })),
        )
    });
    answer(outcome, message)
}

/// Make a new store of `engine` under `limits`, with no instance.
/// Returns null on an internal fault, with the message in `message`.
///
/// # Safety
///
/// `engine` must be a live engine; `message` must be null or valid for
/// a write.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_store_new(
    engine: *const SinterWasmEngine,
    limits: SinterWasmLimits,
    message: *mut SinterWasmBytes,
) -> *mut SinterWasmStore {
    let made = guard(Err(FAULT_MESSAGE.to_owned()), move || {
        let engine = unsafe { &*engine };
        Linked::new(
            &engine.engine,
            engine.native_stack,
            Limits {
                fuel: limits.fuel,
                memory: limits.memory,
                table: limits.table,
            },
        )
    });
    match made {
        Ok(linked) => Box::into_raw(Box::new(SinterWasmStore { linked })),
        Err(text) => {
            unsafe { put_message(message, &text) };
            std::ptr::null_mut()
        }
    }
}

/// Free a store, with its instances.
///
/// # Safety
///
/// `store` must be null, or a store that was not freed before.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_store_free(store: *mut SinterWasmStore) {
    guard((), move || {
        if !store.is_null() {
            drop(unsafe { Box::from_raw(store) });
        }
    })
}

/// # Safety
///
/// `failure` must be null or valid for a write.
unsafe fn report<T>(
    outcome: Option<Result<Result<T, Failure>, Misuse>>,
    failure: *mut SinterWasmFailure,
    done: impl FnOnce(T),
) -> i32 {
    match outcome {
        Some(Ok(Ok(value))) => {
            done(value);
            DONE
        }
        Some(Ok(Err(cause))) => {
            unsafe { put_failure(failure, cause) };
            FAILED
        }
        Some(Err(Misuse(text))) => {
            unsafe {
                put_failure(
                    failure,
                    Failure {
                        code: FAILURE_FAULT,
                        message: text,
                    },
                )
            };
            MISUSE
        }
        None => {
            unsafe {
                put_failure(
                    failure,
                    Failure {
                        code: FAILURE_FAULT,
                        message: FAULT_MESSAGE.to_owned(),
                    },
                )
            };
            FAULT
        }
    }
}

fn index_of(instance: u64) -> Result<usize, Misuse> {
    usize::try_from(instance).map_err(|_| Misuse("the store has no such instance".to_owned()))
}

/// Make an instance of `module` in a store, with the values of
/// `imports` for its imports, in their order. Returns 0 with the index
/// of the instance in `instance`; 1 when the instantiation failed, with
/// the failure in `failure`; 2 when the precondition does not hold,
/// with the message in `failure`; 3 on an internal fault.
///
/// # Safety
///
/// `store` must be a live store that no other thread uses; `module` a
/// live module; `imports` valid for `imports_len` values, each name
/// valid for its length; the out pointers null or valid for a write.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_store_instantiate(
    store: *mut SinterWasmStore,
    module: *const SinterWasmModule,
    imports: *const SinterWasmImport,
    imports_len: usize,
    instance: *mut u64,
    failure: *mut SinterWasmFailure,
) -> i32 {
    let outcome = guard(None, move || {
        let linked = &mut unsafe { &mut *store }.linked;
        let compiled = &unsafe { &*module }.compiled;
        let given: &[SinterWasmImport] = if imports_len == 0 || imports.is_null() {
            &[]
        } else {
            unsafe { std::slice::from_raw_parts(imports, imports_len) }
        };
        let mut sources = Vec::with_capacity(given.len());
        for import in given {
            let source = match import.kind {
                0 => {
                    let Some(name) = (unsafe { utf8(import.name, import.name_len) }) else {
                        return Some(Err(Misuse("the name is not valid UTF-8".to_owned())));
                    };
                    match index_of(import.instance) {
                        Ok(index) => Source::Export(index, name.to_owned()),
                        Err(misuse) => return Some(Err(misuse)),
                    }
                }
                1 => Source::Global(import.mutable != 0, import.value),
                2 => Source::Trap,
                _ => return Some(Err(Misuse("an import has an unknown kind".to_owned()))),
            };
            sources.push(source);
        }
        Some(linked.instantiate(&compiled.module, &sources))
    });
    unsafe { report(outcome, failure, |index| put(instance, index as u64)) }
}

/// Invoke the function export `name` of the instance `instance` of a
/// store, as `sinter_wasm_instance_invoke` does.
///
/// # Safety
///
/// As `sinter_wasm_instance_invoke`, with `store` a live store that no
/// other thread uses.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_store_invoke(
    store: *mut SinterWasmStore,
    instance: u64,
    name: *const u8,
    name_len: usize,
    arguments: *const SinterWasmValue,
    arguments_len: usize,
    result_kind: u32,
    result: *mut SinterWasmValue,
    failure: *mut SinterWasmFailure,
) -> i32 {
    let outcome = guard(None, move || {
        let linked = &mut unsafe { &mut *store }.linked;
        let Some(name) = (unsafe { utf8(name, name_len) }) else {
            return Some(Err(Misuse("the name is not valid UTF-8".to_owned())));
        };
        let results: &[wasmtime::ValType] = match result_kind {
            0 => &[],
            1 => &[wasmtime::ValType::I32],
            2 => &[wasmtime::ValType::I64],
            _ => return Some(Err(Misuse("the result kind is unknown".to_owned()))),
        };
        let given: &[SinterWasmValue] = if arguments_len == 0 || arguments.is_null() {
            &[]
        } else {
            unsafe { std::slice::from_raw_parts(arguments, arguments_len) }
        };
        let values: Option<Vec<wasmtime::Val>> = given
            .iter()
            .map(|value| instance::value_of(value.kind, value.bits))
            .collect();
        let Some(values) = values else {
            return Some(Err(Misuse("an argument has an unknown kind".to_owned())));
        };
        let index = match index_of(instance) {
            Ok(index) => index,
            Err(misuse) => return Some(Err(misuse)),
        };
        let name = name.to_owned();
        Some(linked.invoke(index, &name, &values, results))
    });
    unsafe {
        report(outcome, failure, |value: Option<wasmtime::Val>| {
            if let Some((kind, bits)) = value.as_ref().and_then(instance::bits_of) {
                put(result, SinterWasmValue { kind, bits });
            }
        })
    }
}

/// Grow the memory (`part` 0) or the table (`part` 1) export `name` of
/// the instance `instance` of a store by `delta` pages or elements.
/// Returns 0 with the size before in `previous`; 1 when the growth
/// stopped, with the failure in `failure`; 2 when the precondition does
/// not hold, with the message in `failure`; 3 on an internal fault.
///
/// # Safety
///
/// `store` must be a live store that no other thread uses; `name` must
/// be valid for `name_len` bytes; the out pointers must be null or
/// valid for a write.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_store_grow(
    store: *mut SinterWasmStore,
    instance: u64,
    part: u32,
    name: *const u8,
    name_len: usize,
    delta: u64,
    previous: *mut u64,
    failure: *mut SinterWasmFailure,
) -> i32 {
    let outcome = guard(None, move || {
        let linked = &mut unsafe { &mut *store }.linked;
        let result = (|| {
            let name = unsafe { memory_name(name, name_len) }?;
            let index = index_of(instance)?;
            let part = match part {
                0 => Part::Memory,
                1 => Part::Table,
                _ => return Err(Misuse("the part is unknown".to_owned())),
            };
            linked.grow(index, part, name, delta)
        })();
        Some(result)
    });
    unsafe { report(outcome, failure, |size| put(previous, size)) }
}

/// The number of bytes of the memory export `name` of the instance
/// `instance` of a store, in `size`, as
/// `sinter_wasm_instance_memory_size` gives it.
///
/// # Safety
///
/// As `sinter_wasm_instance_memory_size`, with `store` a live store
/// that no other thread uses.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_store_memory_size(
    store: *mut SinterWasmStore,
    instance: u64,
    name: *const u8,
    name_len: usize,
    size: *mut u64,
    message: *mut SinterWasmBytes,
) -> i32 {
    let outcome = guard(None, move || {
        let linked = &mut unsafe { &mut *store }.linked;
        Some(
            unsafe { memory_name(name, name_len) }
                .and_then(|name| linked.memory_size(index_of(instance)?, name))
                .map(|bytes| unsafe { put(size, bytes) }),
        )
    });
    answer(outcome, message)
}

/// Copy bytes of the memory export `name` of the instance `instance` of
/// a store, or check them, as `sinter_wasm_instance_read` does.
///
/// # Safety
///
/// As `sinter_wasm_instance_read`, with `store` a live store that no
/// other thread uses.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_store_read(
    store: *mut SinterWasmStore,
    instance: u64,
    name: *const u8,
    name_len: usize,
    address: u64,
    length: u64,
    out: *mut u8,
    message: *mut SinterWasmBytes,
) -> i32 {
    let outcome = guard(None, move || {
        let linked = &mut unsafe { &mut *store }.linked;
        Some(unsafe { memory_name(name, name_len) }.and_then(|name| {
            let index = index_of(instance)?;
            if out.is_null() {
                linked.check(index, name, address, length)
            } else {
                let length = usize::try_from(length)
                    .map_err(|_| Misuse("the length is too large".to_owned()))?;
                let target = unsafe { std::slice::from_raw_parts_mut(out, length) };
                linked.read(index, name, address, target)
            }
        }))
    });
    answer(outcome, message)
}

/// Put bytes into the memory export `name` of the instance `instance`
/// of a store, as `sinter_wasm_instance_write` does.
///
/// # Safety
///
/// As `sinter_wasm_instance_write`, with `store` a live store that no
/// other thread uses.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn sinter_wasm_store_write(
    store: *mut SinterWasmStore,
    instance: u64,
    name: *const u8,
    name_len: usize,
    address: u64,
    data: *const u8,
    len: usize,
    message: *mut SinterWasmBytes,
) -> i32 {
    let outcome = guard(None, move || {
        let linked = &mut unsafe { &mut *store }.linked;
        Some(unsafe { memory_name(name, name_len) }.and_then(|name| {
            linked.write(index_of(instance)?, name, address, unsafe {
                borrow(data, len)
            })
        }))
    });
    answer(outcome, message)
}
