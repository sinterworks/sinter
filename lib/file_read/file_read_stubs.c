/* SPDX-License-Identifier: Apache-2.0 */
/* Copyright 2026 The Sinter Authors */

/* @cites file-read-calls */

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/signals.h>
#include <caml/unixsupport.h>

static value open_at(int folder, value name, int flags) {
  CAMLparam1(name);
  caml_unix_check_path(name, "openat");
  char *copy = caml_stat_strdup(String_val(name));
  caml_enter_blocking_section();
  int handle = openat(folder, copy, flags);
  caml_leave_blocking_section();
  caml_stat_free(copy);
  if (handle == -1) {
    caml_uerror("openat", name);
  }
  CAMLreturn(Val_int(handle));
}

CAMLprim value sinter_file_read_open_root(value path) {
  return open_at(AT_FDCWD, path, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
}

CAMLprim value sinter_file_read_open_folder(value folder, value name) {
  return open_at(Int_val(folder), name,
                 O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
}

CAMLprim value sinter_file_read_open_file(value folder, value name) {
  return open_at(Int_val(folder), name,
                 O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_NOCTTY | O_CLOEXEC);
}

CAMLprim value sinter_file_read_kind_at(value folder, value name) {
  CAMLparam2(folder, name);
  struct stat status;
  caml_unix_check_path(name, "fstatat");
  char *copy = caml_stat_strdup(String_val(name));
  caml_enter_blocking_section();
  int outcome = fstatat(Int_val(folder), copy, &status, AT_SYMLINK_NOFOLLOW);
  caml_leave_blocking_section();
  caml_stat_free(copy);
  if (outcome == -1) {
    caml_uerror("fstatat", name);
  }
  switch (status.st_mode & S_IFMT) {
  case S_IFDIR:
    CAMLreturn(Val_int(0));
  case S_IFREG:
    CAMLreturn(Val_int(1));
  case S_IFLNK:
    CAMLreturn(Val_int(2));
  default:
    CAMLreturn(Val_int(3));
  }
}

CAMLprim value sinter_file_read_check_search(value folder) {
  CAMLparam1(folder);
  caml_enter_blocking_section();
  int outcome = faccessat(Int_val(folder), ".", X_OK, AT_EACCESS);
  caml_leave_blocking_section();
  if (outcome == -1) {
    caml_uerror("faccessat", Nothing);
  }
  CAMLreturn(Val_unit);
}

static void free_names(char **names, size_t count) {
  for (size_t i = 0; i < count; i++) {
    free(names[i]);
  }
  free(names);
}

CAMLprim value sinter_file_read_list(value folder) {
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

CAMLprim value sinter_file_read_eilseq(value unit) {
  (void)unit;
  return Val_int(EILSEQ);
}
