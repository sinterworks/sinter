/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 The Sinter Authors */

#include <stddef.h>
#include <stdint.h>

#define EXPORT(name) __attribute__((visibility("default"), export_name(name)))
#define ALIGN 16u
#define PAGE 65536u
#define SMALL_CLASSES 32u
#define CLASSES (SMALL_CLASSES + 22u)
#define LARGEST 0x80000000u

extern unsigned char __heap_base;

static uint32_t heap_next;
static void *free_lists[CLASSES];

typedef struct {
  uint32_t class;
  uint32_t capacity;
  uint32_t unused[2];
} header;

_Static_assert(sizeof(header) == ALIGN, "a header keeps the alignment");

static uint32_t class_of(size_t size, uint32_t *capacity) {
  if (size <= SMALL_CLASSES * ALIGN) {
    uint32_t class = size == 0 ? 0 : (uint32_t)((size - 1) / ALIGN);
    *capacity = (class + 1) * ALIGN;
    return class;
  }
  if (size > LARGEST) {
    __builtin_trap();
  }
  uint32_t class = SMALL_CLASSES;
  uint32_t bytes = 1024;
  while (bytes < size) {
    bytes <<= 1;
    class++;
  }
  *capacity = bytes;
  return class;
}

static void *carve(uint32_t bytes) {
  if (heap_next == 0) {
    heap_next = ((uint32_t)(uintptr_t)&__heap_base + ALIGN - 1) & ~(ALIGN - 1);
  }
  if (bytes > 0xFFFFFFFFu - heap_next) {
    __builtin_trap();
  }
  uint32_t want = heap_next + bytes;
  uint64_t end = (uint64_t)__builtin_wasm_memory_size(0) * PAGE;
  if (want > end) {
    uint64_t pages = ((uint64_t)want - end + PAGE - 1) / PAGE;
    if (__builtin_wasm_memory_grow(0, (size_t)pages) == (size_t)-1) {
      __builtin_trap();
    }
  }
  void *block = (void *)(uintptr_t)heap_next;
  heap_next = want;
  return block;
}

EXPORT("malloc") void *malloc(size_t size) {
  uint32_t capacity = 0;
  uint32_t class = class_of(size, &capacity);
  void *block = free_lists[class];
  if (block != NULL) {
    free_lists[class] = *(void **)block;
    return block;
  }
  if (capacity > 0xFFFFFFFFu - sizeof(header)) {
    __builtin_trap();
  }
  header *head = carve(capacity + (uint32_t)sizeof(header));
  head->class = class;
  head->capacity = capacity;
  return head + 1;
}

EXPORT("free") void free(void *block) {
  if (block == NULL) {
    return;
  }
  header *head = (header *)block - 1;
  if (head->class >= CLASSES) {
    __builtin_trap();
  }
  *(void **)block = free_lists[head->class];
  free_lists[head->class] = block;
}

EXPORT("calloc") void *calloc(size_t count, size_t size) {
  if (size != 0 && count > 0xFFFFFFFFu / size) {
    __builtin_trap();
  }
  size_t bytes = count * size;
  void *block = malloc(bytes);
  __builtin_memset(block, 0, bytes);
  return block;
}

EXPORT("realloc") void *realloc(void *block, size_t size) {
  if (block == NULL) {
    return malloc(size);
  }
  header *head = (header *)block - 1;
  if (size <= head->capacity) {
    return block;
  }
  void *grown = malloc(size);
  __builtin_memcpy(grown, block, head->capacity);
  free(block);
  return grown;
}

EXPORT("abort") __attribute__((noreturn)) void abort(void) { __builtin_trap(); }
