(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Git configurations, as the term [git-configuration] of the design
    [changes=v1] defines them, with the rules of the page git-config, and the
    upstream of a branch, as the term [default-branch-commit] gives it.

    Pathnames, names, and values are byte sequences, OCaml [string]s. This
    module reads no file and no environment variable itself: the caller gives a
    function that reads a file and a function that gives the environment in
    which the program started. *)

(** {1 Keys and values} *)

type key
(** The name of a setting: a section, maybe a subsection, and a variable name.
*)

val key : section:string -> ?subsection:string -> string -> key
(** [key ~section ~subsection name] is the key of the variable [name] in the
    section [section], and in its subsection [subsection] when it is given. Two
    keys are the same key when they give the same byte sequence: the section
    with the bytes [A] to [Z] as [a] to [z]; then, when there is a subsection,
    [.] and the subsection byte for byte; then [.] and the name with the bytes
    [A] to [Z] as [a] to [z]. So the section [branch.main] and no subsection
    give the same keys as the section [branch] and the subsection [main]. *)

val equal_key : key -> key -> bool
(** [equal_key a b] is [true] when, and only when, [a] and [b] are the same key
    by the rule of {!key}. *)

type value = string option
(** A value of a setting: [Some bytes], or [None] for a line that names the
    variable with no [=] after it. *)

val boolean : value -> bool option
(** [boolean value] is the value as a boolean, by the rules of git: [Some true]
    for [None] and for [yes], [on], [true], and [1]; [Some false] for [no],
    [off], [false], [0], and the empty byte sequence; the letters in any case.
    Any other value is an integer when it is, in order: zero or more of the
    bytes 0x20 and 0x09 to 0x0D; [+], [-], or neither; [0x] or [0X] and one or
    more hex digits, or [0] and zero or more of the digits [0] to [7], or a
    digit [1] to [9] and zero or more digits, as a number in base 16, 8, or 10;
    and at most one of [k], [m], and [g], in either case, which multiplies the
    number by 2{^ 10}, 2{^ 20}, or 2{^ 30}. Such an integer from -2{^ 31} to
    2{^ 31}-1 gives [Some true] when it is not 0 and [Some false] when it is 0.
    It is [None] for any other value. *)

type pathname =
  | Pathname of string  (** the value names the file at this pathname *)
  | Names_no_file
      (** the value starts with [%(prefix)/] or with [:(optional)], and it names
          no file *)

type pathname_error =
  | No_home  (** the value starts with [~/], and [HOME] is not set *)
  | Unread_form
      (** the value starts with [~] and not with [~/]; this interface gives no
          pathname for this form *)
  | No_value  (** the value is [None] *)

val pathname : home:string option -> value -> (pathname, pathname_error) result
(** [pathname ~home value] is the file that [value] names, by the rules of the
    page git-config for pathnames, where [home] is the value of the environment
    variable [HOME]: for a value [~/] and a rest, [home], then [/], then the
    rest; for a value that starts with [%(prefix)/] or with [:(optional)], no
    file; for each other value that does not start with [~], the value itself,
    relative or not. *)

(** {1 One configuration file} *)

type syntax_error = { line : int }
(** The line, from 1, at which the content stops being in the syntax of the page
    git-config. *)

