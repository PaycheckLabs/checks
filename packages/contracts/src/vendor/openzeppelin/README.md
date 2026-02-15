# OpenZeppelin vendored subset

This folder vendors a minimal subset of OpenZeppelin Contracts for the Checks Protocol contracts package.

- Upstream: OpenZeppelin Contracts v5.0.2
- License: MIT (see SPDX headers in each file)

Why vendored:
- We develop and patch via the GitHub UI.
- We avoid external dependency installs in Foundry for the monorepo scaffold stage.

If we later move to a local development workflow, we can replace this folder with a standard Foundry dependency install and remappings.
