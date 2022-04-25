# containers

Ad-hoc containers that requires publishing images

## What

This is a common repository for container images that need to be published to be
used across repos -- so it's all pre-prepped, have a single place to audit and
harden security, as well faster on the CI and automatically published to Docker
Hub under the `defi` namespace.

## How

- Add image definition to, one of:
  - `<image>.dockerfile` if it's contextless dockerfile in the root
  - `<image>/Dockerfile` if it's takes the image dir is expected to have only a
  single docker file and the dir is the context.
  - `<category>/<image>.dockerfile` if the category is expected to have multiple
  dockerfiles.
- Templates are supported with go text templates and uses gomplate to process
  them all on the workflow on the context dir.
  - If you require templates files, just add a `.env` file in the context dir,
  with sane defaults for all the variables.
  - This is source and exported before running templates.
  - Additionally, `.env.override` file can be specified in the overflows to
  override the defaults.
- Create `.github/workflows/<image><-suffix>.yaml` from an existing file that
  reuses the `dockerize` workflow.
- Set the `dockerize` workflow inputs, and the workflow trigger `path` to be
  just the relevant files. If the dockerize input has `contextdir` set, it
  uses the templated path - otherwise, uses a context less file only build.
- Push. Images should be published to `defi/<image>` when the workflow is run
  successfully.

## Developer Notes

- Make sure to run `make check` before any commits. They also auto-set
  pre-commit hooks as needed.
- [Do not use short names for images](https://www.redhat.com/sysadmin/container-image-short-names).
  Use a registry qualified name: eg: `docker.io/rust` instead of `rust`.
- Keep it simple. Try not to change many defaults unless absolutely needed.
- Try to use major version numbers or `stable` tag, if provided as much as
  possible - eg: `docker.io/rust:1` instead of `rust:1.77` or `rust:latest`.
  Pinning version numbers to the minor or patch usually defeats the perception
  of security for well audited, maintained and open public images with
  established review processes. Do this when there's a good reason to do so
  (eg: single user controlled repository with insufficient review practices).
- Why Go Text templates? While others like handlebars are arguably simpler, and
  jinja / tera are more interesting, go templates are the defacto templating
  system in the devops world with k8s and docker. So using that avoid context
  switches, and go templates do strike the balance between simplicity and
  flexibility.
