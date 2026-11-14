/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 The Sinter Authors */

#include <stdatomic.h>
#include <stdlib.h>
#include <string.h>

#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#include "sinter_wasm_engine.h"

#define Handle_val(v) (*((void **)Data_custom_val(v)))

static value take_text(sinter_wasm_bytes bytes) {
  value text = caml_alloc_initialized_string(bytes.len, (const char *)bytes.data);
  sinter_wasm_bytes_free(bytes);
  return text;
}

static void raise_misuse(sinter_wasm_bytes message) {
  CAMLparam0();
  CAMLlocal1(text);
  text = take_text(message);
  caml_invalid_argument_value(text);
  CAMLnoreturn;
}

static void raise_fault(sinter_wasm_bytes message) {
  CAMLparam0();
  CAMLlocal1(text);
  text = take_text(message);
  caml_failwith_value(text);
  CAMLnoreturn;
}

static void *live_handle(value v, const char *released) {
  void *handle = Handle_val(v);
  if (handle == NULL) {
    caml_invalid_argument(released);
  }
  return handle;
}

static value alloc_handle(struct custom_operations *operations, void *handle,
                          mlsize_t memory) {
  value block = caml_alloc_custom_mem(operations, sizeof(void *), memory);
  Handle_val(block) = handle;
  return block;
}

#define HANDLE_OPERATIONS(kind, free_function)                                 \
  static void finalize_##kind(value v) {                                       \
    void *handle = Handle_val(v);                                              \
    Handle_val(v) = NULL;                                                      \
    free_function(handle);                                                     \
  }                                                                            \
  static struct custom_operations kind##_operations = {                        \
      "sinter.wasm_engine." #kind, finalize_##kind,                            \
      custom_compare_default,      custom_hash_default,                        \
      custom_serialize_default,    custom_deserialize_default,                 \
      custom_compare_ext_default,  custom_fixed_length_default};

HANDLE_OPERATIONS(engine, sinter_wasm_engine_free)
HANDLE_OPERATIONS(module, sinter_wasm_module_free)

#define Engine_val(v)                                                          \
  ((sinter_wasm_engine *)live_handle(v, "Sinter_wasm_engine: no engine"))
#define Module_val(v)                                                          \
  ((sinter_wasm_module *)live_handle(v, "Sinter_wasm_engine: no module"))

static value result_ok(value contents) {
  CAMLparam1(contents);
  CAMLlocal1(result);
  result = caml_alloc_small(1, 0);
  Field(result, 0) = contents;
  CAMLreturn(result);
}

static value result_error(value contents) {
  CAMLparam1(contents);
  CAMLlocal1(result);
  result = caml_alloc_small(1, 1);
  Field(result, 0) = contents;
  CAMLreturn(result);
}

CAMLprim value sinter_wasm_engine_create_stub(value stack) {
  CAMLparam1(stack);
  CAMLlocal1(handle);
  sinter_wasm_bytes message = {NULL, 0};
  sinter_wasm_engine *engine =
      sinter_wasm_engine_new((uint64_t)Long_val(stack), &message);
  if (engine == NULL) {
    CAMLreturn(result_error(take_text(message)));
  }
  handle = alloc_handle(&engine_operations, engine, 1 << 20);
  CAMLreturn(result_ok(handle));
}

CAMLprim value sinter_wasm_module_compile_stub(value engine, value bytes) {
  CAMLparam2(engine, bytes);
  CAMLlocal1(handle);
  sinter_wasm_bytes message = {NULL, 0};
  sinter_wasm_module *module = sinter_wasm_module_new(
      Engine_val(engine), (const uint8_t *)String_val(bytes),
      caml_string_length(bytes), &message);
  if (module == NULL) {
    CAMLreturn(result_error(take_text(message)));
  }
  handle =
      alloc_handle(&module_operations, module, caml_string_length(bytes));
  CAMLreturn(result_ok(handle));
}

