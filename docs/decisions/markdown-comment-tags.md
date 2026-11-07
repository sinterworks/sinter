<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Read tags in an HTML comment in markdown
@decision markdown-comment-tags
A section or a list item in markdown can hold its tags in an HTML comment before its first paragraph, and the comment joins that paragraph as one block.

## Context

Sinter reads tags in the first paragraph of a section or a list item.
So a tag also shows on a published page, on GitHub, and in a site that
a tool builds from markdown. This cost stops a project from tracing
the pages that its readers see. Code already holds its tags in
comments.

## Decision

- An HTML comment that holds only tag lines is a tag-bearing node when
  it stands at the start of a section or a list item.
- The comment and the first paragraph after it are one block, so the
  paragraph stays the description of the tags.
- The delimiters of the comment are not part of an extent, so moving
  tags into a comment changes no extent hash.
- A first paragraph keeps its meaning. Both forms are valid.

## Alternatives considered

- **Keep the tags in the text of the page.** Not chosen: every reader
  of the page sees them.
- **A build step that removes tag lines from a published page.** Not
  chosen: each project needs a program for its site builder.
- **Tags in front matter.** Not chosen: mdBook shows front matter on
  the page, and a site builder that hides it still needs a place for a
  tag of a section or a list item.

## Consequences

A published page shows no sign of its tags, so a reader of the page
does not see the trace. A person who reads the source or a diff still
sees it. The reader of markdown has one more tag-bearing node.
