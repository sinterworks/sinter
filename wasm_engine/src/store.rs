// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 The Sinter Authors

//! Stores that hold several instances, linked by their imports, under
//! limits of fuel, memory, and table elements.

use wasmtime::{
    Engine, Extern, ExternType, Func, Global, GlobalType, Instance, Module, Mutability, Ref, Store,
    Val, ValType,
};

use crate::engine::on_thread;
use crate::instance::{
    FAILURE_FAULT, Failure, HostTrap, Limits, Misuse, Usage, call, failure, no_thread, range, read,
    write,
};

/// Where the value of an import comes from.
pub(crate) enum Source {
    /// The export of this name of the instance at this index.
    Export(usize, String),
    /// A new global of the type `i32`: mutable or not, and its value.
    Global(bool, i32),
    /// A new function of the type of the import that traps.
    Trap,
}

/// A store of several instances, with the bytes of native stack of
/// each thread that runs their code.
pub(crate) struct Linked {
    store: Store<Usage>,
    instances: Vec<Instance>,
    native_stack: usize,
}

/// What a growth grows.
pub(crate) enum Part {
    Memory,
    Table,
}

impl Linked {
    /// Make a new store of `engine` under `limits`, with no instance.
    pub(crate) fn new(
        engine: &Engine,
        native_stack: usize,
        limits: Limits,
    ) -> Result<Linked, String> {
        let mut store = Store::new(engine, Usage::new(limits, true));
        store.limiter(|usage| usage);
        store
            .set_fuel(limits.fuel)
            .map_err(|error| format!("{error:#}"))?;
        Ok(Linked {
            store,
            instances: Vec::new(),
            native_stack,
        })
    }

    fn instance(&self, index: usize) -> Result<Instance, Misuse> {
        self.instances
            .get(index)
            .copied()
            .ok_or_else(|| Misuse("the store has no such instance".to_owned()))
    }

    fn value(
        &mut self,
        source: &Source,
        ty: ExternType,
    ) -> Result<Result<Extern, Failure>, Misuse> {
        Ok(match source {
            Source::Export(index, name) => {
                let instance = self.instance(*index)?;
                let found = instance
                    .get_export(&mut self.store, name)
                    .ok_or_else(|| Misuse(format!("the instance exports no {name}")))?;
                Ok(found)
            }
            Source::Global(mutable, value) => {
                let mutability = if *mutable {
                    Mutability::Var
                } else {
                    Mutability::Const
                };
                Global::new(
                    &mut self.store,
                    GlobalType::new(ValType::I32, mutability),
                    Val::I32(*value),
                )
                .map(Extern::from)
                .map_err(|error| fault(format!("{error:#}")))
            }
            Source::Trap => match ty {
                ExternType::Func(function_type) => {
                    Ok(Func::new(&mut self.store, function_type, |_, _, _| {
                        Err(wasmtime::Error::new(HostTrap))
                    })
                    .into())
                }
                _ => Err(fault(
                    "a function that traps is the value of an import that is not a function"
                        .to_owned(),
                )),
            },
        })
    }

    /// Make an instance of `module` in the store, with the values of
    /// `sources` for its imports, in their order. Gives the index of
    /// the instance.
    pub(crate) fn instantiate(
        &mut self,
        module: &Module,
        sources: &[Source],
    ) -> Result<Result<usize, Failure>, Misuse> {
        if !Engine::same(module.engine(), self.store.engine()) {
            return Err(Misuse(
                "the module is not a module of the engine of the store".to_owned(),
            ));
        }
        let types: Vec<ExternType> = module.imports().map(|import| import.ty()).collect();
        if types.len() != sources.len() {
            return Err(Misuse(
                "the number of imports is not the number of the imports of the module".to_owned(),
            ));
        }
        let mut values = Vec::with_capacity(sources.len());
        for (source, ty) in sources.iter().zip(types) {
            match self.value(source, ty)? {
                Ok(value) => values.push(value),
                Err(cause) => return Ok(Err(cause)),
            }
        }
        self.store.data_mut().start_use();
        let store = &mut self.store;
        let made = on_thread(self.native_stack, || {
            Instance::new(&mut *store, module, &values)
        });
        Ok(match made {
            None => Err(no_thread()),
            Some(Ok(instance)) => {
                self.instances.push(instance);
                Ok(self.instances.len() - 1)
            }
            Some(Err(error)) => Err(failure(&self.store, error)),
        })
    }

