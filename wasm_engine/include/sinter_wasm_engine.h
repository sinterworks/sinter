/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 The Sinter Authors */

/* The C interface of the Sinter WebAssembly engine.

   An engine compiles and runs exactly the modules of the WebAssembly
   Core Specification 2.0. A module gives the number of its imports and
   the facts of its exports. An instance of a module lives in a new
   store of its own, has no import, and runs under limits of fuel,
   memory, and table elements.

   A handle is an engine, a module, or an instance. Each handle owns
   what it needs, so the handles can be freed in any order. One thread
   at a time may use one instance. */

#ifndef SINTER_WASM_ENGINE_H
#define SINTER_WASM_ENGINE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* An engine of exactly WebAssembly Core 2.0. */
typedef struct SinterWasmEngine sinter_wasm_engine;

/* A compiled module. */
typedef struct SinterWasmModule sinter_wasm_module;

/* An instance of a module in a store of its own. */
typedef struct SinterWasmInstance sinter_wasm_instance;

/* A store of several instances, linked by their imports. */
typedef struct SinterWasmStore sinter_wasm_store;

/* A byte sequence that the engine owns. Free it with
   sinter_wasm_bytes_free. data is NULL when len is 0. */
typedef struct sinter_wasm_bytes {
  uint8_t *data;
  size_t len;
} sinter_wasm_bytes;

/* The codes of a failure of an instantiation or an invocation. */
#define SINTER_WASM_FAILURE_TRAP 0   /* the code trapped; with a message */
#define SINTER_WASM_FAILURE_STACK 1  /* the code exhausted the call stack */
#define SINTER_WASM_FAILURE_FUEL 2   /* stopped at the limit of fuel */
#define SINTER_WASM_FAILURE_MEMORY 3 /* stopped at the limit of memory */
#define SINTER_WASM_FAILURE_TABLE 4  /* stopped at the limit of table elements */
#define SINTER_WASM_FAILURE_FAULT 5  /* the engine could not run the code; with a message */

/* A failure: its code, and its message, which is empty for the codes
   that have none. */
typedef struct sinter_wasm_failure {
  uint32_t code;
  sinter_wasm_bytes message;
} sinter_wasm_failure;

/* A value of type i32 (kind 0) or i64 (kind 1), as its bits. */
typedef struct sinter_wasm_value {
  uint32_t kind;
  uint64_t bits;
} sinter_wasm_value;

/* The limits of one instance. */
typedef struct sinter_wasm_limits {
  /* The units of fuel for the instantiation and all invocations. */
  uint64_t fuel;
  /* The most bytes that the memories of the instance hold together. */
  uint64_t memory;
  /* The most elements that the tables of the instance hold together. */
  uint64_t table;
} sinter_wasm_limits;

/* The value of one import of an instance in a store. kind 0: the
   export name of the instance instance of the store; kind 1: a new
   global of type i32, mutable when mutable_ is not 0, with value; kind
   2: a new function of the type of the import that traps. */
typedef struct sinter_wasm_import {
  uint32_t kind;
  uint64_t instance;
  const uint8_t *name;
  size_t name_len;
  int32_t mutable_;
  int32_t value;
} sinter_wasm_import;

/* The result codes of the functions that return int32_t. */
#define SINTER_WASM_DONE 0   /* the call succeeded */
#define SINTER_WASM_FAILED 1 /* the code failed; the failure says why */
#define SINTER_WASM_MISUSE 2 /* the precondition does not hold; the message says why */
#define SINTER_WASM_FAULT 3  /* an internal fault of the engine */

/* Free a byte sequence that the engine gave. */
void sinter_wasm_bytes_free(sinter_wasm_bytes bytes);

/* Make an engine whose WebAssembly code has stack bytes of call stack.
   Returns NULL on failure, with the message in *message. */
sinter_wasm_engine *sinter_wasm_engine_new(uint64_t stack,
                                           sinter_wasm_bytes *message);

/* Free an engine. Its modules stay valid. */
void sinter_wasm_engine_free(sinter_wasm_engine *engine);

/* Compile len bytes as a module. Returns NULL when they are not a
   module of WebAssembly Core 2.0, with the message in *message. */
sinter_wasm_module *sinter_wasm_module_new(const sinter_wasm_engine *engine,
                                           const uint8_t *bytes, size_t len,
                                           sinter_wasm_bytes *message);

/* Free a module. Its instances stay valid. */
void sinter_wasm_module_free(sinter_wasm_module *module);

/* The number of imports of a module. */
size_t sinter_wasm_module_import_count(const sinter_wasm_module *module);

/* The number of exports of a module. */
size_t sinter_wasm_module_export_count(const sinter_wasm_module *module);

/* The facts of export index of a module, in the order of its export
   section: its name; its kind (0 function, 1 memory, 2 table, 3
   global); for a function, the codes of its parameter types and of its
   result types (0 i32, 1 i64, 2 f32, 3 f64, 4 v128, 5 funcref, 6
   externref). The pointers stay valid while the module lives. Returns
   SINTER_WASM_DONE, or SINTER_WASM_MISUSE when index is not less than
   the number of exports. */
int32_t sinter_wasm_module_export(const sinter_wasm_module *module,
                                  size_t index, const uint8_t **name,
                                  size_t *name_len, uint32_t *kind,
                                  const uint8_t **params, size_t *params_len,
                                  const uint8_t **results,
                                  size_t *results_len);

/* Make an instance of a module with no import, in a new store, under
   limits. Returns NULL with the result code in *code and the failure or
   the message in *failure. */