CAMLprim value sinter_wasm_module_import_count_stub(value module) {
  CAMLparam1(module);
  CAMLreturn(Val_long(sinter_wasm_module_import_count(Module_val(module))));
}

static value value_types(const uint8_t *codes, size_t len) {
  CAMLparam0();
  CAMLlocal2(list, cell);
  list = Val_emptylist;
  for (size_t i = len; i > 0; i--) {
    cell = caml_alloc_small(2, 0);
    Field(cell, 0) = Val_int(codes[i - 1]);
    Field(cell, 1) = list;
    list = cell;
  }
  CAMLreturn(list);
}

CAMLprim value sinter_wasm_module_exports_stub(value module) {
  CAMLparam1(module);
  CAMLlocal5(list, cell, pair, name, extern_value);
  CAMLlocal2(params, results);
  sinter_wasm_module *pointer = Module_val(module);
  size_t count = sinter_wasm_module_export_count(pointer);
  list = Val_emptylist;
  for (size_t i = count; i > 0; i--) {
    const uint8_t *name_data = NULL;
    size_t name_len = 0;
    uint32_t kind = 0;
    const uint8_t *param_codes = NULL;
    size_t params_len = 0;
    const uint8_t *result_codes = NULL;
    size_t results_len = 0;
    sinter_wasm_module_export(pointer, i - 1, &name_data, &name_len, &kind,
                              &param_codes, &params_len, &result_codes,
                              &results_len);
    name = caml_alloc_initialized_string(name_len, (const char *)name_data);
    if (kind == 0) {
      params = value_types(param_codes, params_len);
      results = value_types(result_codes, results_len);
      extern_value = caml_alloc_small(2, 0);
      Field(extern_value, 0) = params;
      Field(extern_value, 1) = results;
    } else {
      extern_value = Val_int(kind - 1);
    }
    pair = caml_alloc_small(2, 0);
    Field(pair, 0) = name;
    Field(pair, 1) = extern_value;
    cell = caml_alloc_small(2, 0);
    Field(cell, 0) = pair;
    Field(cell, 1) = list;
    list = cell;
  }
  CAMLreturn(list);
}

static value failure_value(sinter_wasm_failure failure) {
  CAMLparam0();
  CAMLlocal2(result, text);
  switch (failure.code) {
  case SINTER_WASM_FAILURE_TRAP:
    text = take_text(failure.message);
    result = caml_alloc_small(1, 0);
    Field(result, 0) = text;
    break;
  case SINTER_WASM_FAILURE_STACK:
    sinter_wasm_bytes_free(failure.message);
    result = Val_int(0);
    break;
  case SINTER_WASM_FAILURE_FUEL:
  case SINTER_WASM_FAILURE_MEMORY:
  case SINTER_WASM_FAILURE_TABLE:
    sinter_wasm_bytes_free(failure.message);
    result = caml_alloc_small(1, 1);
    Field(result, 0) = Val_int(failure.code - SINTER_WASM_FAILURE_FUEL);
    break;
  default:
    text = take_text(failure.message);
    result = caml_alloc_small(1, 2);
    Field(result, 0) = text;
    break;
  }
  CAMLreturn(result);
}

#define BUSY 1
#define RELEASE 2

struct instance_box {
  sinter_wasm_instance *handle;
  atomic_int state;
};

#define Box_val(v) ((struct instance_box *)Data_custom_val(v))

static void finalize_instance(value v) {
  struct instance_box *box = Box_val(v);
  sinter_wasm_instance_free(box->handle);
  box->handle = NULL;
}

static struct custom_operations instance_operations = {
    "sinter.wasm_engine.instance", finalize_instance,
    custom_compare_default,        custom_hash_default,
    custom_serialize_default,      custom_deserialize_default,
    custom_compare_ext_default,    custom_fixed_length_default};

static const value busy_failure = Val_int(1);

