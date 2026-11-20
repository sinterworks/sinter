/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 The Sinter Authors */

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "tree_sitter/api.h"

#define EXPORT(name) __attribute__((visibility("default"), export_name(name)))
#define ERROR_SYMBOL ((TSSymbol)-1)

EXPORT("sinter_language_abi") uint32_t sinter_language_abi(const TSLanguage *language) {
  return ts_language_abi_version(language);
}

EXPORT("sinter_parser") TSParser *sinter_parser(const TSLanguage *language) {
  TSParser *parser = ts_parser_new();
  if (!ts_parser_set_language(parser, language)) {
    ts_parser_delete(parser);
    return NULL;
  }
  return parser;
}

static void put(uint8_t *record, uint32_t *at, uint32_t word) {
  memcpy(record + *at, &word, sizeof word);
  *at += sizeof word;
}

EXPORT("sinter_symbols") uint8_t *sinter_symbols(const TSLanguage *language) {
  uint32_t count = ts_language_symbol_count(language);
  uint64_t bytes = 8 + 4 * (uint64_t)count;
  for (uint32_t symbol = 0; symbol < count; symbol++) {
    bytes += strlen(ts_language_symbol_name(language, (TSSymbol)symbol));
  }
  if (bytes > 0xFFFFFFFFu) {
    abort();
  }
  uint8_t *record = malloc((size_t)bytes);
  uint32_t at = 0;
  put(record, &at, (uint32_t)bytes);
  put(record, &at, count);
  for (uint32_t symbol = 0; symbol < count; symbol++) {
    put(record, &at, (uint32_t)strlen(ts_language_symbol_name(language, (TSSymbol)symbol)));
  }
  for (uint32_t symbol = 0; symbol < count; symbol++) {
    const char *name = ts_language_symbol_name(language, (TSSymbol)symbol);
    size_t length = strlen(name);
    memcpy(record + at, name, length);
    at += (uint32_t)length;
  }
  return record;
}

EXPORT("sinter_word") uint32_t sinter_word(const uint8_t *at) {
  uint32_t word;
  memcpy(&word, at, sizeof word);
  return word;
}

EXPORT("sinter_parse") uint8_t *sinter_parse(TSParser *parser, const char *text, uint32_t length) {
  TSTree *tree = ts_parser_parse_string(parser, NULL, text, length);
  if (tree == NULL) {
    return NULL;
  }
  uint32_t error_symbol = ts_language_symbol_count(ts_parser_language(parser));
  TSNode root = ts_tree_root_node(tree);
  uint32_t count = 0;
  TSTreeCursor cursor = ts_tree_cursor_new(root);
  for (;;) {
    count++;
    if (ts_tree_cursor_goto_first_child(&cursor)) {
      continue;
    }
    while (!ts_tree_cursor_goto_next_sibling(&cursor)) {
      if (!ts_tree_cursor_goto_parent(&cursor)) {
        goto counted;
      }
    }
  }
counted:
  if (count > (0xFFFFFFFFu - 8) / 16) {
    abort();
  }
  uint8_t *record = malloc(8 + 16 * (size_t)count);
  uint32_t at = 0;
  put(record, &at, count);
  put(record, &at, ts_node_has_error(root) ? 1 : 0);
  ts_tree_cursor_reset(&cursor, root);
  uint32_t depth = 0;
  for (;;) {
    TSNode node = ts_tree_cursor_current_node(&cursor);
    TSSymbol symbol = ts_node_symbol(node);
    put(record, &at, depth);
    put(record, &at, symbol == ERROR_SYMBOL ? error_symbol : symbol);
    put(record, &at, ts_node_start_byte(node));
    put(record, &at, ts_node_end_byte(node));
    if (ts_tree_cursor_goto_first_child(&cursor)) {
      depth++;
      continue;
    }
    while (!ts_tree_cursor_goto_next_sibling(&cursor)) {
      if (!ts_tree_cursor_goto_parent(&cursor)) {
        return record;
      }
      depth--;
    }
  }
}