    /// Invoke the function export `name` of the instance at `index`.
    pub(crate) fn invoke(
        &mut self,
        index: usize,
        name: &str,
        arguments: &[Val],
        results: &[ValType],
    ) -> Result<Result<Option<Val>, Failure>, Misuse> {
        let instance = self.instance(index)?;
        let function = instance
            .get_func(&mut self.store, name)
            .ok_or_else(|| Misuse(format!("the instance exports no function {name}")))?;
        self.store.data_mut().start_use();
        call(
            &mut self.store,
            function,
            name,
            arguments,
            results,
            self.native_stack,
        )
    }

    fn memory(&mut self, index: usize, name: &str) -> Result<wasmtime::Memory, Misuse> {
        self.instance(index)?
            .get_memory(&mut self.store, name)
            .ok_or_else(|| Misuse(format!("the instance exports no memory {name}")))
    }

    /// Grow the memory or the table export `name` of the instance at
    /// `index` by `delta` pages or elements. Gives its size before.
    pub(crate) fn grow(
        &mut self,
        index: usize,
        part: Part,
        name: &str,
        delta: u64,
    ) -> Result<Result<u64, Failure>, Misuse> {
        self.store.data_mut().start_use();
        let grown = match part {
            Part::Memory => {
                let memory = self.memory(index, name)?;
                memory.grow(&mut self.store, delta)
            }
            Part::Table => {
                let table = self
                    .instance(index)?
                    .get_table(&mut self.store, name)
                    .ok_or_else(|| Misuse(format!("the instance exports no table {name}")))?;
                if !table.ty(&self.store).element().heap_type().is_func() {
                    return Err(Misuse(format!("the table {name} does not hold functions")));
                }
                table.grow(&mut self.store, delta, Ref::Func(None))
            }
        };
        Ok(grown.map_err(|error| failure(&self.store, error)))
    }

    /// The number of bytes of the memory export `name` of the instance
    /// at `index`.
    pub(crate) fn memory_size(&mut self, index: usize, name: &str) -> Result<u64, Misuse> {
        let memory = self.memory(index, name)?;
        Ok(memory.data_size(&self.store) as u64)
    }

    /// Check that the `length` bytes from `address` lie inside the
    /// memory export `name` of the instance at `index`.
    pub(crate) fn check(
        &mut self,
        index: usize,
        name: &str,
        address: u64,
        length: u64,
    ) -> Result<(), Misuse> {
        let memory = self.memory(index, name)?;
        range(&self.store, memory, name, address, length).map(|_| ())
    }

    /// Copy the `out.len()` bytes from `address` of the memory export
    /// `name` of the instance at `index` into `out`.
    pub(crate) fn read(
        &mut self,
        index: usize,
        name: &str,
        address: u64,
        out: &mut [u8],
    ) -> Result<(), Misuse> {
        let memory = self.memory(index, name)?;
        read(&self.store, memory, name, address, out)
    }

    /// Put `bytes` into the memory export `name` of the instance at
    /// `index`, from `address` on.
    pub(crate) fn write(
        &mut self,
        index: usize,
        name: &str,
        address: u64,
        bytes: &[u8],
    ) -> Result<(), Misuse> {
        let memory = self.memory(index, name)?;
        write(&mut self.store, memory, name, address, bytes)
    }
}

fn fault(message: String) -> Failure {
    Failure {
        code: FAILURE_FAULT,
        message,
    }
}
