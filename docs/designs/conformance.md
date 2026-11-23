<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Conformance
@design conformance=v1
Specifies, as used in Sinter, designs, definitions, specifications, requirements, inputs and their owner designs, dependence, a program's own limits, reports, safety obligations, objects and their canonical forms, encodings, a program's own stores, conforming programs, and general requirements on a program's own limits, inputs that are not valid, valid inputs that lack a part, results over canonical objects, and defined encodings.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [design](sinter:#design=v1) | a document of Sinter that declares items under names, each with a kind and a revision |
| [declared item](sinter:#design=v1) | a named unit that a design declares as a specification, a requirement, a term, a schema, or an atom |
| [definition](sinter:#design=v1) | a term, a schema, or an atom that a design declares under a name |
| [term](sinter:#design=v1) | a definition that a design declares under a name, such as `input`, that says what a word or phrase means, gives a grammar rule that other rules use, or defines a computed value |
| [schema](sinter:#design=v1) | a definition that a design declares under a name that gives the form of a concrete thing that crosses the edge of a program, or the form of a file of test cases for a design: its layout and every constraint that is a property of the thing itself |
| [atom](sinter:#design=v1) | a definition that a design declares under a name that defines a named result that a program gives, with the condition under which the program gives that name |
| [specification](sinter:#specification=v1) | a declared item of the kind specification that has a name of its own and declares some of the requirements and definitions of a design |
| [requirement](sinter:#requirement=v1) | a declared item of the kind requirement that a design declares under a name, such as `report-stops-at-limits`, and that states one or more obligations of a program with the word must |
| must | the word with which a [requirement](sinter:#requirement=v1) states an obligation of a [conforming program](sinter:#conforming-program=v1) |
| [input](sinter:#input=v1) | a thing that a program takes for a requirement, such as a file or an argument of a command; an input is not valid when its owner design says that such a thing is not valid or when it supplies code that never ends (including, for a program, code that the program ends because that code reached a bound of the program on time, on steps, or on call depth); an input can also have parts, such as the commits of a history or the files of a folder tree, and content that a program could not take while the program reads the input—when the system refuses a permission, reports an input or output error, or offers no operation that lets the program take that content while the program keeps every safety obligation that binds the program (other than from a resource bound, a refusal or restriction that the program itself causes, or content that the program takes on a later attempt in the same run)—is a part that a valid input can lack |
| [owner design](sinter:#input=v1) | for a requirement, the design that defines the thing as which that requirement names an input |
| [depends on](sinter:#dependence=v1) | a thing that a program gives or does depends on an input, a part of an input, or a reading or computation when a change to that input or part can change what a requirement obliges for that thing, or when the program computes or chooses that thing from it |
| [needs](sinter:#dependence=v1) | which parts of a valid input a thing that a requirement obliges requires, as the owner design or the declaring design says, or by default every part on which that thing depends |
| [limit of a program's own](sinter:#own-limit=v1) | a bound of a program, of its run, or of its machine on a resource that the program uses, such as size, memory, time, or depth; a feature that a program lacks, code that never ends, and any condition that makes content a part that an input lacks under [input](sinter:#input=v1) are not limits of a program's own |
| [report](sinter:#report=v1) | a thing that a program gives to identify a stop at a limit of its own, an input that is not valid, or a missing part of a valid input |
| [safety obligation](sinter:#safety-obligation=v1) | an obligation of a requirement that states that a program reads, alters, writes, follows, or runs no thing other than the things that the requirement allows, or gains no permission; that a program never gives an answer that permits an action to proceed; or that a program ends code or an operation that the program runs |
| [object](sinter:#object=v1) | a thing of a kind that a design defines as a kind of object by citing `object` and stating that things of that kind are objects; each object has one canonical form |
| [canonical form](sinter:#object=v1) | the single form, defined by the design that defines a kind of object, as a value of a kind that a design defines |
| [canonical object](sinter:#object=v1) | an object in its canonical form |
| [encoding](sinter:#encoding=v1) | a form, defined by a design, in which objects are stored in an input; that design says what constitutes one input in that encoding, when such an input is valid, and which canonical objects a valid input in that encoding holds |
| [program's own store](sinter:#own-store=v1) | a store that a program chooses and uses, whose storage form no design defines, such as a database, an index, or a service, from which the program takes objects; it is valid when, and only when, each thing it holds as an object is a canonical object and, when the program takes objects of some kinds from it in place of inputs in encodings, each such input is valid and the store holds the same canonical objects of those kinds as those inputs hold together, with no canonical object of those kinds added, altered, or omitted; a part that the store or such an input lacks under [input](sinter:#input=v1) does not make the store not valid |
| [conforming program](sinter:#conforming-program=v1) | a program, or a part of a program, that meets every requirement of a design (or every requirement that a specification of a design declares), together with `report-stops-at-limits`, `end-runs-at-limits`, `reject-invalid-inputs`, `report-missing-parts`, `give-results-over-canonical-objects`, and `read-defined-encodings`; the term says under which inputs and limits each obligation binds |

## 2. Designs, conforming programs, inputs, and canonical objects

### 2.1 Designs, specifications, requirements, and conforming programs

A design is a document of Sinter that declares items under names, each
with a kind and a revision (term `design`). A definition of a design is
a term, a schema, or an atom that the design declares under a name, such
as `input`. A requirement is a declared item of the kind requirement
that a design declares under a name, such as `report-stops-at-limits`,
and that states one or more obligations of a program with the word must
(term `requirement`). A specification of a design is a declared item of
the kind specification that has a name of its own and that declares
some of the requirements and definitions of the design (term
`specification`). Only declared definitions and requirements are
normative; explanatory prose and glossary rows declare no item.

A conforming program of a design is a program, or a part of a program,
that meets every requirement of the design together with the general
requirements that the term `conforming-program` lists. A conforming
program of a specification meets every requirement that the
specification declares, together with those general requirements, and
the conforming program need not meet the remaining requirements of the
design. So one program can hold conforming programs of several designs
and of several specifications. In a specification of a design, a
conforming program is a conforming program of that specification.
Elsewhere in a design, a conforming program is a conforming program of
that design.

For example, suppose a program reads a file of 10 GB and stops reading
that file at a limit of its own on memory. The program ends that run
(for a part of a program, that call), reports where it reached that
limit as far as it can (`report-stops-at-limits`, `end-runs-at-limits`),
gives no other result of that run, and writes nothing durable
(`end-runs-at-limits`). In that run, safety obligations,
`report-stops-at-limits`, and `end-runs-at-limits` still bind; every
other obligation binds only in a run in which the program reached no
limit of its own (term `conforming-program`).

### 2.2 Inputs and missing parts

An input is a thing that a program takes for a requirement, such as a
file or an argument of a command (term `input`). Each requirement names
the thing as which a program takes each input of that requirement, and
the design that defines that thing is the owner design of that input for
that requirement. That owner design says when such a thing is not valid.
An input that supplies code that never ends is not valid for every owner
design. For example, a design can define a document and say when a
document is not valid. When a program takes a document that is not valid
for a requirement, the program reports which input is not valid and
where, once for that input (unless a requirement of the owner design
states otherwise), reports no valid input as not valid, gives nothing
that depends on that document, and does nothing that depends on that
document (`reject-invalid-inputs`).

An input can also have parts, such as the commits of a history or the
files of a folder tree. The owner design of an input defines which parts
a valid input can lack, and the term `dependence` says which things need
which parts. For example, a valid history can lack older commits. When a
program takes that history for a requirement, the program reports which
part is missing, gives nothing and does nothing that needs the missing
commits, and gives and does every thing that does not need those missing
commits (`report-missing-parts`).

The term `input` also states when content that a program could not take
is a part that a valid input lacks. For example, suppose a program reads
a folder tree of files, and for one file the system refuses the program
permission to read that file, reports a device error, or rejects as not
supported every operation that lets the program read that file while the
program keeps every safety obligation that binds the program. The folder
tree stays valid and lacks that file's content (term `input`). When a
thing that a requirement obliges needs that file's content, the program
reports which file it could not read, gives nothing that needs that
file's content, and does nothing that needs that file's content. In
every case, the program gives and does every thing that does not need
that file's content (`report-missing-parts`). By contrast, when the
program stops reading that file because the file is too large for the
program's memory, the program reaches a limit of its own (term
`own-limit`), ends that run (for a part of a program, that call),
reports where it reached that limit as far as it can
(`report-stops-at-limits`, `end-runs-at-limits`), gives no other result
of that run, and writes nothing durable (`end-runs-at-limits`).

### 2.3 Canonical objects, encodings, and a program's own stores

An object is a thing of a kind that a design defines as a kind of object
by citing `object` and stating that things of that kind are objects
(term `object`). Each kind of object has one canonical form, which the
design that defines that kind defines. An object in its canonical form
is a canonical object. Two objects are the same canonical object when,
and only when, their canonical forms are the same.

An encoding is a form, defined by a design, in which objects are stored
in an input (term `encoding`). The design that defines an encoding says
what constitutes one input in that encoding, when such an input is
valid, and which canonical objects a valid input in that encoding holds.
For example, a design can define one encoding that stores objects as
source files in a folder tree and a second encoding that stores objects
of the same kinds in a file of records.

When a requirement defines what a program gives or does over objects,
what the program gives and does is what that requirement obliges for the
set of the canonical objects that all valid encoding inputs and valid
program's own stores taken for that requirement hold together
(`give-results-over-canonical-objects`). Suppose a person moves an
object from one encoding into a second encoding without changing the
object's canonical form. Suppose also that, before and after the move, all inputs are valid and
hold every part that any obliged thing needs, and the program reaches no
limit of its own. Both sets of inputs hold the same set of canonical
objects. So, for each requirement that defines what a program gives or
does over objects, a conforming program gives and does the same things
before and after the move for every part that the requirement defines
from those canonical objects and not from any other property of those
inputs. Things that a requirement defines from another property of an
input can still change.
Examples are a result that depends on the path of a file, and a place in
an input that a requirement obliges a program to give for an object
(such as a line of a file).

When a requirement R defines what a program gives or does over objects
of a kind, a conforming program that meets R takes every object of that
kind from any valid input given for R in each encoding that the design
that declares R, or a design that it cites directly or through a chain
of citations, defines for objects of that kind
(`read-defined-encodings`). A conforming program can also take objects
from a program's own store, such as a database, an index, or a service,
whose storage form no design defines. The term `own-store` says when a
program takes a program's own store as an input and when a program's own
store is valid. For example, when a program takes objects from a
database in place of a folder tree's files, and that database omits an
object or alters a field of an object, that database is an input that is
not valid, so `reject-invalid-inputs` applies to that database.

## 3. Definitions

### 3.1 Designs

@term design=v1

A design is a document of Sinter that declares items under names, each
with a kind and a revision. A declared item is a named unit that a
design declares as one of these kinds: specification, requirement, term,
schema, or atom. Only declared definitions and requirements are
normative. Explanatory prose and glossary rows are not normative and
declare no item. A definition that uses the word must is still a
definition and not a requirement. An external standard is not a design.
A design may adopt definitions from an external standard that the design
cites; when a design does so, those definitions are part of what that
design defines.

A definition of a design is a term, a schema, or an atom that the design
declares under a name:

- A term says what a word or phrase means, gives a grammar rule that
  other rules use, or defines a computed value.
- A schema gives the form of a concrete thing that crosses the edge of a
  program, or the form of a file of test cases for a design: its layout
  and every constraint that is a property of the thing itself.
- An atom defines a named result that a program gives, with the
  condition under which the program gives that name.

### 3.2 Specifications

@term specification=v1
@cites #{design=v1}

A specification of a design is a declared item of the kind specification
that has a name of its own and that declares some of the requirements
and definitions of that design. A section of a design that is not
declared as an item of the kind specification is not a specification.

### 3.3 Requirements

@term requirement=v1
@cites #{design=v1}

A requirement is a declared item of the kind requirement that a design
declares under a name and that states one or more obligations of a
program with the word must.

### 3.4 Inputs

@term input=v1
@cites #{design=v1, requirement=v1, safety-obligation=v1}

An input is a thing that a program takes, such as a file or an argument
of a command. A program takes a thing as an input for a requirement R
when R names that thing as an input of something that R obliges the
program to give or do, or when the program supplies that thing as an
input for R.

Each requirement R names the thing as which a program takes each input
of R, such as a file, a document, or an argument of a command. The
design that defines that thing is the owner design of that input for R,
except when another definition of this design specifies the owner design
of that input. An input is not valid for R when its owner design for R
says that such a thing is not valid, or when that input supplies code
that never ends. Otherwise, that input is valid for R. An input that
supplies code that never ends is not valid for every owner design. When
a program ends code that an input supplies because that code reached a
bound of the program on time, on steps, or on call depth, that code
counts, for that program, as code that never ends. A property that a
design defines for a thing, such as whether a file is empty, makes an
input not valid for R only when the owner design of that input for R
says so.

An input can have parts, such as the commits of a history or the files
of a folder tree. The owner design of an input defines which parts such
an input has and which parts a valid input can lack.

For every owner design, unless one of the exceptions of this term holds,
the content that a program could not take while the program reads an
input or a part of an input is a part that the input lacks, and a valid
input can lack that part, when one of these conditions holds:

- the system refuses the program a permission;
- the system reports an input or output error; or
- the system offers no operation that lets the program take that content
  while the program keeps every safety obligation (term
  `safety-obligation`) that binds the program.

That content is not a part that the input lacks when one of these
exceptions holds:

- the refusal, the error, or the rejection of an operation comes from a
  bound of the program, of its run, or of its machine on a resource,
  such as a bound on open files, file size, memory, or time;
- the program itself gives up the permission, causes the refusal, or
  blocks or gives up the operations that the system would otherwise
  offer, such as by a sandbox that the program sets up; or
- the program takes that content on a later attempt in the same run.

When that content is a part that the input lacks, the input does not
hold that part, and neither lacking that part nor that content makes the
input not valid.

Here, the content of an input includes what the system gives about that
input or its parts, such as folder entries, file types, and bytes. Here,
the system is anything outside the whole program through which the
program reads an input, such as the operating system or a storage
service. For a part of a program, the system is the same system as for
the larger program. A program, the libraries and the runtime that the
program uses, and any other program that the program runs are not part
of the system. An input or output error is a fault of the system or of
its storage in giving the content of an input, such as a device error or
a lost connection. A report that content does not exist, or that content
does not decode in a form that a design defines, is not an input or
output error. The system offers no
operation that lets a program take content while the program keeps every
safety obligation that binds the program when the system provides no
such operation, or when the system or a part of the system (such as a
file system) rejects each such operation as not supported. Here, an
operation with one choice of options, such as one call with one set of
flags, is a different operation from the same operation with another
choice of options. A feature that a program lacks is not a lack of an
operation that the system offers. A feature that a library or a runtime
that the program uses lacks, or that another program that the program
runs lacks, is a feature that the program lacks. An operation that fails
because of a bound of the program, of its run, or of its machine on a
resource is not an operation that the system rejects as not supported.

### 3.5 Dependence

@term dependence=v1
@cites #{design=v1, requirement=v1, input=v1}

What a program gives or does includes any value, summary over several
inputs, exit status, report, or action. A thing that a program gives or
does depends on an input I when either of these conditions holds:

- A requirement defines that thing, and changing I, with every other
  input unchanged, can change what that requirement obliges the program
  to give or do for that thing.
- The program computes or chooses that thing from I.

In the same way, a thing that a program gives or does depends on a part
P of an input I when either of these conditions holds:

- A requirement defines that thing, and changing P, with the rest of I
  and every other input unchanged, can change what that requirement
  obliges the program to give or do for that thing.
- The program computes or chooses that thing from P.

When an input I lacks a part P—including content that the program could
not take under the term `input`—whether a thing that a program gives or
does depends on P is judged as if I held P and the program had taken P.

A thing that a program gives or does depends on a reading or computation
when what a requirement obliges the program to give or do for that thing
depends on an input or a part that the reading reads, or on the value
that the computation computes, or when the program computes or chooses
that thing from that reading or computation.

For a valid input I and a requirement R, the owner design of I for R, or
the design that declares R, says which things that R obliges a program
to give or do need which parts of I. When both of those designs say
whether a thing that R obliges needs a part of I, what the design that
declares R says governs. When neither of those designs says which parts
of I a thing that R obliges needs, that thing needs every part of I on
which that thing depends.

### 3.6 A program's own limits

@term own-limit=v1
@cites #{input=v1}

A limit of a program's own is a bound of the program, of its run, or of
its machine on a resource that the program uses, such as a bound on
size, memory, time, or depth. A feature that a program lacks is not a
limit of its own.

A program reaches a limit of its own when, and only when, the program
stops a reading or computation because of such a bound, or its machine
ends the program because of such a bound. Code that never ends makes the
input that supplies it not valid and is not a limit of a program's own,
so a program that ends code that never ends reaches no limit of its own
by ending that code. A condition that makes content a part that an input
lacks under the term `input` is not a limit of a program's own, so a
program reaches no limit of its own when it stops reading because such a
condition holds. For example, when the system reports an error for too
many open files and the program stops reading because of that error, or
when a program stops reading a file because the file is too large for
the program's memory, the program reaches a limit of its own.

### 3.7 Reports

@term report=v1
@cites #{design=v1, requirement=v1, input=v1, own-limit=v1}

A report is a thing that a program gives to identify a stop at a limit
of its own, an input that is not valid, or a missing part of a valid
input. Unless a requirement states the form of a report, a program may
give a report in any form that identifies the required fact, such as a
message, a structured output, an exit status, or a named result.

For a stop at a limit of a program's own, where the program reached that
limit is the reading or computation that stopped, together with the
input and a place in that input (in the terms that the owner design of
that input defines) when the stop occurred while reading or computing on
a place of an input. For an input that is not valid, where the input is
not valid is a place in that input in the terms that its owner design
defines, or the whole input when its owner design defines no finer place
for that input.

### 3.8 Safety obligations

@term safety-obligation=v1
@cites #{requirement=v1}

A safety obligation is an obligation of a requirement that states one of
these things:

- that a program reads, alters, writes, follows, or runs no thing other
  than the things that the requirement allows, or gains no permission,
  where such a thing is, for example, a file, a symbolic link, a stored
  record, or code that the program takes from a file or from another
  program;
- that a program never gives an answer that permits an action to
  proceed; or
- that a program ends code or an operation that the program runs.

### 3.9 Objects

@term object=v1
@cites #{design=v1}

A design defines a kind of thing as a kind of object when, and only
when, a definition of that design cites this term (`object`) and states
that things of that kind are objects. A thing of any other kind—even
when a standard or a design calls it an object—is not an object in this
sense.

An object is a thing of a kind that a design defines as a kind of
object. For each kind of object, the design that defines that kind
defines one canonical form for objects of that kind. That canonical form
is a value of a kind that a design defines, such as a text, a byte
sequence, or a structured value. Two canonical forms are the same when,
and only when, they are the same value of that kind. A canonical object
is an object in its canonical form. Two objects are the same canonical
object when, and only when, their canonical forms are the same.

### 3.10 Encodings

@term encoding=v1
@cites #{design=v1, input=v1, object=v1}

An encoding is a form, which a design defines, in which objects are
stored in an input. The design that defines an encoding says what
constitutes one input in that encoding (such as a single file or a whole
folder tree), when an input in that encoding is valid, and which
canonical objects a valid input in that encoding holds.

### 3.11 A program's own stores

@term own-store=v1
@cites #{design=v1, requirement=v1, input=v1, object=v1, encoding=v1}

A program's own store is a store that a program chooses and uses, whose
storage form no design defines—such as a database, an index, or a
service—from which the program takes objects. A program takes a
program's own store as an input for a requirement R when, and only when,
the program takes an object from that store for R. This design defines
what a program's own store is, though no design defines its storage
form, so this design is the owner design of a program's own store.

A program's own store is valid when, and only when, it meets both of
these conditions:

- Each thing that the store holds as an object is a canonical object.
- When a program takes objects of some kinds from the store in place of
  the objects of those kinds from one or more inputs in encodings, each
  of those inputs is valid, and the store holds the same canonical
  objects of those kinds as those inputs hold together, with no
  canonical object of those kinds added, altered, or omitted.

Otherwise, the program's own store is not valid. A part that the store
or one of those inputs in encodings lacks under the term `input` because
the program could not take its content does not count as an object that
the store adds, alters, or omits, and does not make the store not valid.

### 3.12 Conforming programs

@term conforming-program=v1
@cites #{
    design=v1, specification=v1, requirement=v1, input=v1,
    dependence=v1, own-limit=v1, safety-obligation=v1,
    report-stops-at-limits=v1, end-runs-at-limits=v1,
    reject-invalid-inputs=v1, report-missing-parts=v1,
    give-results-over-canonical-objects=v1, read-defined-encodings=v1,
}

A part of a program is a component of a larger program, such as a
library or a subsystem, whose edge is the interface through which the
larger program passes inputs to that component and receives what that
component gives, together with any external state that that component
reads, alters, writes, follows, or runs. For a part of a program, a run
is one call of that part.

A conforming program of a design is a program, or a part of a program,
that meets every requirement of the design, `report-stops-at-limits`,
`end-runs-at-limits`, `reject-invalid-inputs`, `report-missing-parts`,
`give-results-over-canonical-objects`, and `read-defined-encodings`. A
conforming program of a specification of a design is a program, or a
part of a program, that meets every requirement that the specification
declares, `report-stops-at-limits`, `end-runs-at-limits`,
`reject-invalid-inputs`, `report-missing-parts`,
`give-results-over-canonical-objects`, and `read-defined-encodings`. In a
specification of a design, a conforming program is a conforming program
of that specification. Elsewhere in a design, a conforming program is a
conforming program of that design.

Each obligation that a requirement of a design states with the word must
is an obligation of each conforming program of that design. When a
specification of a design declares a requirement of that design, each
obligation that the requirement states with the word must is also an
obligation of each conforming program of that specification. Each
obligation that `report-stops-at-limits`, `end-runs-at-limits`,
`reject-invalid-inputs`, `report-missing-parts`,
`give-results-over-canonical-objects`, or `read-defined-encodings`
states with the word must is an obligation of each conforming program of
every design and of every specification of a design.

For anything that an obligation of a requirement obliges a conforming
program to give or do—including an obligation to give nothing, to do
nothing, or to give no thing of a kind—that obligation binds the
conforming program only in a run in which the conforming program
reached no limit of its own, and only when each input on which that
thing depends is valid and holds every part that that thing needs. Four
kinds of obligation bind a conforming program beyond that scope:

- A safety obligation binds a conforming program always: under an input
  that is not valid, under a valid input that lacks a part, and in a run
  in which the conforming program reached a limit of its own.
- Each obligation of `report-stops-at-limits` and `end-runs-at-limits`
  binds a conforming program always: under an input that is not valid,
  under a valid input that lacks a part, and in a run in which the
  conforming program reached a limit of its own.
- In a run in which the conforming program reached no limit of its own,
  each obligation of `reject-invalid-inputs` binds the conforming
  program when an input is not valid, and each obligation of a
  requirement of the owner design of an input that itself states what a
  program gives or does when that input is not valid binds the
  conforming program when that input is not valid.
- In a run in which the conforming program reached no limit of its own,
  each obligation of `report-missing-parts`, and each obligation of a
  requirement that itself states what a program gives or does when a
  valid input lacks a part, binds the conforming program when a valid
  input lacks a part.

No other obligation binds a conforming program beyond that scope.

## 4. Requirements

### 4.1 A program's own limits

@req report-stops-at-limits=v1
@cites #{own-limit=v1, report=v1}

When a program reaches a limit of its own, unless its machine ends the
program before the program can report, the program must report where the
program reached that limit, once for each stop at a limit of its own. A
program must report no stop at a limit of its own that did not occur.

### 4.2 Runs that reach a limit

@req end-runs-at-limits=v1
@cites #{own-limit=v1, report=v1}

When a program reaches a limit of its own, the program must end that run
(for a part of a program, that call), report where the program reached
that limit as far as the program can, give no other result of that run,
and write nothing durable.

### 4.3 Inputs that are not valid

@req reject-invalid-inputs=v1
@cites #{
    design=v1, requirement=v1, input=v1, dependence=v1, own-limit=v1,
    report=v1,
}

When a program takes an input I for a requirement R, and I is not valid
for R, the program must report which input is not valid and where, once
for each such input unless a requirement of the owner design of I for R
states otherwise, must give nothing that depends on I, and must do
nothing that depends on I. A program must report no input that is valid
for R as an input that is not valid for R. This requirement does not
forbid a report of which input is not valid and where, or a report of
where a program reached a limit of its own. This requirement also does
not forbid what a requirement of the owner design of I for R states that
a program gives or does for I in that case, and a report that such a
requirement states is the report of I for R.

### 4.4 Valid inputs that lack a part

@req report-missing-parts=v1
@cites #{design=v1, requirement=v1, input=v1, dependence=v1, report=v1}

When a program takes a valid input I for a requirement R, and a thing
that R obliges the program to give or do needs a part that I lacks, the
program must report which part is missing, once for each such missing
part unless a requirement of the owner design of I for R or of the
design that declares R states otherwise, must give nothing that needs
that part, and must do nothing that needs that part. A program must
report no part that I holds as missing. In that case, for each thing
that does not need that missing part, the program must give what the
requirements oblige the program to give for that thing and must do what
the requirements oblige the program to do for that thing. When a
requirement of the owner design of I for R, or of the design that
declares R, states a report for that missing part, that report is the
report of that missing part for R. When both of those designs state a
report for that missing part, the report that the design that declares R
states is the report of that missing part for R. When two requirements
of different designs both need the same missing part and those designs
state different reports, the program must give each design's report for
its requirement.

### 4.5 Results over canonical objects

@req give-results-over-canonical-objects=v1
@cites #{
    design=v1, requirement=v1, input=v1, dependence=v1, object=v1,
    encoding=v1, own-store=v1,
}

When a requirement R defines what a program gives or does over objects,
the program must give and do what R obliges the program to give and do
for the set of the canonical objects that all of these inputs hold
together, and must give and do no other thing for R in place of what R
obliges:

- each valid input in an encoding from which the program takes objects
  for R;
- each valid program's own store from which the program takes objects
  for R.

This requirement applies only to the part of what R obliges a program to
give or do that R defines from the canonical objects in that set, and
not from any other property of those inputs. This requirement does not
apply to a part of what R obliges a program to give or do that R defines
from a property of one of those inputs other than the canonical objects
that the input holds. Examples of such a property are the path of a
file, the layout of a file, and a place in an input from which the
program takes an object (such as a line of a file). What a program gives
or does for such a part depends on that input.

Because two objects with the same canonical form are the same canonical
object, a canonical object that two or more of those inputs hold appears
once in that set. Whether two valid inputs that hold different canonical
objects conflict is governed by the designs that define those kinds of
object and those encodings, not by this requirement.

### 4.6 Defined encodings

@req read-defined-encodings=v1
@cites #{
    design=v1, requirement=v1, input=v1, object=v1, encoding=v1,
    own-store=v1,
}

When a requirement R defines what a program gives or does over objects
of a kind, and the design that declares R or a design that it cites,
directly or through a chain of citations, defines an encoding for
objects of that kind, a program that meets R must take every object of
that kind that any valid input in that encoding holds when that input is
given to the program for R. A program may take those objects from a
valid program's own store in place of inputs in encodings.

## 5. Conformance

A program, or a part of a program, conforms to this design when it is a
[conforming program](sinter:#conforming-program=v1) of this design.
