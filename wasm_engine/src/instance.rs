// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 The Sinter Authors

//! Instances of a module, each in a new store with no import, under
//! limits of fuel, memory, and table elements.

use wasmtime::{Instance, Module, ResourceLimiter, Store, Trap, Val, ValType};

use crate::engine::on_thread;

/// The code of a failure: the code trapped. The failure has a message.
pub(crate) const FAILURE_TRAP: u32 = 0;
/// The code of a failure: the code exhausted the call stack.
pub(crate) const FAILURE_STACK: u32 = 1;
/// The code of a failure: the engine stopped the code at the limit of
/// fuel.
pub(crate) const FAILURE_FUEL: u32 = 2;
/// The code of a failure: the engine stopped the code at the limit of
/// memory.
pub(crate) const FAILURE_MEMORY: u32 = 3;
/// The code of a failure: the engine stopped the code at the limit of
/// table elements.
pub(crate) const FAILURE_TABLE: u32 = 4;
/// The code of a failure: the engine could not run the code. The
/// failure has a message.
pub(crate) const FAILURE_FAULT: u32 = 5;

/// The maximum of a memory whose memory type gives none: 65,536 pages
/// of 65,536 bytes.
const MEMORY_MAXIMUM: usize = 1 << 32;
/// The maximum of a table whose table type gives none.
const TABLE_MAXIMUM: usize = u32::MAX as usize;

/// Why an instantiation or an invocation failed.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Failure {
    pub(crate) code: u32,
    pub(crate) message: String,
}

impl Failure {
    fn new(code: u32) -> Failure {
        Failure {
            code,
            message: String::new(),
        }
    }
}

/// A use of an instance that its precondition does not allow.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Misuse(pub(crate) String);

/// The limits of one instance.
#[derive(Debug, Clone, Copy)]
pub(crate) struct Limits {
    pub(crate) fuel: u64,
    pub(crate) memory: u64,
    pub(crate) table: u64,
}

struct Usage {
    memory_limit: usize,
    table_limit: usize,
    memory_total: usize,
    memory_growth: usize,
    table_total: usize,
    table_growth: usize,
    stopped: Option<u32>,
}

impl ResourceLimiter for Usage {
    fn memory_growing(
        &mut self,
        current: usize,
        desired: usize,
        maximum: Option<usize>,
    ) -> wasmtime::Result<bool> {
        if desired > maximum.unwrap_or(MEMORY_MAXIMUM) {
            return Ok(false);
        }
        let growth = desired.saturating_sub(current);
        let total = self.memory_total.saturating_add(growth);
        if total > self.memory_limit {
            self.stopped = Some(FAILURE_MEMORY);
            return Err(wasmtime::Error::msg("the memory limit of the instance"));
        }
        self.memory_total = total;
        self.memory_growth = growth;
        Ok(true)
    }

    fn memory_grow_failed(&mut self, _error: wasmtime::Error) -> wasmtime::Result<()> {
        self.memory_total -= self.memory_growth;
        self.memory_growth = 0;
        Ok(())
    }

    fn table_growing(
        &mut self,
        current: usize,
        desired: usize,
        maximum: Option<usize>,
    ) -> wasmtime::Result<bool> {
        if desired > maximum.unwrap_or(TABLE_MAXIMUM) {
            return Ok(false);
        }
        let growth = desired.saturating_sub(current);
        let total = self.table_total.saturating_add(growth);
        if total > self.table_limit {
            self.stopped = Some(FAILURE_TABLE);
            return Err(wasmtime::Error::msg("the table limit of the instance"));
        }
        self.table_total = total;
        self.table_growth = growth;
        Ok(true)
    }

    fn table_grow_failed(&mut self, _error: wasmtime::Error) -> wasmtime::Result<()> {
        self.table_total -= self.table_growth;
        self.table_growth = 0;
        Ok(())
    }
}

/// An instance of a module in a store of its own, with the bytes of
/// native stack of each thread that runs its code.
pub(crate) struct Running {
    store: Store<Usage>,
    instance: Instance,
    native_stack: usize,
}

fn no_thread() -> Failure {
    Failure {
        code: FAILURE_FAULT,
        message: "the engine could not run the code on a thread of its own".to_owned(),
    }
}

fn failure(store: &Store<Usage>, error: wasmtime::Error) -> Failure {
    if let Some(code) = store.data().stopped {
        return Failure::new(code);
    }
    match error.downcast_ref::<Trap>() {
        Some(Trap::OutOfFuel) => Failure::new(FAILURE_FUEL),
        Some(Trap::StackOverflow) => Failure::new(FAILURE_STACK),
        Some(trap) => Failure {
            code: FAILURE_TRAP,
            message: trap.to_string(),
        },
        None => Failure {
            code: FAILURE_FAULT,
            message: format!("{error:#}"),
        },
    }
}

fn size(limit: u64) -> usize {
    usize::try_from(limit).unwrap_or(usize::MAX)
}

/// The value of a C value: kind 0 is `i32`, kind 1 is `i64`.
pub(crate) fn value_of(kind: u32, bits: u64) -> Option<Val> {
    match kind {
        0 => Some(Val::I32(bits as u32 as i32)),
        1 => Some(Val::I64(bits as i64)),
        _ => None,
    }
}

/// The kind and the bits of a value of type `i32` or `i64`.
pub(crate) fn bits_of(value: &Val) -> Option<(u32, u64)> {
    match value {
        Val::I32(number) => Some((0, *number as u32 as u64)),
        Val::I64(number) => Some((1, *number as u64)),
        _ => None,
    }
}