static int take(struct instance_box *box) {
  int idle = 0;
  return atomic_compare_exchange_strong(&box->state, &idle, BUSY);
}

static void give_back(struct instance_box *box) {
  int state = atomic_load(&box->state);
  for (;;) {
    if (state & RELEASE) {
      sinter_wasm_instance_free(box->handle);
      box->handle = NULL;
      atomic_store(&box->state, 0);
      return;
    }
    if (atomic_compare_exchange_weak(&box->state, &state, 0)) {
      return;
    }
  }
}

static sinter_wasm_instance *live_instance(struct instance_box *box) {
  if (box->handle == NULL) {
    give_back(box);
    caml_invalid_argument(
        "Sinter_wasm_engine.Instance: the instance was released");
  }
  return box->handle;
}

static void raise_misuse_after(struct instance_box *box,
                               sinter_wasm_bytes message) {
  give_back(box);
  raise_misuse(message);
}

static void raise_fault_after(struct instance_box *box,
                              sinter_wasm_bytes message) {
  give_back(box);
  raise_fault(message);
}

static void check_after(struct instance_box *box, int32_t code,
                        sinter_wasm_bytes message) {
  if (code == SINTER_WASM_MISUSE) {
    raise_misuse_after(box, message);
  }
  if (code != SINTER_WASM_DONE) {
    raise_fault_after(box, message);
  }
}

CAMLprim value sinter_wasm_instance_create_stub(value module, value fuel,
                                                value memory, value table) {
  CAMLparam4(module, fuel, memory, table);
  CAMLlocal1(handle);
  sinter_wasm_limits limits;
  limits.fuel = (uint64_t)Long_val(fuel);
  limits.memory = (uint64_t)Long_val(memory);
  limits.table = (uint64_t)Long_val(table);
  int32_t code = SINTER_WASM_DONE;
  sinter_wasm_failure failure = {SINTER_WASM_FAILURE_FAULT, {NULL, 0}};
  sinter_wasm_instance *instance =
      sinter_wasm_instance_new(Module_val(module), limits, &code, &failure);
  if (instance != NULL) {
    handle = caml_alloc_custom_mem(&instance_operations,
                                   sizeof(struct instance_box), 1 << 20);
    Box_val(handle)->handle = instance;
    atomic_init(&Box_val(handle)->state, 0);
    CAMLreturn(result_ok(handle));
  }
  if (code == SINTER_WASM_MISUSE) {
    raise_misuse(failure.message);
  }
  CAMLreturn(result_error(failure_value(failure)));
}

CAMLprim value sinter_wasm_instance_release_stub(value instance) {
  CAMLparam1(instance);
  struct instance_box *box = Box_val(instance);
  for (;;) {
    if (take(box)) {
      sinter_wasm_instance_free(box->handle);
      box->handle = NULL;
      atomic_store(&box->state, 0);
      break;
    }
    int state = atomic_load(&box->state);
    if ((state & BUSY) &&
        atomic_compare_exchange_weak(&box->state, &state, state | RELEASE)) {
      break;
    }
  }
  CAMLreturn(Val_unit);
}