sinter_wasm_instance *sinter_wasm_instance_new(
    const sinter_wasm_module *module, sinter_wasm_limits limits,
    int32_t *code, sinter_wasm_failure *failure);

/* Free an instance and its store. */
void sinter_wasm_instance_free(sinter_wasm_instance *instance);

/* Invoke the function export name of an instance with arguments.
   result_kind is the result type of the function: 0 none, 1 i32, 2
   i64. On SINTER_WASM_DONE, *result holds the result when the function
   has one. Otherwise *failure holds the failure or the message. */
int32_t sinter_wasm_instance_invoke(sinter_wasm_instance *instance,
                                    const uint8_t *name, size_t name_len,
                                    const sinter_wasm_value *arguments,
                                    size_t arguments_len, uint32_t result_kind,
                                    sinter_wasm_value *result,
                                    sinter_wasm_failure *failure);

/* The number of bytes of the memory export name of an instance, in
   *size. */
int32_t sinter_wasm_instance_memory_size(sinter_wasm_instance *instance,
                                         const uint8_t *name, size_t name_len,
                                         uint64_t *size,
                                         sinter_wasm_bytes *message);

/* Copy length bytes from address of the memory export name to out, or,
   when out is NULL, only check that they lie inside that memory. */
int32_t sinter_wasm_instance_read(sinter_wasm_instance *instance,
                                  const uint8_t *name, size_t name_len,
                                  uint64_t address, uint64_t length,
                                  uint8_t *out, sinter_wasm_bytes *message);

/* Put len bytes into the memory export name from address on. */
int32_t sinter_wasm_instance_write(sinter_wasm_instance *instance,
                                   const uint8_t *name, size_t name_len,
                                   uint64_t address, const uint8_t *data,
                                   size_t len, sinter_wasm_bytes *message);

/* The facts of import index of a module, in the order of its import
   section: its module name and its name; its kind (0 function, 1
   memory, 2 table, 3 global); for a function, the codes of its
   parameter and result types; for a memory or a table, its minimum,
   and its maximum when *has_maximum is 1; for a table, the code of the
   type of its elements in *global_type; for a global, the code of its
   value type, and 1 in *mutable_ when it is mutable. The pointers stay
   valid while the module lives. Returns SINTER_WASM_DONE, or
   SINTER_WASM_MISUSE when index is not less than the number of
   imports. */
int32_t sinter_wasm_module_import(
    const sinter_wasm_module *module, size_t index,
    const uint8_t **module_name, size_t *module_name_len,
    const uint8_t **name, size_t *name_len, uint32_t *kind,
    const uint8_t **params, size_t *params_len, const uint8_t **results,
    size_t *results_len, uint64_t *minimum, uint64_t *maximum,
    int32_t *has_maximum, uint8_t *global_type, int32_t *mutable_);

/* Make a new store of an engine under limits, with no instance.
   Returns NULL on an internal fault, with the message in *message. */
sinter_wasm_store *sinter_wasm_store_new(const sinter_wasm_engine *engine,
                                         sinter_wasm_limits limits,
                                         sinter_wasm_bytes *message);

/* Free a store, with its instances. */
void sinter_wasm_store_free(sinter_wasm_store *store);

/* Make an instance of a module in a store, with the values of imports
   for its imports, in their order. On SINTER_WASM_DONE, *instance
   holds the index of the instance in the store. Otherwise *failure
   holds the failure or the message. */
int32_t sinter_wasm_store_instantiate(sinter_wasm_store *store,
                                      const sinter_wasm_module *module,
                                      const sinter_wasm_import *imports,
                                      size_t imports_len, uint64_t *instance,
                                      sinter_wasm_failure *failure);

/* Invoke the function export name of the instance instance of a store,
   as sinter_wasm_instance_invoke does. */
int32_t sinter_wasm_store_invoke(sinter_wasm_store *store, uint64_t instance,
                                 const uint8_t *name, size_t name_len,
                                 const sinter_wasm_value *arguments,
                                 size_t arguments_len, uint32_t result_kind,
                                 sinter_wasm_value *result,
                                 sinter_wasm_failure *failure);

/* Grow the memory (part 0) or the table (part 1) export name of the
   instance instance of a store by delta pages or elements. On
   SINTER_WASM_DONE, *previous holds the size before. Otherwise
   *failure holds the failure or the message. */
int32_t sinter_wasm_store_grow(sinter_wasm_store *store, uint64_t instance,
                               uint32_t part, const uint8_t *name,
                               size_t name_len, uint64_t delta,
                               uint64_t *previous,
                               sinter_wasm_failure *failure);

/* The number of bytes of the memory export name of the instance
   instance of a store, in *size. */
int32_t sinter_wasm_store_memory_size(sinter_wasm_store *store,
                                      uint64_t instance, const uint8_t *name,
                                      size_t name_len, uint64_t *size,
                                      sinter_wasm_bytes *message);

/* Copy length bytes from address of the memory export name of the
   instance instance of a store to out, or, when out is NULL, only check
   that they lie inside that memory. */
int32_t sinter_wasm_store_read(sinter_wasm_store *store, uint64_t instance,
                               const uint8_t *name, size_t name_len,
                               uint64_t address, uint64_t length, uint8_t *out,
                               sinter_wasm_bytes *message);

/* Put len bytes into the memory export name of the instance instance of
   a store from address on. */
int32_t sinter_wasm_store_write(sinter_wasm_store *store, uint64_t instance,
                                const uint8_t *name, size_t name_len,
                                uint64_t address, const uint8_t *data,
                                size_t len, sinter_wasm_bytes *message);

#ifdef __cplusplus
}
#endif

#endif
