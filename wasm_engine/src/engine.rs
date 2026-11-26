// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 The Sinter Authors

//! The engine of exactly WebAssembly Core 2.0, and the modules that it
//! compiles, with the facts of their imports and exports.

use wasmtime::{Config, Engine, ExternType, Module, ValType, WasmFeatures};

/// The code of an export that is a function.
pub(crate) const KIND_FUNCTION: u32 = 0;
/// The code of an export that is a memory.
pub(crate) const KIND_MEMORY: u32 = 1;
/// The code of an export that is a table.
pub(crate) const KIND_TABLE: u32 = 2;
/// The code of an export that is a global.
pub(crate) const KIND_GLOBAL: u32 = 3;

/// The bytes of native stack that the code of the engine needs on a
/// thread beside the call stack of WebAssembly code.
const HOST_MARGIN: usize = 1 << 20;

/// The least bytes of native stack of the thread of a compilation.
const COMPILE_STACK: usize = 8 << 20;

/// Run `body` on a new thread with `stack` bytes of native stack, and
/// give its value. It is `None` when the thread cannot start or when
/// `body` panics.
pub(crate) fn on_thread<T: Send>(stack: usize, body: impl FnOnce() -> T + Send) -> Option<T> {
    std::thread::scope(|scope| {
        std::thread::Builder::new()
            .stack_size(stack)
            .spawn_scoped(scope, body)
            .ok()?
            .join()
            .ok()
    })
}

/// The bytes of native stack of a thread that runs WebAssembly code
/// with `stack` bytes of call stack.
pub(crate) fn native_stack(stack: usize) -> Option<usize> {
    stack.checked_add(HOST_MARGIN)
}

/// Make an engine that compiles and runs exactly the modules of
/// WebAssembly Core 2.0, with fuel, and with `stack` bytes for the
/// call stack of WebAssembly code.
pub(crate) fn new_engine(stack: usize) -> wasmtime::Result<Engine> {
    let mut config = Config::new();
    config.wasm_features(WasmFeatures::all().difference(WasmFeatures::WASM2), false);
    config.wasm_features(WasmFeatures::WASM2, true);
    config.consume_fuel(true);
    config.max_wasm_stack(stack);
    config.wasm_backtrace_max_frames(None);
    config.macos_use_mach_ports(false);
    Engine::new(&config)
}

/// The facts of one export of a module.
pub(crate) struct Export {
    pub(crate) name: String,
    pub(crate) kind: u32,
    pub(crate) params: Vec<u8>,
    pub(crate) results: Vec<u8>,
}

/// The facts of one import of a module: its module name, its name, its
/// kind (as the kind of an export), the codes of the parameter and the
/// result types of a function, the limits of a memory or a table, the
/// code of the value type of a global or of the elements of a table,
/// and the mutability of a global.
pub(crate) struct Import {
    pub(crate) module: String,
    pub(crate) name: String,
    pub(crate) kind: u32,
    pub(crate) params: Vec<u8>,
    pub(crate) results: Vec<u8>,
    pub(crate) minimum: u64,
    pub(crate) maximum: Option<u64>,
    pub(crate) global_type: u8,
    pub(crate) mutable: bool,
}

/// A compiled module, with the facts of its imports, in the order of
/// its import section, and of its exports, in the order of its export
/// section.
pub(crate) struct Compiled {
    pub(crate) module: Module,
    pub(crate) native_stack: usize,
    pub(crate) imports: Vec<Import>,
    pub(crate) exports: Vec<Export>,
}

/// The code of a value type: 0 `i32`, 1 `i64`, 2 `f32`, 3 `f64`, 4
/// `v128`, 5 `funcref`, 6 `externref`. Any other type has no code.
fn type_code(value_type: &ValType) -> Option<u8> {
    match value_type {
        ValType::I32 => Some(0),
        ValType::I64 => Some(1),
        ValType::F32 => Some(2),
        ValType::F64 => Some(3),
        ValType::V128 => Some(4),
        other if other.is_funcref() => Some(5),
        other if other.is_externref() => Some(6),
        _ => None,
    }
}

