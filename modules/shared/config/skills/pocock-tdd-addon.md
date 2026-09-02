
## Pragmatic regression loop

Proceed without asking the user to confirm a seam when the public boundary is already clear and the choice is reversible. State the chosen seam before writing the test. Ask only when competing seams would materially change the public design or test cost.

For a bug fix, prove the regression red before changing production code, then prove the same check green afterward. Report both observations. If a durable failing test would require broad harness work, brittle mocks, slow infrastructure, production-only state, or unrelated fixture churn, state why it is impractical and use the closest executable check instead. A focused script, manual reproduction, log assertion, or existing integration check is preferable to a weak test.