CAMLprim value sinter_wasm_instance_invoke_stub(value instance, value name,
                                                value arguments,
                                                value result_type) {
  CAMLparam4(instance, name, arguments, result_type);
  CAMLlocal1(result);
  struct instance_box *box = Box_val(instance);
  if (!take(box)) {
    CAMLreturn(result_error(busy_failure));
  }
  sinter_wasm_instance *pointer = live_instance(box);
  mlsize_t count = Wosize_val(arguments);
  sinter_wasm_value *given = NULL;
  if (count > 0) {
    given = malloc(count * sizeof(sinter_wasm_value));
    if (given == NULL) {
      give_back(box);
      caml_raise_out_of_memory();
    }
  }
  for (mlsize_t i = 0; i < count; i++) {
    value argument = Field(arguments, i);
    if (Tag_val(argument) == 0) {
      given[i].kind = 0;
      given[i].bits = (uint64_t)(uint32_t)Int32_val(Field(argument, 0));
    } else {
      given[i].kind = 1;
      given[i].bits = (uint64_t)Int64_val(Field(argument, 0));
    }
  }
  uint32_t kind = (uint32_t)Int_val(result_type);
  sinter_wasm_value number = {0, 0};
  sinter_wasm_failure failure = {SINTER_WASM_FAILURE_FAULT, {NULL, 0}};
  int32_t code = sinter_wasm_instance_invoke(
      pointer, (const uint8_t *)String_val(name), caml_string_length(name),
      given, count, kind, &number, &failure);
  free(given);
  if (code == SINTER_WASM_MISUSE) {
    raise_misuse_after(box, failure.message);
  }
  give_back(box);
  if (code == SINTER_WASM_DONE) {
    if (kind == 1) {
      result = caml_copy_int32((int32_t)(uint32_t)number.bits);
    } else if (kind == 2) {
      result = caml_copy_int64((int64_t)number.bits);
    } else {
      result = Val_unit;
    }
    CAMLreturn(result_ok(result));
  }
  CAMLreturn(result_error(failure_value(failure)));
}

CAMLprim value sinter_wasm_instance_memory_size_stub(value instance,
                                                     value name) {
  CAMLparam2(instance, name);
  struct instance_box *box = Box_val(instance);
  if (!take(box)) {
    CAMLreturn(result_error(busy_failure));
  }
  uint64_t size = 0;
  sinter_wasm_bytes message = {NULL, 0};
  int32_t code = sinter_wasm_instance_memory_size(
      live_instance(box), (const uint8_t *)String_val(name),
      caml_string_length(name), &size, &message);
  check_after(box, code, message);
  give_back(box);
  CAMLreturn(result_ok(Val_long(size)));
}

CAMLprim value sinter_wasm_instance_read_stub(value instance, value name,
                                              value address, value length) {
  CAMLparam4(instance, name, address, length);
  CAMLlocal1(bytes);
  sinter_wasm_bytes message = {NULL, 0};
  if (!take(Box_val(instance))) {
    CAMLreturn(result_error(busy_failure));
  }
  int32_t code = sinter_wasm_instance_read(
      live_instance(Box_val(instance)), (const uint8_t *)String_val(name),
      caml_string_length(name), (uint64_t)Long_val(address),
      (uint64_t)Long_val(length), NULL, &message);
  check_after(Box_val(instance), code, message);
  give_back(Box_val(instance));
  bytes = caml_alloc_string((mlsize_t)Long_val(length));
  if (!take(Box_val(instance))) {
    CAMLreturn(result_error(busy_failure));
  }
  code = sinter_wasm_instance_read(
      live_instance(Box_val(instance)), (const uint8_t *)String_val(name),
      caml_string_length(name), (uint64_t)Long_val(address),
      (uint64_t)Long_val(length), (uint8_t *)Bytes_val(bytes), &message);
  check_after(Box_val(instance), code, message);
  give_back(Box_val(instance));
  CAMLreturn(result_ok(bytes));
}

CAMLprim value sinter_wasm_instance_write_stub(value instance, value name,
                                               value address, value bytes) {
  CAMLparam4(instance, name, address, bytes);
  struct instance_box *box = Box_val(instance);
  if (!take(box)) {
    CAMLreturn(result_error(busy_failure));
  }
  sinter_wasm_bytes message = {NULL, 0};
  int32_t code = sinter_wasm_instance_write(
      live_instance(box), (const uint8_t *)String_val(name),
      caml_string_length(name), (uint64_t)Long_val(address),
      (const uint8_t *)String_val(bytes), caml_string_length(bytes), &message);
  check_after(box, code, message);
  give_back(box);
  CAMLreturn(result_ok(Val_unit));
}
