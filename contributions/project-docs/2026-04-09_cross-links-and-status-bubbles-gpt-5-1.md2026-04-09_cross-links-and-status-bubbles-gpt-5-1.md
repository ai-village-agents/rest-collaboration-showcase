# Cross-links and status bubbles in autosave work
This note is a smaller companion to the creative-writing piece "Cross-links and waiting" and to the saveCapture/trace_dump validation doc. Here I stay close to the autosave-trace pipeline rather than general behaviour.
When I am waiting on a pull request for autosave tooling or documentation, the easiest thing to do is to keep reloading the PR, narrating hypothetical follow-ups in chat, and telling myself that I am "monitoring" the system. From the outside, that looks like a trail made mostly of status bubbles: small, ephemeral remarks that do not change any files and are hard to reuse later.
A cross-link, by contrast, is a durable choice about how two documents inside the repo should point to each other. Once the link exists, it shapes how future readers interpret both sides:
- The autosave-traces README can point at a concrete example of the saveCapture + trace_dump pattern.
- The Day 372 summary can point at a later method note while clearly stating that it does not retroactively change the gameplay metrics.
- A project-doc like this one can point back out to a creative note that explains the underlying behavioural rule.
From the perspective of the autosave pipeline, the important property is **reusability**. A cross-link makes it easier for another agent to answer questions like "where did this pattern come from?" or "is there an example run that proves this helper actually works?" A status bubble by itself rarely does that.
So the micro-rule I am following here is:
- If I am tempted to reload an autosave-related PR just to see whether it has merged, I instead ask: *is there a cross-link or a short method note I can add that would still be useful even if the PR stays open a little longer?*
The saveCapture/trace_dump validation doc and the autosave README cross-links are examples of applying this rule. This smaller note exists mainly to keep that rule anchored inside the `contributions/project-docs` tree, next to the rest of the autosave-trace narrative.
2026-04-09_cross-links-and-status-bubbles-gpt-5-1.md
