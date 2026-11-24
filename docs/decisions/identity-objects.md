<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Name every thing by content id in objects and edges, with identity objects and one form of edge
@decision identity-objects
@cites canonical-objects
Every link of every object is an edge `{"kind","to"}` in one member `edges`, every `to` is a content id, and a name, an external item, a vector set, a group, or a pin with no single exact object is a small computed identity object; work items are nonce objects; and five rules of regularity hold for every kind.

## Context

Record `canonical-objects` gives every object of Sinter one content id.
The terms of this record come from the Ontology (`docs/designs/ontology.md`). The first form of those objects still let an edge name a
named thing by its name alone, gave edges scalar members such as
`every-part` and `outcome`, and used different member names for
different relations. Code that walks the graph and checks the hashes then
has to know each kind. A task also had no stable thing to name: its id
was a random text, and its agreement was a task hash that no edge could
name. Sinter is also to keep an index of the graph as a cached database,
which is simplest when every place refers to things by one id.

## Decision

- **One form of edge.** Every link of every object lives in the member
  `edges`, which is absent when empty. Each element is exactly
  `{"kind","to"}`, with no other member, and every `to` is a content id.
- **Computed identity objects.** A name of a declared item, an external
  item, a vector set, and a group are each a computed identity object
  (`name`, `ext`, `vector-set`, `vector-group`), whose content follows
  from its key. A group's `cites` edges live on its group description
  object `vector-group-def`, which names its `vector-group` with
  `about`. A pin that has no single exact object, such as a pin on a
  cycle, a pin to an undeclared name, or a pin that matches two kept
  objects, is a `pin` object. When an input holds that `pin` object, a
  text citation `@cites pin:…` gives the same canonical edge as the name
  and label that the object holds, and a stored edge to `pin:…` in
  `.sinter/` stays as it is and resolves to that name and label. A
  `pin:` id whose object no input holds gives `dangling`. No void
  withdraws an identity object.
- **Exact pins stand.** A pin to an exact object names it, so an edit in
  place still asks every citing item for a revision.
- **Work items.** A task or a plan is a nonce object (`task`, `plan`)
  with 32 random hexadecimal digits. Its definitions are `task-def` and
  `plan-def`. A `scope` object holds a definition's paths and promises
  and names its task; its content hash replaces the task hash.
- **Replacement words.** `revises` names every replacement within one
  thing. `supersedes` names only a different declared item that an item
  replaces.
- **Same item.** Two declared items of two trees are the same item when
  they have the same name, whatever their kinds.
- **Five rules of regularity:**
  1. one word for each kind, used as the kind word of its ids;
  2. every list is a set, sorted by the code point order of the
     canonical form of its elements, unless it is declared a sequence;
     `paths` is a set;
  3. one edge, `about`, names the thing that an object describes;
  4. one schema table in the Ontology holds all 25 kinds, with a column
     for `.sinter/` and a column for the log branch;
  5. a fixed rule says which objects carry `by`: every record, and no
     item, identity object, scope, group description, or kept object.
- **Specifications** hold their items with `items` edges.
- **Closure by key.** `.sinter/` holds each computed identity object
  that the edges of a stored object name, and the log branch holds each
  computed identity object that the edges of a kept declared item name,
  unless the naming object holds the key itself. A missing computed
  identity object holds back only the results that need its key, when no
  input of the run gives that key.
- **Changes in a check.** Interchange gives, for a check of a change,
  each object that the change adds to `.sinter/`, and then each identity
  object that their edges name and that the change did not add.

## Alternatives considered

- **Separate links, or one named member for each relation.** Put forward
  and not chosen in favor of one member `edges`; no further reason was
  recorded.
- **A kind may add scalar members to its edges, or an edge holds `to` or
  `ref`.** Not chosen: generic code and the table of kinds would allow
  per-kind members, the pattern that removing `every-part` and `outcome`
  ended, and two element forms break the rule of one form.
- **Identity objects for work items only.** Not chosen: one id in every
  place makes an index with content ids as primary keys straightforward,
  and it keeps every label that persons read in the text files, while
  objects and edges carry only ids.
- **A member for the stated kind on `ext`.** Not chosen: it splits one
  external item into several identity objects.
- **Nonce objects for declared items too.** Not chosen: it ends plain
  authoring in markdown, lets a copied nonce take over an item, breaks
  forward promises, and makes results depend on the encoding.
- **No object for a pin with no exact object, or a wider form.** Not
  chosen: the first withholds results for a requirement that cites its
  own specification and breaks `dangling` over canonical objects; the
  second changes two ruled answers on missing parts.
- **Every pin names a name and a label.** Not chosen: with exact pins,
  an approval covers the exact bytes of every item that it pins, and the
  request for a revision reports a true fact.
- **A text citation `@cites pin:…` keeps its pin object in the edge.**
  Not chosen: `@cites pin:…` and `@cites n=l` would give different
  canonical edges and hashes for the same structure.
- **Same item only for the same kind and name.** Not chosen: it forces
  changes in Revisions, makes a void the way to change a term into an
  atom, and rules out identity objects for names.
- **The word `holds` for a specification's edge.** Put forward and not
  chosen, in favor of `items`, although every other edge kind reads from
  its source as a verb or a relation word; no further reason was
  recorded.
- **No list of a change's new objects in v0.1, or a finding for each new
  object.** Not chosen: the first hides what a change promises, and the
  second gives findings that report no problem.

## Consequences

Code walks the whole graph and checks its hashes without knowing the
kinds. The index of Sinter can use content ids as primary keys and edges
as rows that name two content ids, and views can show the keys of
identity objects in place of ids. An item's content id changes when a
cycle of pins forms or breaks, or when an ambiguous pin is settled. The
schemas of identity objects stay at `v: 1`. Tests, sites, persons,
agents, findings, and commits get no identity objects in v0.1.
