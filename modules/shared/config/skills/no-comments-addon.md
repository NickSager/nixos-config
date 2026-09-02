
## Host-neutral reviewer delegation

When the host does not provide a named `Comment Sicko` agent, delegate the review to its generic worker mechanism. Give the worker the caller's scope or diff and require it to read the `comment-sicko` skill in full before reviewing. The worker must return only that skill's report and must not edit application code. Continue with the remaining steps after the report arrives.
