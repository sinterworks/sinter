<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Conformance
@design conformance=v1
A Sinter design declares specifications, requirements, terms, schemas, and atoms, and a conforming program of a design meets the requirements of that design, ends a run at a resource limit, rejects invalid inputs, reports missing parts, and returns the same results over canonical objects in every encoding.

Sinter designs specify what conforming programs return and what actions
those programs avoid. During a run, a program can reach a bound on a
resource such as memory or time, receive an input that the design of
that input defines as invalid, or receive a valid input with content
that the program cannot read.

Designs can also define canonical objects and multiple encodings that
store those objects in inputs. A program can read those objects from
inputs in those encodings or from a database, an index, or a service of
its own.

## Definitions

### Design

@term design=v1

A **design** is a Sinter document that declares items under names, each
with a kind and a revision. A **declared item** is a named unit that a
design declares as one of these kinds: **specification**,
**requirement**, **term**, **schema**, or **atom**.

A **definition** of a design is a declared term, schema, or atom:

- A **term** defines a word or phrase, a grammar rule used by other
  rules, or a computed value.
- A **schema** defines the layout and self-contained constraints of a
  concrete artifact that crosses a program boundary, or of a conformance
  test-vector file.
- An **atom** defines a named result, state, or classification that a
  program returns, with the condition under which the program returns it.

A **specification** of a design is a declared item of kind
`specification` that has its own name and declares a subset of the
design's definitions and requirements. A section of a design that is not
declared as an item of kind `specification` is not a specification.

A **requirement** is a declared item of kind `requirement` that a design
declares under a name and that states one or more obligations of a
program with the word `must`.

Only declared definitions and requirements are normative. Explanatory
prose and glossary rows are non-normative and declare no item. Trailing
`@example` blocks are non-normative, declare no item, and stand outside
their parent item's normative text. A definition that contains the word
`must` remains a definition and is not a requirement. An external
standard is not a design. When a design adopts definitions from an
external standard that the design cites, those adopted definitions are
part of what that design defines.

### Safety obligation

@term safety-obligation=v1
@cites #{design=v1}

A **safety obligation** is an obligation of a requirement that states
one of these guarantees:

- that a program reads, alters, writes, follows, or runs nothing other
  than what the requirement allows (for example, a file, a symbolic
  link, a stored record, or code supplied by a file or by another
  program), or gains no permission;
- that a program never returns an answer that permits an action to
  proceed; or
- that a program ends code or an operation that the program runs.

### Input

@term input=v1
@cites #{design=v1, safety-obligation=v1}

An **input** is a thing that a program takes, such as a file, a
directory tree, or a command argument. A program takes a thing as an
input for a requirement `R` when `R` names that thing as an input of
something `R` obliges the program to return or do, or when the program
supplies that thing as an input for `R`.

Each requirement `R` names the kind of thing as which a program takes
each input of `R`, such as a file, a document, or a command argument.
The design that defines that kind of thing is the **owner design** of
that input for `R`, except when another definition of this design
specifies the owner design of that input.

An input is **invalid** for `R` when its owner design for `R` defines
such a thing as invalid, or when that input supplies code that never
ends (which makes an input invalid for every owner design). Otherwise,
that input is **valid** for `R`. When a program ends code supplied by an
input because that code reaches a bound of the program on time, steps,
or call depth, that code counts, for that program, as code that never
ends. A property defined for a thing, such as being empty, makes an
input invalid for `R` only when the owner design of that input for `R`
says so.

An input can have **parts**, such as the commits of a history or the
files of a directory tree. The owner design of an input defines which
parts the input has and which parts a valid input can lack.

For every owner design, unless one of the exclusions of this term holds,
content that a program could not read while the program reads an input
or a part of an input is a **part that the input lacks** (and a valid
input can lack that part) when any of these conditions holds:

- the system refuses the program a permission;
- the system reports an I/O error; or
- the system offers no operation that lets the program read that content
  while the program keeps every safety obligation that binds the
  program.

That content is not a part that the input lacks when any of these
exclusions holds:

- the refusal, I/O error, or operation rejection comes from a bound of
  the program, its run, or its machine on a resource, such as open
  files, file size, memory, or time;
- the program itself gives up the permission, causes the refusal, or
  restricts operations that the system would otherwise offer (for
  example, through a sandbox that the program sets up); or
- the program reads that content on a later attempt in the same run.

When that content is a part that the input lacks, the input does not
hold that part, and neither lacking that part nor that content makes the
input invalid.

