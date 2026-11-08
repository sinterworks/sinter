<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Write all project text by rules modelled on Simplified Technical English
@decision ste-adoption v2
Every text in the repository, and the tool's own output, follows the writing rules of CONTRIBUTING.md, which take Simplified Technical English (ASD-STE100) in the style of Simple English Wikipedia as their model.

## Context

Coding agents write most of Sinter's text. Agent prose has three
common faults: invented jargon, several ideas compressed into one
phrase, and missing context. The readers are the people who use
Sinter or contribute to it, not the person who runs the agent. Those
readers do not share the agent's context.

ASD-STE100 limits a sentence to 20 words in a procedure and to 25
words in a description. A fixed limit makes a writer cut words that an
idea needs, or break an idea into parts that do not make sense alone.
Both make the text harder to follow. So Sinter keeps one idea in each
sentence. It sets no limit on the number of words.

## Decision

All text follows the rules in the "Writing" section of
CONTRIBUTING.md. In short: one idea in each sentence, with the length
that the idea needs; active voice and simple tenses; one word for one
meaning; no invented terms, and a definition at first use for a
necessary technical term; one clear referent for every pronoun;
context before detail; lists for sequences and tables for enumerable
facts; no notes that explain why a sentence or a file exists; no prose
that opens a document by explaining what the document is.

The rules apply to documentation, specifications, code comments,
commit messages, the tool's output, and an agent's replies to the
person it works with. Text reproduced from elsewhere — license
texts, the DCO, quoted standards — stays verbatim.

Reviewers check text against these rules. A reviewer can give a coding
agent a skill, a set of instructions for one task, that checks text
against ASD-STE100. Such a skill also reports each sentence above 20
or 25 words. Reviewers do not apply those limits.
This record is the origin for a future `ste-docs` rule (design notes
section 7).

## Alternatives considered

None were put forward, for this revision or for the first.

## Consequences

Every document costs more words than a dense draft, because a clear
explanation is longer than a compressed one. Reviews name the rule a
sentence breaks. Whether a sentence holds one idea is the reviewer's
judgment.
