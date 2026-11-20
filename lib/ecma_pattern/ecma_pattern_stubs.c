/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 The Sinter Authors */

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/signals.h>

#include "libregexp.h"

#define HEADER 16
#define STACK_BUDGET (256 * 1024)

typedef struct {
  size_t limit;
  size_t used;
  int refused;
  uint64_t checks;
  uint64_t calls;
  const char *stack_base;
  int stack_exhausted;
} context;

int lre_check_timeout(void *opaque) {
  context *c = opaque;
  if (c == NULL) {
    return 0;
  }
  c->calls++;
  return c->calls > c->checks;
}

int lre_check_stack_overflow(void *opaque, size_t alloca_size) {
  char here;
  context *c = opaque;
  if (c == NULL || c->stack_base == NULL) {
    return 0;
  }
  if (&here > c->stack_base) {
    return 0;
  }
  size_t depth = (size_t)(c->stack_base - &here);
  if (depth + alloca_size > STACK_BUDGET) {
    c->stack_exhausted = 1;
    return 1;
  }
  return 0;
}

void *lre_realloc(void *opaque, void *ptr, size_t size) {
  context *c = opaque;
  unsigned char *base = NULL;
  size_t old = 0;
  if (ptr != NULL) {
    base = (unsigned char *)ptr - HEADER;
    memcpy(&old, base, sizeof old);
  }
  if (size == 0) {
    if (c != NULL) {
      c->used -= old;
    }
    free(base);
    return NULL;
  }
  if (size > SIZE_MAX - HEADER ||
      (c != NULL && (size > c->limit || c->used - old > c->limit - size))) {
    if (c != NULL) {
      c->refused = 1;
    }
    return NULL;
  }
  unsigned char *grown = realloc(base, HEADER + size);
  if (grown == NULL) {
    return NULL;
  }
  memcpy(grown, &size, sizeof size);
  if (c != NULL) {
    c->used = c->used - old + size;
  }
  return grown + HEADER;
}

#define Bytecode_val(v) (*((uint8_t **)Data_custom_val(v)))

static void finalize_code(value v) {
  lre_realloc(NULL, Bytecode_val(v), 0);
  Bytecode_val(v) = NULL;
}

static struct custom_operations code_operations = {
    "sinter.ecma_pattern.code", finalize_code,
    custom_compare_default,     custom_hash_default,
    custom_serialize_default,   custom_deserialize_default,
    custom_compare_ext_default, custom_fixed_length_default};

static value tagged(int tag, value contents) {
  CAMLparam1(contents);
  CAMLlocal1(block);
  block = caml_alloc_small(1, tag);
  Field(block, 0) = contents;
  CAMLreturn(block);
}

CAMLprim value sinter_ecma_pattern_compile_stub(value source, value memory) {
  CAMLparam2(source, memory);
  CAMLlocal3(code, message, pair);
  size_t length = caml_string_length(source);
  char *copy = malloc(length + 1);
  if (copy == NULL) {
    caml_raise_out_of_memory();
  }
  memcpy(copy, String_val(source), length);
  copy[length] = '\0';
  char error[128];
  int size = 0;
  char base;
  context c = {(size_t)Long_val(memory), 0, 0, 0, 0, &base, 0};
  caml_enter_blocking_section();
  uint8_t *compiled = lre_compile(&size, error, sizeof error, copy, length,
                                  LRE_FLAG_UNICODE, &c);
  caml_leave_blocking_section();
  free(copy);
  if (compiled != NULL) {
    code = caml_alloc_custom_mem(&code_operations, sizeof(uint8_t *),
                                 (mlsize_t)size);
    Bytecode_val(code) = compiled;
    pair = caml_alloc_tuple(2);
    Store_field(pair, 0, code);
    Store_field(pair, 1, Val_int(size));
    CAMLreturn(tagged(0, pair));
  }
  if (c.stack_exhausted) {
    CAMLreturn(tagged(1, Val_int(0)));
  }
  if (c.refused) {
    CAMLreturn(tagged(1, Val_int(1)));
  }
  message = caml_copy_string(error);
  CAMLreturn(tagged(1, tagged(0, message)));
}

CAMLprim value sinter_ecma_pattern_test_stub(value code, value subject,
                                             value checks, value memory) {
  CAMLparam4(code, subject, checks, memory);
  size_t bytes = caml_string_length(subject);
  size_t units = bytes / 2;
  context c = {(size_t)Long_val(memory), 0, 0, (uint64_t)Long_val(checks), 0,
               NULL, 0};
  if (units > INT32_MAX) {
    CAMLreturn(tagged(1, Val_int(1)));
  }
  static uint8_t nothing[2];
  uint8_t *copy = bytes == 0 ? nothing : lre_realloc(&c, NULL, bytes);
  if (copy == NULL) {
    if (c.refused) {
      CAMLreturn(tagged(1, Val_int(1)));
    }
    caml_raise_out_of_memory();
  }
  memcpy(copy, String_val(subject), bytes);
  const uint8_t *compiled = Bytecode_val(code);
  int count = lre_get_alloc_count(compiled);
  uint8_t **captures = malloc(sizeof(uint8_t *) * (count > 0 ? count : 1));
  if (captures == NULL) {
    if (bytes > 0) {
      lre_realloc(&c, copy, 0);
    }
    caml_raise_out_of_memory();
  }
  caml_enter_blocking_section();
  int found = lre_exec(captures, compiled, copy, 0, (int)units, 1, &c);
  caml_leave_blocking_section();
  free(captures);
  if (bytes > 0) {
    lre_realloc(&c, copy, 0);
  }
  if (found == 1 || found == 0) {
    CAMLreturn(tagged(0, Val_bool(found)));
  }
  if (found == LRE_RET_TIMEOUT) {
    CAMLreturn(tagged(1, Val_int(0)));
  }
  if (c.refused) {
    CAMLreturn(tagged(1, Val_int(1)));
  }
  caml_raise_out_of_memory();
}
