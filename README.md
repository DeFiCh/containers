# containers
Ad-hoc containers that requires publishing images

## What

This is a common repository for container images that need to be published to be used across repos -- so it's all pre-prepped, have a single place to audit and harden security, as well faster on the CI and automatically published to Docker Hub on the
under the `defi` namespace.

## How

- Write a `<image>.dockerfile`
- Create `.github/workflows/<image>.yaml` from an existing file that reuses the `dockerize*` workflow.
- Set the `dockerize` workflow inputs, and the workflow trigger `path` to be just the relevant files.
- Done

## Notes

- [Do not use short names for images](https://www.redhat.com/sysadmin/container-image-short-names). Use a registry qualified name: eg: `docker.io/rust` instead of `rust`.
- Keep it simple. Try not to change to many default unless absolutely needed.
