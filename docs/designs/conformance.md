<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Conformance
@design conformance=v1
Specifies, as used in Sinter, designs, specifications, requirements, conforming programs, safety obligations, inputs, objects and their canonical forms, encodings and a program's own stores, and general requirements for conforming programs that report where they reach limits of their own, report inputs that are not valid and give and do nothing that depends on them, report missing parts of valid inputs and give and do nothing that needs them, give results over canonical objects, and read the encodings that designs define.

A design declares definitions and requirements under names, and a
specification is a named part of a design that declares some of those
definitions and requirements. A conforming program of a design meets
every requirement of that design together with five general requirements
on limits, inputs that are not valid, valid inputs that lack a part,
canonical objects, and encodings. A conforming program of a
specification meets every requirement that the specification declares
together with those five general requirements.

An input is a thing that a program takes, and its owner design says when
such a thing is not valid. An input can also have parts that some things
that a program gives or does need and that others do not need. An object
is a thing of a kind that a design defines as an object, with one
canonical form. An encoding is a form in which objects are stored as an
input that a design defines, and a program can also take objects from a
valid store of its own, such as a database, an index, or a service.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [definition](sinter:#design=v1) | a term, a schema, or an atom that a design declares under a name |
| term | a definition that a design declares under a name, such as `input`, that says what a word means, gives a grammar rule that is a building block, or defines a computed value |
| schema | a definition that a design declares under a name that gives the form of a thing that crosses the edge of a conforming program, or the form of a file of vectors and of its lines: its layout and every constraint that is a property of the thing itself |
| atom | a definition, declared by a design under a name, that defines a named verdict that a conforming program gives, with the condition under which it gives that name |
| [requirement](sinter:#requirement=v1) | an obligation that a design declares under a name, such as `report-stops-at-limits`, and states with the word must |
| [design](sinter:#design=v1) | a document that declares, each under a name, obligations and definitions |
| [specification](sinter:#specification=v1) | a part of a design that has a name of its own and declares some of the obligations and definitions of the design |
| [conforming program](sinter:#conforming-program=v1) | a program, or a part of a program, that meets every requirement of a design (or every requirement that a specification of a design declares), together with `report-stops-at-limits`, `reject-invalid-inputs`, `report-missing-parts`, `give-results-over-canonical-objects`, and `read-defined-encodings`; the term says for which inputs, and where, each requirement and each of its obligations binds |
| [safety obligation](sinter:#conforming-program=v1) | a requirement that states one of these things: that a conforming program reads, changes, or runs no thing other than the things that the requirement allows, or gains no permission, where such a thing is, for example, a ref, a ledger, a file, a symbolic link, or code that a repository supplies; that a conforming program never gives an outcome of a check that lets a change pass, such as "does not block"; or that a conforming program ends code or an operation that it runs |
| must | the word with which a [requirement](sinter:#requirement=v1) states an obligation of a [conforming program](sinter:#conforming-program=v1) |
| [input](sinter:#input=v1) | a thing that a program takes, such as a file or a binding of a parameter; an input is not valid when its owner design says that such a thing is not valid; an input can also have parts, such as the commits of a history or the objects of a git repository |
| [owner design](sinter:#input=v1) | the design that defines the thing as which a program takes an input |
| [object](sinter:#object=v1) | a thing of a kind that a design defines as an object; each object has one canonical form |
| [canonical form](sinter:#object=v1) | the single form that a design defines for an object |
| [canonical object](sinter:#object=v1) | an object in its canonical form |
| [encoding](sinter:#encoding=v1) | a form in which objects are stored as an input that a design defines; that design says when an input in that encoding is valid and which canonical objects a valid input in that encoding gives |
| [program's own store](sinter:#encoding=v1) | a store whose form no design defines, such as a database, an index, or a service, that a program takes as an input from which the program takes objects; it is valid when each thing it gives as an object is a canonical object and, when it stands for inputs in encodings, each such input is valid and the store gives the same canonical objects as those inputs |

## 2. Designs, conforming programs, inputs, and canonical objects

### 2.1 Designs, specifications, requirements, and conforming programs

A design is a document that declares, each under a name, obligations
and definitions. A definition of a design is a term, a schema, or an
atom that the design declares under a name, such as `input`. A
requirement is an obligation that a design declares under a name, such
as `report-stops-at-limits`, and states with the word must. A
specification of a design is a part of the design that has a name of its
own and that declares some of the obligations and definitions of the
design.

A conforming program of a design is a program, or a part of a program,
that meets every requirement of the design together with the five
general requirements `report-stops-at-limits`, `reject-invalid-inputs`,
`report-missing-parts`, `give-results-over-canonical-objects`, and
`read-defined-encodings` (term `conforming-program`). A conforming
program of a specification meets every requirement that the
specification declares, together with those five general requirements,
and the conforming program need not meet the remaining requirements of
the design. So one program can hold conforming programs of several
designs and of several specifications. In a specification of a design, a
conforming program is a conforming program of that specification.
Elsewhere in a design, a conforming program is a conforming program of
that design. Each obligation that a requirement states with the word
must is an obligation of each conforming program of the design that
declares the requirement. When a specification of that design declares
that requirement, that obligation is also an obligation of each
conforming program of that specification.

For example, a program that reads a file of 10 GB can reach a limit of
its own on memory. The program then reports where it reached that limit
(`report-stops-at-limits`), and requirements that depend on reading that
file do not fix what the program gives for that file (term
`conforming-program`). A program that takes an input that is not valid
follows `reject-invalid-inputs`, and the term `conforming-program` says
which obligations of `reject-invalid-inputs` bind where the program
reaches a limit of its own. A program that takes a valid input that
lacks a part follows `report-missing-parts`, and the term
`conforming-program` says which obligations of `report-missing-parts`
bind where the program reaches a limit of its own.

### 2.2 Inputs and missing parts

An input is a thing that a program takes, such as a file or a binding of
a parameter. The owner design of an input is the design that defines the
thing as which a program takes that input, and that design says when
such a thing is not valid (term `input`). For example, a design can
define a TOML document and say when a TOML document is not valid. When a
program takes a TOML document that is not valid, the program reports
which input is not valid and where, gives nothing that depends on that
document, and does nothing that depends on that document
(`reject-invalid-inputs`).

An input can also have parts, such as the commits of a history or the
objects of a git repository. The owner design of an input, or a design
whose requirement takes that input, says which things that a program
gives or does need which parts of that input (term `input`). For
example, a valid git repository can lack older commits of its history.
When a program takes that repository, the program reports which part is
missing, gives nothing and does nothing that needs the missing commits,
and gives every thing that does not need those missing commits
(`report-missing-parts`).

### 2.3 Canonical objects, encodings, and a program's own stores

An object is a thing of a kind that a design defines as an object, and
each object has one canonical form, which a design defines (term
`object`). An object in its canonical form is a canonical object. Two
objects are the same canonical object when their canonical forms are the
same.

An encoding is a form in which objects are stored as an input that a
design defines (term `encoding`). The design that defines an encoding
says when an input in that encoding is valid and which canonical objects
a valid input in that encoding gives. For example, a design can define
one encoding that stores objects as source files in a folder tree and a
second encoding that stores objects of the same kinds in a store of
records.

When a requirement defines what a program gives or does over objects,
those things depend only on the canonical objects
(`give-results-over-canonical-objects`). Suppose a repository moves an
object from one encoding into a second encoding without changing the
object's canonical form. Both inputs give the same canonical objects, so
a conforming program gives and does the same things for both inputs.

When a requirement takes objects of a kind for which designs define
encodings, a conforming program reads every encoding that those designs
define for objects of that kind (`read-defined-encodings`). A conforming
program can also take objects from a program's own store, such as a
database, an index, or a service, whose form no design defines. A
program's own store is valid only when it gives exactly the canonical
objects (term `encoding`). For example, a cache that omits an object
from a repository's files or alters a field of an object is an input
that is not valid, so `reject-invalid-inputs` applies to that cache. No
conforming program need read or keep any program's own store
(`read-defined-encodings`).

## 3. Definitions

### 3.1 Designs

@term design=v1

A design is a document that declares, each under a name, obligations
and definitions. A definition of a design is a term, a schema, or an
atom that the design declares under a name.

### 3.2 Specifications

@term specification=v1
@cites #{design=v1}

A specification of a design is a part of the design that has a name of
its own and that declares some of the obligations and definitions of
the design.

### 3.3 Requirements

@term requirement=v1
@cites #{design=v1}

A requirement is an obligation that a design declares under a name and
states with the word must.

### 3.4 Inputs

@term input=v1
@cites #{design=v1, requirement=v1}

An input is a thing that a program takes, such as a file or a binding of
a parameter. A program takes each input as one thing that a design
defines, such as a file, a TOML document, or a binding of a parameter.
That design is the owner design of that input. An input is not valid
when its owner design says that such a thing is not valid, and is valid
otherwise. A property that a design defines for a thing, such as whether
a file is empty, makes an input not valid only when the owner design of
that input says so. An input can have parts, such as the commits of a
history or the objects of a git repository. The owner design of an
input, or a design whose requirement takes that input, says which things
that a program gives or does need which parts of that input.

### 3.5 Objects

@term object=v1
@cites #{design=v1}

An object is a thing of a kind that a design defines as an object. Each
object has one canonical form, which a design defines. A canonical
object is an object in its canonical form. Two objects are the same
canonical object when, and only when, their canonical forms are the
same.

### 3.6 Encodings and a program's own stores

@term encoding=v1
@cites #{design=v1, input=v1, object=v1}

An encoding is a form in which objects are stored as an input that a
design defines. The design that defines an encoding says when an input
in that encoding is valid and which canonical objects a valid input in
that encoding gives.

A program's own store is a store whose form no design defines, such as a
database, an index, or a service, that a program takes as an input from
which the program takes objects. A program's own store is valid when,
and only when, it meets both of these conditions:

- Each thing that the store gives as an object is a canonical object.
- When the store stands for one or more inputs in encodings, each of
  those inputs is valid, and the store gives the same canonical objects
  as those inputs, with no canonical object added, changed, or omitted.

Otherwise, the program's own store is not valid.

### 3.7 Conforming programs

@term conforming-program=v1
@cites #{
    design=v1, requirement=v1, specification=v1, input=v1,
    report-stops-at-limits=v1, reject-invalid-inputs=v1,
    report-missing-parts=v1, give-results-over-canonical-objects=v1,
    read-defined-encodings=v1,
}

A conforming program of a design is a program, or a part of a program,
that meets every requirement of the design, `report-stops-at-limits`,
`reject-invalid-inputs`, `report-missing-parts`,
`give-results-over-canonical-objects`, and `read-defined-encodings`. A
conforming program of a specification of a design is a program, or a
part of a program, that meets every requirement that the specification
declares, `report-stops-at-limits`, `reject-invalid-inputs`,
`report-missing-parts`, `give-results-over-canonical-objects`, and
`read-defined-encodings`. In a specification of a design, a conforming
program is a conforming program of that specification. Elsewhere in a
design, a conforming program is a conforming program of that design.

Each obligation that a requirement of a design states with the word must
is an obligation of each conforming program of that design. When a
specification of a design declares a requirement of that design, each
obligation that the requirement states with the word must is also an
obligation of each conforming program of that specification. Each
obligation that `report-stops-at-limits`, `reject-invalid-inputs`,
`report-missing-parts`, `give-results-over-canonical-objects`, or
`read-defined-encodings` states with the word must is an obligation of
each conforming program of every design and of every specification of a
design.

For anything that a requirement obliges a conforming program to give or
do, that requirement binds the conforming program only when each input
on which that thing depends is valid and holds every part that that
thing needs, and only where the conforming program reaches no limit of
its own, such as a limit of the program or of its machine on size,
memory, time, or depth. Code that never ends is a fault of an input and
not a limit of a program, so a conforming program that ends code that
never ends reaches no limit of its own by ending that code. Four kinds
of requirement bind a conforming program beyond that scope:

- A safety obligation binds a conforming program always: under an input
  that is not valid, under a valid input that lacks a part, and where
  the conforming program reaches a limit of its own. A safety obligation
  is a requirement that states one of these things: that a conforming
  program reads, changes, or runs no thing other than the things that
  the requirement allows, or gains no permission, where such a thing is,
  for example, a ref, a ledger, a file, a symbolic link, or code that a
  repository supplies; that a conforming program never gives an outcome
  of a check that lets a change pass, such as "does not block"; or that
  a conforming program ends code or an operation that it runs.
- A requirement that itself states what a program gives or does at a
  limit of its own binds a conforming program where the conforming
  program reaches a limit of its own, whether or not the inputs are
  valid or hold every part.
- A requirement that itself states what a program gives or does under an
  input that is not valid binds a conforming program under an input that
  is not valid, where the conforming program reaches no limit of its
  own. The obligations of `reject-invalid-inputs` to give nothing that
  depends on an input that is not valid and to do nothing that depends
  on that input bind a conforming program also where the conforming
  program reaches a limit of its own. The obligation of
  `reject-invalid-inputs` to report which input is not valid, and where,
  binds only where the conforming program reaches no limit of its own.
- A requirement that itself states what a program gives or does when a
  valid input lacks a part binds a conforming program when a valid input
  lacks a part, where the conforming program reaches no limit of its
  own. The obligations of `report-missing-parts` to give nothing that
  needs a missing part and to do nothing that needs that part bind a
  conforming program also where the conforming program reaches a limit
  of its own. The obligation of `report-missing-parts` to report which
  part is missing, and its obligation for each thing that does not need
  that missing part, bind only where the conforming program reaches no
  limit of its own.

Where a conforming program reaches a limit of its own, only safety
obligations, requirements that themselves state what a program gives or
does at a limit of its own, the obligations of `reject-invalid-inputs`
to give nothing and to do nothing that depends on an input that is not
valid, and the obligations of `report-missing-parts` to give nothing and
to do nothing that needs a missing part fix what the conforming program
gives or does.

## 4. Requirements

### 4.1 A program's own limits

@req report-stops-at-limits=v1

When a program reaches a limit of its own, such as a limit of the
program or of its machine on size, memory, time, or depth, the program
must report where the program reached that limit.

### 4.2 Inputs that are not valid

@req reject-invalid-inputs=v1
@cites #{design=v1, requirement=v1, input=v1}

When a program takes an input that is not valid, the program must report
which input is not valid and where, must give nothing that depends on
that input, and must do nothing that depends on that input. This
requirement does not forbid a report of which input is not valid and
where, or a report of where a program reached a limit of its own. This
requirement also does not forbid what a requirement of the owner design
of that input states that a program gives or does for that input in that
case, and a report that such a requirement states is the report of that
input.

### 4.3 Valid inputs that lack a part

@req report-missing-parts=v1
@cites #{design=v1, requirement=v1, input=v1}

When a program takes a valid input I, and a thing that a requirement R
obliges the program to give or do needs a part that I lacks, the program
must report which part is missing, must give nothing that needs that
part, and must do nothing that needs that part. In that case, for each
thing that does not need that missing part, the program must give what
the requirements oblige the program to give for that thing. When a
requirement of the owner design of I, or of the design that declares R,
states a report for that missing part, that report is the report of that
missing part. When both of those designs state a report for that missing
part, the report that the design that declares R states is the report of
that missing part.

### 4.4 Results over canonical objects

@req give-results-over-canonical-objects=v1
@cites #{design=v1, requirement=v1, input=v1, object=v1, encoding=v1}

When a requirement R defines what a program gives or does over objects,
and the program takes objects from a valid input I that is in an
encoding or is a program's own store, the program must give what R
obliges the program to give for the canonical objects that I gives. In
that case, the program must also do what R obliges the program to do for
those canonical objects. The program must not change what it gives or
does for R based on which encoding or valid program's own store supplied
those canonical objects.

### 4.5 Defined encodings

@req read-defined-encodings=v1
@cites #{design=v1, requirement=v1, object=v1, encoding=v1}

When a requirement R takes objects of a kind for which one or more
designs define encodings, a program that meets R must read every
encoding that those designs define for objects of that kind. A program
may also take objects from a valid program's own store. A program need
not read or keep a program's own store.

## 5. Conformance

A program, or a part of a program, conforms to this design when it is a
[conforming program](sinter:#conforming-program=v1) of this design.
No requirement of section 4 names a result for an input, so there are no
conformance vectors.
