/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 The Sinter Authors */

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/signals.h>
#include <caml/unixsupport.h>

CAMLprim value sinter_repository_files_open_folder(value path) {
  CAMLparam1(path);
  caml_unix_check_path(path, "open");
  char *copy = caml_stat_strdup(String_val(path));
  caml_enter_blocking_section();
  int handle = open(copy, O_RDONLY | O_DIRECTORY | O_NONBLOCK | O_NOCTTY |
                              O_CLOEXEC);
  caml_leave_blocking_section();
  caml_stat_free(copy);
  if (handle == -1) {
    caml_uerror("open", path);
  }
  CAMLreturn(Val_int(handle));
}

static void free_names(char **names, size_t count) {
  for (size_t i = 0; i < count; i++) {
    free(names[i]);
  }
  free(names);
}

CAMLprim value sinter_repository_files_list(value folder) {
  CAMLparam1(folder);
  CAMLlocal3(list, name, cell);
  int copy = fcntl(Int_val(folder), F_DUPFD_CLOEXEC, 0);
  if (copy == -1) {
    caml_uerror("fcntl", Nothing);
  }
  DIR *listing = fdopendir(copy);
  if (listing == NULL) {
    int error = errno;
    close(copy);
    caml_unix_error(error, "fdopendir", Nothing);
  }
  rewinddir(listing);
  char **names = NULL;
  size_t count = 0;
  size_t room = 0;
  int error = 0;
  for (;;) {
    errno = 0;
    struct dirent *entry = readdir(listing);
    if (entry == NULL) {
      error = errno;
      break;
    }
    if (count == room) {
      size_t larger = room == 0 ? 64 : 2 * room;
      char **grown = realloc(names, larger * sizeof *names);
      if (grown == NULL) {
        error = ENOMEM;
        break;
      }
      names = grown;
      room = larger;
    }
    names[count] = strdup(entry->d_name);
    if (names[count] == NULL) {
      error = ENOMEM;
      break;
    }
    count++;
  }
  closedir(listing);
  if (error != 0) {
    free_names(names, count);
    caml_unix_error(error, "readdir", Nothing);
  }
  list = Val_emptylist;
  for (size_t i = 0; i < count; i++) {
    name = caml_copy_string(names[i]);
    cell = caml_alloc_small(2, Tag_cons);
    Field(cell, 0) = name;
    Field(cell, 1) = list;
    list = cell;
  }
  free_names(names, count);
  CAMLreturn(list);
}

CAMLprim value sinter_repository_files_eilseq(value unit) {
  (void)unit;
  return Val_int(EILSEQ);
}
