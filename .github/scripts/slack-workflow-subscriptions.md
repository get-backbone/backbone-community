# Slack workflow notifications

Copy-paste commands for the [GitHub Slack app](https://github.com/integrations/slack).
Run these in the Slack channel that should receive alerts.

These subscriptions are **not** applied automatically — they are stored here so we can
review, edit, and re-apply them when setting up or fixing a channel.

## Prerequisites

- Use **straight ASCII double quotes** (`"`), not curly/smart quotes.
- Workflow `name` values must match the `name:` field in each workflow YAML exactly
  (including emoji).
- The GitHub app does **not** support failure-only or exclude filters. We whitelist
  workflows by `name` instead. See
  [GitHub docs](https://docs.github.com/en/integrations/how-tos/slack/customize-notifications#workflow-notification-filters).

Shared event and branch filters:

```text
event:"push","schedule","workflow_dispatch","repository_dispatch" branch:"main"
```

Verify an active channel subscription:

```text
/github subscribe list features
```

## get-backbone/backbone-core

```text
/github unsubscribe get-backbone/backbone-core workflows
/github subscribe get-backbone/backbone-core workflows:{name:"02 🚧 Build and test","03 👊🏽 Auto version bump","03a 📦 Publish packages","04 📦 ECR image upload","05 🔨 INT runtime deploy","06 🧪 STAGE runtime deploy","07 🚀 PROD runtime deploy","09 🌐 Static site deploy","10 🐿️ Infra deploy","11 💤 Infra hibernate","50 🔎 Static analysis","51 ☘️ Code coverage","90 🗄️ OWASP db cache","91 🪩 Mirror platform repo","92 📚 Mirror docs repo" event:"push","schedule","workflow_dispatch","repository_dispatch" branch:"main"}
```

## get-backbone/forge-kit

```text
/github unsubscribe get-backbone/forge-kit workflows
/github subscribe get-backbone/forge-kit workflows:{name:"01 🚧 Build and test","02 🔎 Static analysis","03 👊🏽 Auto version bump","04 📦 Publish packages","51 ☘️ Code coverage","100 🗄️ OWASP cache" event:"push","schedule","workflow_dispatch","repository_dispatch" branch:"main"}
```

## Maintenance

When adding or renaming a numbered workflow:

1. Update the workflow `name:` in the YAML if needed.
2. Add or update the row in the table above.
3. Regenerate the `/github subscribe` command `name` list.
4. Re-run unsubscribe + subscribe in Slack.

Excluded by design (noisy or out of scope): `00` hygiene checks, `98`/`99` janitors,
and other numbered workflows not listed above.