val parse : string -> ((key * value) list, syntax_error) result
(** [parse content] is the settings of one configuration file whose content is
    [content], in the order of their lines, with no include applied. The syntax
    is that of the page git-config, section "Syntax": a section header [[name]]
    or [[name "subsection"]], with whitespace before the double quote, gives the
    settings after it the section [name] and the subsection [subsection]. A
    section name is zero or more of the bytes [a] to [z], [A] to [Z], [0] to
    [9], [-], and [.], and it is empty only in a header with a subsection; a
    subsection holds no 0x0A and no 0x00, with [\ ] before any byte for that
    byte. The rest of the line after a header is read as the lines below are.
    The other lines are lines [name = value] or [name], where a name is a
    letter, then letters, digits, and [-]. Only the bytes 0x20 and 0x09 are
    whitespace. [#] and [;] outside double quotes start a comment to the end of
    the line. In a value, the whitespace around it is dropped, the whitespace
    inside it is kept byte for byte, double quotes are dropped and keep the
    whitespace between them, and a [\ ] and 0x0A join two lines. A [\ ] before a
    double quote, a [\ ], [n], [t], or [b] gives the byte 0x22, 0x5C, 0x0A,
    0x09, or 0x08. A setting before the first section header, a [\ ] before any
    other byte, a double quote with no end on its line, a byte 0x00, and a [\ ]
    at the end of the content are errors. *)

(** {1 Configurations} *)

type t
(** The settings of a git configuration, each with its values in order. *)

val values : t -> key -> value list
(** [values configuration key] is the values of the setting [key], in the order
    in which the page git-config reads the files and their lines, with the lines
    of an included file at the place of its include. It is [[]] when the setting
    has no value. *)

val last : t -> key -> value option
(** [last configuration key] is the last of [values configuration key], the
    value of a setting that takes one value, or [None] when there is none. *)

(** What a read of a file gives. *)
type file =
  | No_file  (** no file is at the pathname *)
  | Unreadable  (** a file is there, and it cannot be read as a regular file *)
  | Content of { content : string; identity : (int * int) option }
      (** the whole content of the regular file there, and, when the system
          gives one, its identity: the number of its device and its file serial
          number *)

type error =
  | Syntax of { pathname : string; line : int }
      (** the file at [pathname] is not in the syntax of {!parse}, from [line]
      *)
  | Unreadable_file of string
      (** the file [config] of the git folder, the file [config.worktree], or an
          included file at this pathname gives [Unreadable] *)
  | Environment of string
      (** the environment variable with this name has a value that the page
          git-config does not give a meaning: [GIT_CONFIG_NOSYSTEM] that is not
          a boolean, [GIT_CONFIG_COUNT] that is not empty and not a whole number
          in decimal digits, or a [GIT_CONFIG_KEY_<n>] that is missing or not a
          key, or a [GIT_CONFIG_VALUE_<n>] that is missing, for an [<n>] below
          the count *)
  | Unread_pathname of { pathname : string option; value : value }
      (** {!pathname} gives an error for the value [value] of [include.path] or
          [includeIf.<condition>.path], or the value of [HOME] is empty and
          [value] is the value of a setting [includeIf.<condition>.<name>], for
          any [<name>], whose condition is [gitdir:] or [gitdir/i:] and a
          pattern that is [~] or starts with [~/]; in the file at [pathname], or
          in the environment when [pathname] is [None] *)
  | Relative_without_file of value
      (** a value of [include.path] or of [includeIf.<condition>.path] that
          includes a file, or a condition [gitdir:./] or [gitdir/i:./], that is
          relative to a file comes from the environment, which is no file *)
  | Not_a_boolean of key
      (** the last value of this setting is not a boolean by {!boolean} *)
  | Include_cycle of string
      (** an include, in turn, of the file at this pathname comes from that same
          file or from a file that it includes, in turn. Two files are the same
          file when the reads give each an identity and the two identities are
          equal, and otherwise when their pathnames are the same bytes *)
  | Remote_url_in_conditional_include of string
      (** the file at this pathname sets [remote.<name>.url], and either a
          condition [hasconfig:remote.*.url:] that is not met includes that
          file, in turn, or a met condition includes that file, in turn, while
          the configuration has a setting
          [includeIf.hasconfig:remote.*.url:<pattern>.<name>] *)
  | Remote_url_without_value
      (** a setting [remote.<name>.url] has the value [None], and a condition
          [hasconfig:remote.*.url:] needs the values of these settings *)
  | Limit_exceeded
      (** the read would read more files, or read more values, than its
          {!limits} allow; it gives no part of the configuration *)

type limits = {
  max_files : int;
      (** the maximum number of calls of the read of a file: the system file,
          the global files, the file [config], the file [config.worktree], and
          each include, counted each time that it is read *)
  max_values : int;
      (** the maximum number of values of all the settings together, the values
          of [include.path] and [includeIf.<condition>.path] included; the
          values of the files that a condition [hasconfig:remote.*.url:] that is
          not met includes, in turn, count too *)
}
(** The limits of the work of one read of a git configuration. When the
    configuration has a condition [hasconfig:remote.*.url:], each of the two
    passes over its files has these limits. *)

val of_repository :
  limits:limits ->
  environment:(string -> string option) ->
  read:(string -> file) ->
  git_directories:string list ->
  branch:string option ->
  string ->
  (t, error) result
(** [of_repository ~limits ~environment ~read ~git_directories ~branch
     git_folder] is the git configuration of the git repository whose git folder
    is at the pathname [git_folder]. [environment name] is the value of the
    environment variable [name], and [read pathname] is what the file at
    [pathname] gives. [branch] is [Some name] when the HEAD of [git_folder]
    names a branch, with [name] its name after [refs/heads/], and [None]
    otherwise. The files, in this order:

    + the system file: the value of [GIT_CONFIG_SYSTEM], or [/etc/gitconfig]
      when that variable is not set; none when [GIT_CONFIG_NOSYSTEM] is true by
      {!boolean};
    + the global files: the value of [GIT_CONFIG_GLOBAL] when it is set;
      otherwise [$XDG_CONFIG_HOME/git/config], with [$HOME/.config] when
      [XDG_CONFIG_HOME] is not set or empty, and then [$HOME/.gitconfig], each
      only when the variables that it needs are set;
    + the file [config] of the git folder;
    + the settings [GIT_CONFIG_KEY_<n>] and [GIT_CONFIG_VALUE_<n>] for each
      [<n>] from 0 to the value of [GIT_CONFIG_COUNT] less 1, in that order. A
      key [GIT_CONFIG_KEY_<n>] splits at its first and its last [.]: the bytes
      before the first [.] are the section, the bytes of a section name of
      {!parse} other than [.]; the bytes after the last [.] are the variable
      name, as in {!parse}; and, when the two [.] differ, the bytes between them
      are the subsection, with no 0x0A and no 0x00. The section is empty only
      when there is a subsection.

    An empty pathname names no file. A system file or a global file that gives
    [No_file] or [Unreadable] holds no setting; any other file that gives
    [No_file] holds no setting. [GIT_CONFIG] has no effect.

    A value of [include.path], and of [includeIf.<condition>.path] when the
    condition is met, includes the file that the value names by {!pathname},
    relative to the folder of the file that holds the value when it does not
    start with [/]; the settings of that file come at the place of the value.
    [Names_no_file] includes nothing. An empty value is a relative pathname: it
    names the folder of the file that holds it. The conditions:

    - [gitdir:] and a pattern is met when the pattern matches one of the
      pathnames [git_directories], by {!Sinter_wildmatch.matches}, after these
      steps: when the pattern is [~] or starts with [~/], the [~] at its start
      becomes the value of [HOME]; a [./] at its start becomes the folder of the
      file that holds it, then [/]; a pattern that then does not start with [/]
      gets [**/] before it; and a pattern that ends with [/] gets [**] after it.
      [gitdir/i:] is the same with [~case_fold:true]. A pattern that starts with
      [~] and then a byte other than [/] keeps its [~]. When [HOME] is not set,
      a condition [gitdir:] or [gitdir/i:] whose pattern is [~] or starts with
      [~/] is not met. When the value of [HOME] is empty, each setting
      [includeIf.<condition>.<name>] with such a condition, for any [<name>] and
      with a value or with none, gives [Unread_pathname] where the read meets
      that setting.
    - [hasconfig:remote.*.url:] and a pattern is met when the pattern matches a
      value of a setting [remote.<name>.url] of the configuration in which no
      such condition is met.
    - [onbranch:] and a pattern is met when [branch] is [Some name] and the
      pattern matches [name] by {!Sinter_wildmatch.matches}, with [**] after a
      pattern that ends with [/].
    - Any other condition is never met: the setting [includeIf.<condition>.path]
      includes no file.

    A value of [includeIf.hasconfig:remote.*.url:<pattern>.path] whose condition
    is not met also includes a file, by the same rules, but no setting of that
    file, or of a file that it includes, in turn, is a setting of the
    configuration. The read reads these files as it reads each other included
    file, and it counts them and their values toward [limits].

    The read meets the settings of the files and of the environment in their
    order, with the settings of an included file at the place of its include. A
    setting [remote.<name>.url], with a value or with none, gives
    [Remote_url_in_conditional_include] where the read meets it in these files:

    - a file that a condition [hasconfig:remote.*.url:] that is not met
      includes, in turn;
    - a file that a met condition includes, in turn, after the read meets the
      first setting [includeIf.hasconfig:remote.*.url:<pattern>.<name>], for any
      [<name>].

    When the read meets that first setting, a setting [remote.<name>.url], with
    a value or with none, that the read met before that place in a file that a
    met condition includes, in turn, gives [Remote_url_in_conditional_include]
    there, with the pathname of the first such file.

    The configuration of a git repository has no settings of a file
    [config.worktree]. The result is the first error that the files give, in
    their order. Past one of [limits], the result is [Limit_exceeded], and no
    part of the configuration. It raises [Invalid_argument] when a limit is
    negative. *)

val of_working_tree :
  limits:limits ->
  environment:(string -> string option) ->
  read:(string -> file) ->
  git_folder:string ->
  git_directories:string list ->
  branch:string option ->
  string ->
  (t, error) result
(** [of_working_tree ~limits ~environment ~read ~git_folder ~git_directories
     ~branch working_tree_folder] is the git configuration of the working tree
    whose folder is at the pathname [working_tree_folder], of the git repository
    whose git folder is at [git_folder], as {!of_repository} gives it, with one
    more rule. The file [config.worktree] of [working_tree_folder] comes after
    the file [config] of the git folder, when the last value of
    [extensions.worktreeConfig] in that file [config] itself, with no include
    applied, is true by {!boolean}; a value that is not a boolean gives
    [Not_a_boolean]. In this function, [branch] is [Some name] when the HEAD of
    the working tree names a branch, with [name] its name after [refs/heads/],
    and [None] otherwise. *)

(** {1 The upstream of a branch} *)

type upstream_error =
  | No_value_of of key
      (** the first or last value that the term needs is [None], or a value of a
          setting [remote.<name>.fetch] is [None] *)
  | Invalid_refspec of string
      (** this value of a setting [remote.<name>.fetch] is not a fetch refspec
      *)

val upstream :
  t ->
  Sinter_branch_names.Branch_name.t ->
  (string option, upstream_error) result
(** [upstream configuration b] is the name of the upstream of the branch name
    [b], as the term [default-branch-commit] gives it, or [None] when [b] has no
    upstream. First, each value of each setting [remote.<name>.fetch], for any
    [<name>], must be a fetch refspec: the first value, by the order of the keys
    by {!String.compare} and then of the values, that is [None] gives
    [No_value_of], and that is not a fetch refspec gives [Invalid_refspec].
    Then, with M the first value of [branch.<b>.merge] and r the last value of
    [branch.<b>.remote]: no upstream when one of the two has no value; M when r
    is [.]; otherwise the first value of [remote.<r>.fetch] that maps M gives
    the upstream, or no upstream when none maps M. The name is the bytes of a
    destination, and it can be a name that is no ref name, such as [up/main].

    A fetch refspec is one of: [^] and a source that is not empty, a negative
    refspec; or an optional [+], then a source, or a source, [:], and a
    destination, a positive refspec. A source is empty, [@], or a name; a
    destination is empty or a name. A name, by the rules of the page
    git-check-ref-format with one level allowed, is not empty and not [@]; it
    does not start or end with [/] and holds no [//]; no part between [/] starts
    with [.] or ends with [.lock]; it does not end with [.]; it holds no [..]
    and no [@\{]; and it holds no byte 0x00 to 0x20 or 0x7F, none of [~], [^],
    [:], [?], [\[], and [\ ], and at most one [*]. In a positive refspec, when
    the source holds a [*], there is a destination with a [*]; when the source
    holds none, the destination holds none.

    A refspec maps M when it is positive, it has a [:], and its source, with [@]
    read as [HEAD], is M, or holds a [*] and is M with a byte sequence s, which
    can be empty and can hold [/], in place of the [*]. It maps M to its
    destination, with s in place of the [*]. An empty destination gives no
    upstream. *)