fn same_kind(value: &Val, value_type: &ValType) -> bool {
    matches!(
        (value, value_type),
        (Val::I32(_), ValType::I32) | (Val::I64(_), ValType::I64)
    )
}

impl Running {
    /// Make a new store under `limits`, and an instance of `module` in
    /// it with no import.
    pub(crate) fn new(
        module: &Module,
        native_stack: usize,
        imports: usize,
        limits: Limits,
    ) -> Result<Result<Running, Failure>, Misuse> {
        if imports > 0 {
            return Err(Misuse("the module has imports".to_owned()));
        }
        let usage = Usage {
            memory_limit: size(limits.memory),
            table_limit: size(limits.table),
            memory_total: 0,
            memory_growth: 0,
            table_total: 0,
            table_growth: 0,
            stopped: None,
        };
        let mut store = Store::new(module.engine(), usage);
        store.limiter(|usage| usage);
        if let Err(error) = store.set_fuel(limits.fuel) {
            return Ok(Err(Failure {
                code: FAILURE_FAULT,
                message: format!("{error:#}"),
            }));
        }
        let made = on_thread(native_stack, || {
            let instance = Instance::new(&mut store, module, &[]);
            (store, instance)
        });
        Ok(match made {
            None => Err(no_thread()),
            Some((store, Ok(instance))) => Ok(Running {
                store,
                instance,
                native_stack,
            }),
            Some((store, Err(error))) => Err(failure(&store, error)),
        })
    }

    /// Invoke the export `name`, a function whose parameter types are
    /// those of `arguments`, and whose result types are `results`: no
    /// type, or one `i32` or `i64`.
    pub(crate) fn invoke(
        &mut self,
        name: &str,
        arguments: &[Val],
        results: &[ValType],
    ) -> Result<Result<Option<Val>, Failure>, Misuse> {
        self.store.data_mut().stopped = None;
        let function = self
            .instance
            .get_func(&mut self.store, name)
            .ok_or_else(|| Misuse(format!("the instance exports no function {name}")))?;
        let function_type = function.ty(&self.store);
        let params: Vec<ValType> = function_type.params().collect();
        if params.len() != arguments.len()
            || !arguments
                .iter()
                .zip(&params)
                .all(|(value, value_type)| same_kind(value, value_type))
        {
            return Err(Misuse(format!(
                "the arguments do not have the parameter types of {name}"
            )));
        }
        let found: Vec<ValType> = function_type.results().collect();
        if found.len() != results.len()
            || !found
                .iter()
                .zip(results)
                .all(|(found, wanted)| ValType::eq(found, wanted))
        {
            return Err(Misuse(format!(
                "the result types of {name} are not those that the caller wants"
            )));
        }
        let mut values: Vec<Val> = results
            .iter()
            .map(|value_type| match value_type {
                ValType::I64 => Val::I64(0),
                _ => Val::I32(0),
            })
            .collect();
        let store = &mut self.store;
        let called = on_thread(self.native_stack, || {
            function
                .call(&mut *store, arguments, &mut values)
                .map(|()| values)
        });
        Ok(match called {
            None => Err(no_thread()),
            Some(Ok(mut values)) => Ok(values.pop()),
            Some(Err(error)) => Err(failure(&self.store, error)),
        })
    }

    fn memory(&mut self, name: &str) -> Result<wasmtime::Memory, Misuse> {
        self.instance
            .get_memory(&mut self.store, name)
            .ok_or_else(|| Misuse(format!("the instance exports no memory {name}")))
    }

    /// The number of bytes of the memory export `name`.
    pub(crate) fn memory_size(&mut self, name: &str) -> Result<u64, Misuse> {
        let memory = self.memory(name)?;
        Ok(memory.data_size(&self.store) as u64)
    }

    fn range(
        &mut self,
        name: &str,
        address: u64,
        length: u64,
    ) -> Result<(wasmtime::Memory, usize, usize), Misuse> {
        let memory = self.memory(name)?;
        let size = memory.data_size(&self.store) as u64;
        match address.checked_add(length) {
            Some(end) if end <= size => Ok((memory, address as usize, end as usize)),
            _ => Err(Misuse(format!(
                "the bytes from {address} to {address} + {length} do not lie inside the memory {name}"
            ))),
        }
    }

    /// Check that the `length` bytes from `address` lie inside the
    /// memory export `name`.
    pub(crate) fn check(&mut self, name: &str, address: u64, length: u64) -> Result<(), Misuse> {
        self.range(name, address, length).map(|_| ())
    }

    /// Copy the `out.len()` bytes from `address` of the memory export
    /// `name` into `out`.
    pub(crate) fn read(&mut self, name: &str, address: u64, out: &mut [u8]) -> Result<(), Misuse> {
        let (memory, start, end) = self.range(name, address, out.len() as u64)?;
        out.copy_from_slice(&memory.data(&self.store)[start..end]);
        Ok(())
    }

    /// Put `bytes` into the memory export `name` from `address` on.
    pub(crate) fn write(&mut self, name: &str, address: u64, bytes: &[u8]) -> Result<(), Misuse> {
        let (memory, start, end) = self.range(name, address, bytes.len() as u64)?;
        memory.data_mut(&mut self.store)[start..end].copy_from_slice(bytes);
        Ok(())
    }
}
