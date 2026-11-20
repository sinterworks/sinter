#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 The Sinter Authors

set -eu

# @cites bridge-build-folders
# Cargo writes its build output outside _build, in one directory for
# each content hash of the crate. The hash covers every file in the
# crate working tree except top-level target/, .git/, and .DS_Store.
# A new directory clones the most recently used build directory of the
# same package, cleans the crate package, and builds the crate. Each
# build marks its directory as used and removes every other unlocked
# build directory that no build used for 7 days. "dune clean" does not
# remove these directories.

abs_path() {
  case $1 in
    /*) printf '%s\n' "$1" ;;
    *)  printf '%s/%s\n' "$(pwd -P)" "$1" ;;
  esac
}

is_hex_key() {
  case $1 in
    '' | *[!0-9a-f]*) return 1 ;;
  esac
  [ "${#1}" -ge 16 ]
}

is_content_key() {
  case $1 in
    '' | *[!0-9a-f]*) return 1 ;;
  esac
  [ "${#1}" -eq 32 ]
}

safe_rm_under_base() {
  rm_base=$1
  rm_path=$2
  [ -n "$rm_base" ] || { echo "Refusing to remove with empty base." >&2; exit 1; }
  [ -n "$rm_path" ] || { echo "Refusing to remove empty path." >&2; exit 1; }
  case $rm_base in
    '/') echo "Refusing to remove under /." >&2; exit 1 ;;
    /*) ;;
    *) echo "Refusing to remove under relative base: $rm_base" >&2; exit 1 ;;
  esac
  case $rm_path in
    "$rm_base"/*) ;;
    *) echo "Refusing to remove path outside base: $rm_path" >&2; exit 1 ;;
  esac
  rm_rel=${rm_path#"$rm_base"/}
  case $rm_rel in
    '' | '.' | '..' | */* | .locks)
      echo "Refusing to remove unsafe child path: $rm_path" >&2
      exit 1
      ;;
  esac
  rm -rf "$rm_path"
}

require_sha256() {
  if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
    echo "Building the crate needs sha256sum or shasum on the PATH." >&2
    exit 1
  fi
}

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    if ! out=$(sha256sum <"$1"); then
      echo "sha256sum failed on $1." >&2
      exit 1
    fi
  elif command -v shasum >/dev/null 2>&1; then
    if ! out=$(shasum -a 256 <"$1"); then
      echo "shasum failed on $1." >&2
      exit 1
    fi
  else
    echo "Building the crate needs sha256sum or shasum on the PATH." >&2
    exit 1
  fi
  printf '%s\n' "${out%% *}"
}

hash_stdin() {
  if command -v sha256sum >/dev/null 2>&1; then
    if ! out=$(sha256sum); then
      echo "sha256sum failed on crate manifest." >&2
      exit 1
    fi
  elif command -v shasum >/dev/null 2>&1; then
    if ! out=$(shasum -a 256); then
      echo "shasum failed on crate manifest." >&2
      exit 1
    fi
  else
    echo "Building the crate needs sha256sum or shasum on the PATH." >&2
    exit 1
  fi
  printf '%s\n' "${out%% *}"
}

with_lock() {
  lock_file=$1
  lock_mode=$2
  shift 2
  if command -v perl >/dev/null 2>&1; then
    perl -MFcntl=:flock,F_SETFD -e '
      my ($path, $mode, @cmd) = @ARGV;
      open(my $fh, "+>>", $path) or die "cannot open $path: $!\n";
      my $op = $mode eq "ex"    ? LOCK_EX
             : $mode eq "nb-ex" ? (LOCK_EX | LOCK_NB)
             : $mode eq "nb-sh" ? (LOCK_SH | LOCK_NB)
             : die "unknown lock mode: $mode\n";
      my $ok = 0;
      while (1) {
        if (flock($fh, $op)) { $ok = 1; last; }
        next if $!{EINTR} && $mode eq "ex";
        last;
      }
      exit 99 unless $ok;
      fcntl($fh, F_SETFD, 0) or die "cannot clear cloexec: $!\n";
      exec(@cmd) or die "cannot exec $cmd[0]: $!\n";
    ' "$lock_file" "$lock_mode" "$@"
  elif command -v flock >/dev/null 2>&1; then
    case $lock_mode in
      ex)    flock -x "$lock_file" "$@" ;;
      nb-ex) flock -x -n -E 99 "$lock_file" "$@" ;;
      nb-sh) flock -s -n -E 99 "$lock_file" "$@" ;;
      *)     exit 2 ;;
    esac
  else
    echo "Locking build directories needs perl or flock on the PATH." >&2
    exit 1
  fi
}

