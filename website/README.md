# cckg

Documentation for the Climate Change Knowledge Graph of the HACID project, published at https://hacid-project.github.io/cckg/


## Competency questions and example queries

The [Competency Questions](competency-questions.md) and [Example Queries](example-queries.md) pages are both generated from a single data file, [`_data/cqs.json`](_data/cqs.json).
Each competency question has a stable `id` (e.g., `CQ11`, rendered as the anchor `competency-questions#cq11`), a `category`, a short `title`, the `question` itself, and an optional list of `queries` that answer it.
A competency question without `queries` is shown as *not yet validated*.