fn type_codes(types: impl Iterator<Item = ValType>) -> Option<Vec<u8>> {
    types.map(|value_type| type_code(&value_type)).collect()
}

fn export_facts(module: &Module) -> Result<Vec<Export>, String> {
    let mut exports = Vec::new();
    for export in module.exports() {
        let name = export.name().to_owned();
        let facts = match export.ty() {
            ExternType::Func(function) => {
                match (
                    type_codes(function.params()),
                    type_codes(function.results()),
                ) {
                    (Some(params), Some(results)) => Export {
                        name,
                        kind: KIND_FUNCTION,
                        params,
                        results,
                    },
                    _ => {
                        return Err(format!(
                            "the export {name} has a type that WebAssembly Core 2.0 does not have"
                        ));
                    }
                }
            }
            ExternType::Memory(_) => Export {
                name,
                kind: KIND_MEMORY,
                params: Vec::new(),
                results: Vec::new(),
            },
            ExternType::Table(_) => Export {
                name,
                kind: KIND_TABLE,
                params: Vec::new(),
                results: Vec::new(),
            },
            ExternType::Global(_) => Export {
                name,
                kind: KIND_GLOBAL,
                params: Vec::new(),
                results: Vec::new(),
            },
            ExternType::Tag(_) => {
                return Err(format!(
                    "the export {name} is a tag, which WebAssembly Core 2.0 does not have"
                ));
            }
        };
        exports.push(facts);
    }
    Ok(exports)
}

fn import_facts(module: &Module) -> Result<Vec<Import>, String> {
    let mut imports = Vec::new();
    for import in module.imports() {
        let mut facts = Import {
            module: import.module().to_owned(),
            name: import.name().to_owned(),
            kind: KIND_FUNCTION,
            params: Vec::new(),
            results: Vec::new(),
            minimum: 0,
            maximum: None,
            global_type: 0,
            mutable: false,
        };
        let name = import.name();
        match import.ty() {
            ExternType::Func(function) => {
                match (
                    type_codes(function.params()),
                    type_codes(function.results()),
                ) {
                    (Some(params), Some(results)) => {
                        facts.params = params;
                        facts.results = results;
                    }
                    _ => {
                        return Err(format!(
                            "the import {name} has a type that WebAssembly Core 2.0 does not have"
                        ));
                    }
                }
            }
            ExternType::Memory(memory) => {
                facts.kind = KIND_MEMORY;
                facts.minimum = memory.minimum();
                facts.maximum = memory.maximum();
            }
            ExternType::Table(table) => {
                facts.kind = KIND_TABLE;
                facts.global_type = if table.element().heap_type().is_func() {
                    5
                } else {
                    6
                };
                facts.minimum = table.minimum();
                facts.maximum = table.maximum();
            }
            ExternType::Global(global) => {
                facts.kind = KIND_GLOBAL;
                facts.global_type = type_code(global.content()).ok_or_else(|| {
                    format!("the import {name} has a type that WebAssembly Core 2.0 does not have")
                })?;
                facts.mutable = global.mutability() == wasmtime::Mutability::Var;
            }
            ExternType::Tag(_) => {
                return Err(format!(
                    "the import {name} is a tag, which WebAssembly Core 2.0 does not have"
                ));
            }
        }
        imports.push(facts);
    }
    Ok(imports)
}

/// Compile `bytes` as a module of WebAssembly Core 2.0, on a thread of
/// its own. The error is the message of the engine.
pub(crate) fn compile(
    engine: &Engine,
    native_stack: usize,
    bytes: Vec<u8>,
) -> Result<Compiled, String> {
    let module = on_thread(native_stack.max(COMPILE_STACK), || {
        Module::new(engine, &bytes).map_err(|error| format!("{error:#}"))
    })
    .unwrap_or_else(|| {
        Err("the engine could not start a thread to compile the module".to_owned())
    })?;
    let exports = export_facts(&module)?;
    let imports = import_facts(&module)?;
    Ok(Compiled {
        module,
        native_stack,
        imports,
        exports,
    })
}