hash_crate() {
  h_root=$1
  require_sha256
  manifest=$(
    cd "$h_root"
    printf 'V 2\n'
    raw_files=$(find . \( -path ./target -type d -o -path ./.git -o -name .DS_Store \) -prune -o -print)
    sorted_files=$(printf '%s\n' "$raw_files" | LC_ALL=C sort)
    printf '%s\n' "$sorted_files" | while IFS= read -r rel; do
      [ -z "$rel" ] && continue
      [ "$rel" = "." ] && continue
      if [ -L "$rel" ]; then
        if [ -d "$rel" ]; then
          echo "The crate holds a symbolic link to a directory: $h_root/$rel" >&2
          exit 1
        fi
        link_target=$(readlink "$rel")
        printf 'L %s %s %s %s\n' "${#rel}" "$rel" "${#link_target}" "$link_target"
        if [ -f "$rel" ]; then
          fhash=$(hash_file "$rel")
          printf 'LT %s\n' "$fhash"
        fi
      elif [ -d "$rel" ]; then
        printf 'D %s %s\n' "${#rel}" "$rel"
      elif [ -f "$rel" ]; then
        if [ -x "$rel" ]; then
          exec_bit=x
        else
          exec_bit=-
        fi
        fhash=$(hash_file "$rel")
        printf 'F %s %s %s %s\n' "${#rel}" "$rel" "$exec_bit" "$fhash"
      fi
    done
  )
  full_hash=$(printf '%s\n' "$manifest" | hash_stdin)
  h_key=$(printf '%s\n' "$full_hash" | cut -c1-32)
  if ! is_content_key "$h_key"; then
    echo "Failed to compute a 32-digit SHA-256 content key for $h_root." >&2
    exit 1
  fi
  printf '%s\n' "$h_key"
}