A **part of a program** is a component of a larger program, such as a
library or a subsystem, whose boundary is the interface through which
the larger program passes inputs and receives what the component returns,
together with any external state that the component reads, alters,
writes, follows, or runs. For a part of a program, a **run** is one call
of that component.

In this term:

- The **content** of an input includes what the system supplies about
  that input or its parts, such as directory entries, file types, and
  file bytes.
- The **system** is anything outside the whole program through which the
  program reads an input, such as the operating system or a storage
  service; for a part of a program, the system is the same system as for
  the larger program. The program, its libraries and runtime, and any
  other program that the program runs are not part of the system. A
  feature that any of them lacks is a feature that the program lacks,
  not a case in which the system offers no operation.
- An **I/O error** is a fault of the system or its storage in supplying
  content, such as a device error or a lost connection. A report that
  content does not exist, or that content fails to decode in a defined
  form, is not an I/O error.
- The system **offers no operation** that lets a program read content
  while the program keeps every safety obligation that binds the program
  when the system provides no such operation, or when the system or a
  part of the system (such as a file system) rejects each such operation
  as unsupported. An operation with one choice of options or flags is a
  different operation from the same operation with another choice of
  options or flags.

@example Suppose a program reads a directory tree. For one file, the
operating system refuses permission to read the file, reports a device
error, or rejects as unsupported every operation that lets the program
read the file while the program keeps every
[safety obligation](sinter:#safety-obligation=v1). The directory tree
remains valid and lacks that file's content. When a result
[needs](sinter:#dependence=v1) that file, the program reports the
missing file and withholds that result. The program still returns every
result that does not need that file
([report-missing-parts](sinter:#report-missing-parts=v1)). By contrast,
when the program stops a read of a 10 GB file because the file exceeds
the program's memory bound or because the run hits the open-files bound,
the program reaches a [resource limit](sinter:#resource-limit=v1) and
ends the run ([end-runs-at-limits](sinter:#end-runs-at-limits=v1)).

### Dependence

@term dependence=v1
@cites #{design=v1, input=v1}

What a program returns or does includes any value, summary over several
inputs, exit status, report, or action. A program returns a thing when
the program produces that thing through any interface, such as a return
value, standard output, a structured message, or an exit status.

Let `X` be an input or a part of an input. A thing that a program returns
or does **depends on** `X` when either condition holds:

- a requirement defines that thing, and changing `X`, with every other
  input and the rest of the input that holds `X` unchanged, can change
  what that requirement obliges the program to return or do for that
  thing; or
- the program computes or chooses that thing from `X`.

When an input `I` lacks a part `P`—including content that the program
could not read—whether a thing that a program returns or does depends on
`P` is judged as if `I` held `P` and the program read `P`.

A thing that a program returns or does **depends on** a reading or
computation when what a requirement obliges for that thing depends on an
input or part that the reading reads or on the value that the
computation computes, or when the program computes or chooses that thing
from that reading or computation.

For a valid input `I` and a requirement `R`, the owner design of `I` for
`R` or the design that declares `R` defines which parts of `I` a thing
obliged by `R` **needs**. When both designs state whether a thing
obliged by `R` needs a part of `I`, the design that declares `R`
governs. When neither design states which parts of `I` a thing obliged
by `R` needs, that thing needs every part of `I` on which that thing
depends.

### Resource limit

@term resource-limit=v1
@cites #{input=v1}

A **resource limit** is a bound of a program, its run, or its machine on
a resource that the program uses, such as size, memory, time, open
files, or depth. A program **reaches a resource limit** when, and only
when, the program stops a reading or computation because of such a
bound, or the program's machine ends the program because of such a
bound.

A feature that a program lacks is not a resource limit. Neither code
that never ends nor a condition that makes content a part that an input
lacks is a resource limit:

- When a program ends code that never ends, the program reaches no
  resource limit.
- When a program stops a read because of a condition that makes content
  a part that an input lacks, the program reaches no resource limit.

### Report

@term report=v1
@cites #{design=v1, input=v1, resource-limit=v1}

A **report** is an output that a program returns to identify a stop at a
resource limit, an invalid input, or a missing part of a valid input.
Unless a requirement states the form of a report, a report can have any
form that identifies the required fact, such as a message, a structured
output, an exit status, or a named result.

For a stop at a resource limit, **where** the program reached that limit
is the reading or computation that stopped, together with the input and
a location in that input (in the terms that the owner design of that
input defines) when the stop occurred during a read or computation at a
location in an input.

For an invalid input, **where** the input is invalid is a location in
that input (in the terms that its owner design defines), or the whole
input when its owner design defines no finer location for that input.

### Object

@term object=v1
@cites #{design=v1}

A design defines a kind of thing as a **kind of object** when, and only
when, a definition of that design cites `object` and states that things
of that kind are objects. A thing of any other kind—even when a standard
or a design calls that thing an object—is not an object in this sense.

An **object** is a thing of a kind defined as a kind of object. For each
kind of object, the design that defines that kind defines one
**canonical form**, as a value of a kind that a design defines (such as
a text, a byte sequence, or a structured value). Two canonical forms are
equal when, and only when, they are the same value of that kind. A
**canonical object** is an object in its canonical form. Two objects are
the same canonical object when, and only when, their canonical forms are
equal.

### Encoding

@term encoding=v1
@cites #{design=v1, input=v1, object=v1}

An **encoding** is a form, defined by a design, in which objects are
stored in an input. The design that defines an encoding specifies what
constitutes one input in that encoding (such as a single file or a whole
directory tree), when an input in that encoding is valid, and which
canonical objects a valid input in that encoding holds.

### Program's own store

@term own-store=v1
@cites #{design=v1, input=v1, object=v1, encoding=v1}

A **program's own store** is a store that a program chooses and uses—such
as a database, an index, or a service—whose storage form no design
defines and from which the program reads objects. A program takes a
program's own store as an input for a requirement `R` when, and only
when, the program reads an object from that store for `R`. This design
is the owner design of a program's own store.

A program's own store is **valid** when, and only when, both conditions
hold:

- Each thing that the store holds as an object is a canonical object.
- When a program reads objects of some kinds from the store in place of
  the objects of those kinds from one or more inputs in encodings, each
  of those inputs is valid, and the store holds the same canonical
  objects of those kinds as those inputs hold together, with no
  canonical object of those kinds added, altered, or omitted.

Otherwise, the program's own store is **invalid**. A part that the store
or one of those inputs in encodings lacks because the program could not
read that part's content does not count as an object that the store
adds, alters, or omits, and does not make the store invalid.

@example Suppose a program reads [objects](sinter:#object=v1) from a
database of its own in place of a directory tree of encoded files
([encoding](sinter:#encoding=v1)). If the database omits an object or
alters a field of an object, the database is an invalid input, so
[reject-invalid-inputs](sinter:#reject-invalid-inputs=v1) applies to
that database. If an operating-system permission refusal prevents a read
of one encoded file, that file's content is a missing part under
[input](sinter:#input=v1) and does not make the database invalid.

### Conforming program

@term conforming-program=v1
@cites #{
    design=v1, input=v1, dependence=v1, resource-limit=v1,
    safety-obligation=v1, end-runs-at-limits=v1,
    reject-invalid-inputs=v1, report-missing-parts=v1,
    give-results-over-canonical-objects=v1, read-defined-encodings=v1,
}

The **general requirements** are `end-runs-at-limits`,
`reject-invalid-inputs`, `report-missing-parts`,
`give-results-over-canonical-objects`, and `read-defined-encodings`.

A **conforming program** of a design is a program, or a part of a
program, that meets every requirement of that design together with the
general requirements. A **conforming program** of a specification of a
design is a program, or a part of a program, that meets every
requirement that the specification declares together with the general
requirements. Inside a specification of a design, a conforming program is
a conforming program of that specification. Elsewhere in a design, a
conforming program is a conforming program of that design.

Each obligation that a requirement of a design states with the word
`must` binds every conforming program of that design. When a
specification of a design declares a requirement, each obligation of
that requirement also binds every conforming program of that
specification. Each obligation of the general requirements binds every
conforming program of every design and of every specification.

For anything that an obligation of a requirement obliges a conforming
program to return or do—including an obligation to return nothing, to do
nothing, or to return no thing of a kind—that obligation binds the
conforming program only in a run in which the program reaches no
resource limit, and only when every input on which that thing depends is
valid and holds every part that that thing needs. These categories of
obligation bind a conforming program beyond that scope:

- Every safety obligation binds a conforming program always: under an
  invalid input, under a valid input that lacks a part, and in a run in
  which the program reaches a resource limit.
- Every obligation of `end-runs-at-limits` binds a conforming program
  always: under an invalid input, under a valid input that lacks a part,
  and in a run in which the program reaches a resource limit.
- In a run in which the program reaches no resource limit, when an input
  is invalid, every obligation of `reject-invalid-inputs` binds the
  conforming program, together with every obligation of a requirement of
  that input's owner design that states what a program returns or does
  when that input is invalid.
- In a run in which the program reaches no resource limit, when a valid
  input lacks a part, every obligation of `report-missing-parts` binds
  the conforming program, together with every obligation of a
  requirement that states what a program returns or does when a valid
  input lacks a part.

No other obligation binds a conforming program beyond that scope.

## Requirements

### Ending runs at resource limits

@req end-runs-at-limits=v1
@cites #{input=v1, resource-limit=v1, report=v1}

When a program reaches a resource limit, the program must end the run
(for a part of a program, that call). Unless the program's machine ends
the program before the program can report, the program must return one
report identifying where the program reached that limit, as far as the
machine permits. The program must return no other result of that run, and
must write nothing durable after the program reaches that limit. A
program must report no resource-limit stop that did not occur.

### Rejecting invalid inputs

@req reject-invalid-inputs=v1
@cites #{
    design=v1, input=v1, dependence=v1, resource-limit=v1, report=v1,
}

When a program takes an invalid input `I` for a requirement `R`, the
program must:

- return a report identifying which input is invalid and where, once for
  each invalid input unless a requirement of the owner design of `I` for
  `R` states otherwise; and
- return nothing and do nothing that depends on `I`, other than reports of
  invalid inputs, reports of resource-limit stops, and any output or
  action that a requirement of the owner design of `I` for `R` states
  for `I` when `I` is invalid.

A program must report no input that is valid for `R` as invalid for `R`.
When a requirement of the owner design of `I` for `R` states a report
for `I` when `I` is invalid, that report is the report of `I` for `R`.

### Reporting missing parts

@req report-missing-parts=v1
@cites #{design=v1, input=v1, dependence=v1, report=v1}

When a program takes a valid input `I` for a requirement `R` and a thing
that `R` obliges the program to return or do needs a part that `I` lacks,
the program must:

- return a report identifying which part is missing, once for each such
  missing part unless a requirement of the owner design of `I` for `R`
  or of the design that declares `R` states otherwise; and
- return nothing and do nothing that needs that part.

A program must report no part that `I` holds as missing. For every thing
that does not need that missing part, the program must still return and do
what the requirements oblige.

When a requirement of the owner design of `I` for `R` or of the design
that declares `R` states a report for that missing part, that report is
the report of that missing part for `R`. When both designs state a
report for that missing part, the report that the design that declares
`R` states governs for `R`. When two requirements of different designs
both need the same missing part and those designs state different
reports, the program must return each design's report for its requirement.

### Returning results over canonical objects

@req give-results-over-canonical-objects=v1
@cites #{
    design=v1, input=v1, dependence=v1, object=v1, encoding=v1,
    own-store=v1,
}

When a requirement `R` defines what a program returns or does over
objects, the program must return and do what `R` obliges for the set of
canonical objects held together by these inputs, and must return and do
nothing else for `R` in place of what `R` obliges:

- each valid input in an encoding from which the program reads objects
  for `R`; and
- each valid program's own store from which the program reads objects
  for `R`.

This requirement applies only to the part of what `R` obliges that `R`
defines from those canonical objects, and not to a part that `R` defines
from another property of an input, such as a file path, a file layout,
or the location in an input from which the program reads an object (such
as a line of a file). What a program returns or does for such a part
depends on that input.

The designs that define those kinds of object and those encodings govern
whether two valid inputs that hold different canonical objects conflict;
this requirement does not.

@example Suppose a design defines one [encoding](sinter:#encoding=v1)
that stores objects as source files in a directory tree and a second
encoding that stores objects of the same kinds in a file of records. A
person moves an object from the first encoding into the second encoding
without changing the object's canonical form
([object](sinter:#object=v1)), while all [inputs](sinter:#input=v1) stay
valid and hold every [needed](sinter:#dependence=v1) part, and the
program reaches no [resource limit](sinter:#resource-limit=v1). Both
input sets hold the same set of canonical objects, so results defined
over those canonical objects stay identical, whereas results defined
from a file path or a source line location can change.

### Reading defined encodings

@req read-defined-encodings=v1
@cites #{design=v1, input=v1, object=v1, encoding=v1, own-store=v1}

A program that meets a requirement `R` must read every object of a kind
that a valid input in an encoding holds when all of these conditions
hold:

- `R` defines what a program returns or does over objects of that kind;
- the design `D` that declares `R`, or a design that `D` cites directly
  or through a chain of citations, defines that encoding for objects of
  that kind; and
- the input is given to the program for `R`.

A program may read those objects from a valid program's own store in
place of inputs in encodings.

## Conformance

A program, or a part of a program, conforms to this design when it is a
[conforming program](sinter:#conforming-program=v1) of this design.