read_package_name() {
  awk '
    /^[[:space:]]*\[/ {
      in_pkg = ($0 ~ /^[[:space:]]*\[package\][[:space:]]*(#.*)?$/)
      next
    }
    in_pkg && /^[[:space:]]*name[[:space:]]*=/ {
      line = $0
      sub(/^[[:space:]]*name[[:space:]]*=[[:space:]]*/, "", line)
      sub(/[[:space:]]*(#.*)?$/, "", line)
      if (line ~ /^"[^"]*"$/) {
        print substr(line, 2, length(line) - 2)
        exit
      }
      if (line ~ /^'\''[^'\'']*'\''$/) {
        print substr(line, 2, length(line) - 2)
        exit
      }
    }
  ' "$1"
}

copy_dir_cow() {
  c_base=$1
  src=$2
  dst=$3
  safe_rm_under_base "$c_base" "$dst"
  if [ "$(uname -s)" = "Darwin" ]; then
    if cp -c -p -R -P "$src" "$dst" 2>/dev/null; then
      return 0
    fi
    safe_rm_under_base "$c_base" "$dst"
    cp -p -R -P "$src" "$dst"
  else
    if cp -a --reflink=auto "$src" "$dst" 2>/dev/null; then
      return 0
    fi
    safe_rm_under_base "$c_base" "$dst"
    cp -p -R -P "$src" "$dst"
  fi
}

release_dir_of() {
  if [ -n "${CARGO_BUILD_TARGET:-}" ]; then
    printf '%s/%s/release\n' "$1" "$CARGO_BUILD_TARGET"
  else
    printf '%s/release\n' "$1"
  fi
}

is_file_stale() {
  [ -n "$(find "$1" -mtime +6)" ]
}

internal_clone() {
  c_base=$1
  c_cand=$2
  c_stage=$3
  c_pkg=$4
  c_name=$(basename -- "$c_cand")
  [ ! -L "$c_cand" ] || exit 1
  [ -d "$c_cand" ] || exit 1
  [ ! -f "$c_base/.locks/$c_name.building" ] || exit 1
  [ -f "$c_cand/CACHEDIR.TAG" ] || exit 1
  [ -f "$c_cand/package" ] || exit 1
  cand_pkg=$(cat "$c_cand/package" 2>/dev/null) || exit 1
  [ "$cand_pkg" = "$c_pkg" ] || exit 1
  copy_dir_cow "$c_base" "$c_cand" "$c_stage"
}

find_seeds() {
  s_base=$1
  s_key=$2
  s_pkg=$3
  (cd "$s_base" && ls -dt -- */last-used 2>/dev/null) | while IFS= read -r rel; do
    name=${rel%/last-used}
    [ "$name" = "$s_key" ] && continue
    is_hex_key "$name" || continue
    entry=$s_base/$name
    [ -L "$entry" ] && continue
    [ -d "$entry" ] || continue
    [ -f "$s_base/.locks/$name.building" ] && continue
    [ -f "$entry/CACHEDIR.TAG" ] || continue
    [ -f "$entry/package" ] || continue
    cand_pkg=$(cat "$entry/package" 2>/dev/null) || continue
    [ "$cand_pkg" = "$s_pkg" ] || continue
    printf '%s\n' "$name"
  done
}

internal_build() {
  b_self=$1
  b_base=$2
  b_root=$3
  b_key=$4
  b_pkg=$5
  b_archive_name=$6
  b_archive=$7
  b_flags=$8

  if ! is_content_key "$b_key"; then
    echo "Refusing to build with invalid content key: $b_key" >&2
    exit 1
  fi

  b_target=$b_base/$b_key
  b_locks=$b_base/.locks
  b_building=$b_locks/$b_key.building
  b_stage=$b_base/.stage-$b_key-$$
  b_log=$b_archive.log.$$
  b_archive_tmp=$b_archive.tmp.$$
  b_flags_tmp=$b_flags.tmp.$$
  b_rel=$(release_dir_of "$b_target")
  b_stage_rel=$(release_dir_of "$b_stage")

  trap 'safe_rm_under_base "$b_base" "$b_stage"; rm -f "$b_log" "$b_archive_tmp" "$b_flags_tmp"' EXIT
  trap 'safe_rm_under_base "$b_base" "$b_stage"; rm -f "$b_log" "$b_archive_tmp" "$b_flags_tmp"; exit 130' INT
  trap 'safe_rm_under_base "$b_base" "$b_stage"; rm -f "$b_log" "$b_archive_tmp" "$b_flags_tmp"; exit 143' TERM
  trap 'safe_rm_under_base "$b_base" "$b_stage"; rm -f "$b_log" "$b_archive_tmp" "$b_flags_tmp"; exit 129' HUP

  if [ -f "$b_building" ] && [ -d "$b_target" ]; then
    if (cd "$b_root" && CARGO_TARGET_DIR="$b_target" \
        cargo clean -p "$b_pkg" --release --quiet --color never \
        --target-dir "$b_target") >/dev/null 2>&1; then
      rm -f "$b_rel/$b_archive_name"
    else
      safe_rm_under_base "$b_base" "$b_target"
    fi
  fi

  if [ ! -d "$b_rel" ]; then
    safe_rm_under_base "$b_base" "$b_target"
    seeds=$(find_seeds "$b_base" "$b_key" "$b_pkg" || true)
    if [ -n "$seeds" ]; then
      for seed_key in $seeds; do
        safe_rm_under_base "$b_base" "$b_stage"
        if with_lock "$b_locks/$seed_key.lock" nb-sh \
            sh "$b_self" --internal-clone "$b_base" "$b_base/$seed_key" "$b_stage" "$b_pkg"; then
          rm -f "$b_stage/package" "$b_stage/last-used" \
            "$b_stage/native-static-libs.log" "$b_stage/checkout"
          if (cd "$b_root" && CARGO_TARGET_DIR="$b_stage" \
              cargo clean -p "$b_pkg" --release --quiet --color never \
              --target-dir "$b_stage") >/dev/null 2>&1; then
            rm -f "$b_stage_rel/$b_archive_name"
            mv "$b_stage" "$b_target"
            break
          fi
          safe_rm_under_base "$b_base" "$b_stage"
        fi
      done
    fi
  fi

  : >"$b_building"

  if ! (cd "$b_root" && CARGO_TARGET_DIR="$b_target" \
      cargo rustc --release --quiet --color never \
      --target-dir "$b_target" -- --print native-static-libs 2>"$b_log"); then
    cat "$b_log" >&2
    exit 1
  fi

  key_after=$(hash_crate "$b_root")
  if [ "$key_after" != "$b_key" ]; then
    safe_rm_under_base "$b_base" "$b_target"
    rm -f "$b_building"
    echo "The crate changed during the build: $b_root" >&2
    exit 1
  fi

  rm -f "$b_building"

  if [ ! -s "$b_rel/$b_archive_name" ]; then
    echo "The Rust build produced no archive at $b_rel/$b_archive_name." >&2
    cat "$b_log" >&2
    exit 1
  fi

  note=$(sed 's/\x1b\[[0-9;]*m//g' "$b_log" |
    sed -n 's/^note: native-static-libs: *//p' | tail -n 1)
  if [ -z "$note" ]; then
    echo "The Rust toolchain reported no native-static-libs line." >&2
    cat "$b_log" >&2
    exit 1
  fi

  printf '%s\n' "$b_pkg" >"$b_target/.package.$$"
  mv -f "$b_target/.package.$$" "$b_target/package"
  touch "$b_target/last-used"

  cp "$b_rel/$b_archive_name" "$b_archive_tmp"
  mv -f "$b_archive_tmp" "$b_archive"

  echo "note: native-static-libs: $note" >&2
  libraries=$(printf '%s' "$note" |
    tr ' ' '\n' | grep -v -e '^-lSystem$' -e '^-lc$' -e '^$' | tr '\n' ' ')
  printf '(%s)\n' "$libraries" >"$b_flags_tmp"
  mv -f "$b_flags_tmp" "$b_flags"
}

internal_prune_dir() {
  p_base=$1
  p_dir=$2
  [ -L "$p_dir" ] && exit 0
  [ -d "$p_dir" ] || exit 0
  p_name=$(basename -- "$p_dir")
  if [ -f "$p_dir/last-used" ]; then
    if is_file_stale "$p_dir/last-used"; then
      safe_rm_under_base "$p_base" "$p_dir"
      rm -f "$p_base/.locks/$p_name.building"
    fi
    exit 0
  fi
  has_mark=0
  for probe in "$p_dir/checkout" "$p_dir/native-static-libs.log" "$p_dir/package" "$p_dir/CACHEDIR.TAG"; do
    if [ -f "$probe" ]; then
      has_mark=1
      if ! is_file_stale "$probe"; then
        exit 0
      fi
    fi
  done
  if [ "$has_mark" -eq 1 ]; then
    safe_rm_under_base "$p_base" "$p_dir"
    rm -f "$p_base/.locks/$p_name.building"
  fi
}

internal_prune_stage() {
  p_base=$1
  p_stage=$2
  [ -L "$p_stage" ] && exit 0
  [ -d "$p_stage" ] || exit 0
  safe_rm_under_base "$p_base" "$p_stage"
}

prune_base() {
  pb_self=$1
  pb_base=$2
  pb_key=$3
  pb_locks=$pb_base/.locks
  for entry in "$pb_base"/*; do
    [ -L "$entry" ] && continue
    [ -d "$entry" ] || continue
    name=$(basename -- "$entry")
    [ "$name" = "$pb_key" ] && continue
    is_hex_key "$name" || continue
    with_lock "$pb_locks/$name.lock" nb-ex \
      sh "$pb_self" --internal-prune-dir "$pb_base" "$entry" >/dev/null 2>&1 || true
  done
  for entry in "$pb_base"/.stage-*; do
    [ -L "$entry" ] && continue
    [ -d "$entry" ] || continue
    name=$(basename -- "$entry")
    rest=${name#.stage-}
    skey=${rest%-*}
    is_hex_key "$skey" || continue
    with_lock "$pb_locks/$skey.lock" nb-ex \
      sh "$pb_self" --internal-prune-stage "$pb_base" "$entry" >/dev/null 2>&1 || true
  done
}

case ${1:-} in
  --internal-clone) shift; internal_clone "$@"; exit 0 ;;
  --internal-build) shift; internal_build "$@"; exit 0 ;;
  --internal-prune-dir) shift; internal_prune_dir "$@"; exit 0 ;;
  --internal-prune-stage) shift; internal_prune_stage "$@"; exit 0 ;;
esac

cache_name=sinter-bridge-build
require_cmake=0
target_dir_only=0

while [ "$#" -gt 0 ]; do
  case $1 in
    --cache-name) cache_name=$2; shift 2 ;;
    --require-cmake) require_cmake=1; shift ;;
    --target-dir) target_dir_only=1; shift ;;
    --) shift; break ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
    *) break ;;
  esac
done

if [ "$target_dir_only" -eq 1 ]; then
  if [ "$#" -lt 1 ]; then
    echo "Usage: $0 [--cache-name NAME] --target-dir CRATE" >&2
    exit 2
  fi
  crate=$1
  fallback=
else
  if [ "$#" -lt 4 ]; then
    echo "Usage: $0 [OPTIONS] CRATE FALLBACK ARCHIVE FLAGS" >&2
    exit 2
  fi
  crate=$1
  fallback=$2
  archive=$(abs_path "$3")
  flags=$(abs_path "$4")
fi

if [ -n "${CARGO_TARGET_DIR:-}" ]; then
  base=$CARGO_TARGET_DIR
elif [ -n "${XDG_CACHE_HOME:-}" ]; then
  base=$XDG_CACHE_HOME/$cache_name
elif [ -n "${HOME:-}" ]; then
  base=$HOME/.cache/$cache_name
else
  base=$fallback
fi

if [ -z "$base" ]; then
  echo "The build directory is empty. Set CARGO_TARGET_DIR, XDG_CACHE_HOME, or HOME." >&2
  exit 1
fi
base=$(abs_path "$base")
if [ "$base" = "/" ]; then
  echo "Refusing to use / as the build parent directory." >&2
  exit 1
fi

require_sha256

root=$(CDPATH='' cd -- "$crate" && pwd -P)
key=$(hash_crate "$root")
if ! is_content_key "$key"; then
  echo "Failed to compute a 32-digit SHA-256 content key for $root." >&2
  exit 1
fi
target=$base/$key

if [ "$target_dir_only" -eq 1 ]; then
  printf '%s\n' "$target"
  exit 0
fi

if ! command -v cargo >/dev/null 2>&1; then
  echo "This crate needs the Rust toolchain, and cargo is not on the PATH." >&2
  echo "Install it with rustup: https://rustup.rs" >&2
  exit 1
fi

if [ "$require_cmake" -eq 1 ] && ! command -v cmake >/dev/null 2>&1; then
  echo "The bridge needs cmake, and cmake is not on the PATH." >&2
  echo "A build script of wasmtime runs it. Install cmake and build again." >&2
  exit 1
fi

if [ ! -f "$root/Cargo.toml" ]; then
  echo "The crate directory holds no Cargo.toml: $root" >&2
  exit 1
fi
package_name=$(read_package_name "$root/Cargo.toml")
if [ -z "$package_name" ]; then
  echo "Cargo.toml holds no package name: $root/Cargo.toml" >&2
  exit 1
fi

archive_name=$(basename -- "$archive")
self=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)/$(basename -- "$0")

mkdir -p "$base"
base=$(CDPATH='' cd -- "$base" && pwd -P)
if [ -z "$base" ] || [ "$base" = "/" ]; then
  echo "Refusing to use / as the build parent directory." >&2
  exit 1
fi
mkdir -p "$base/.locks"
locks=$base/.locks

with_lock "$locks/$key.lock" ex \
  sh "$self" --internal-build \
    "$self" "$base" "$root" "$key" "$package_name" "$archive_name" "$archive" "$flags"

prune_base "$self" "$base" "$key"
