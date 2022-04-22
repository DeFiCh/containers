# containers

Ad-hoc containers that requires publishing images

## What

This is a common repository for container images that need to be published to be used across repos -- so it's all pre-prepped, have a single place to audit and harden security, as well faster on the CI and automatically published to Docker Hub under the `defi` namespace.

## How

- Add image defintion to, one of:
  - `<image>.dockerfile` if it's contextless dockerfile in the root
  - `<image>/Dockerfile` if it's takes the image dir is expected to have only a single docker file and the dir is the context.
  - `<category>/<image>.dockerfile` if the category is expected to have multiple dockerfiles.
- Templates are supported with go text templates and uses gomplate to process them all on the workflow on the context dir.
  - If you require templates files, just add a `.env` file in the context dir, with sane defaults for all the variables.
  - This is source and exported before running templates.
  - Additionally, `.env.override` file can be specified in the overflows to override the defaults.
- Create `.github/workflows/<image><-suffix>.yaml` from an existing file that reuses the `dockerize*` workflow.
- Set the `dockerize` workflow inputs, and the workflow trigger `path` to be just the relevant files.
- Push. Images should be published to `defi/<image>` when the workflow is run successfully.

## Notes

- [Do not use short names for images](https://www.redhat.com/sysadmin/container-image-short-names). Use a registry qualified name: eg: `docker.io/rust` instead of `rust`.
- Keep it simple. Try not to change to many default unless absolutely needed.
- Why Go Text templates? While others like handlebars are arguably simpler, and jinja / tera are more interesting, go templates are the defacto templating system in the devops world with k8s and docker. So using that avoid context switches, and go templates do strike the balance between simplicity and flexibility.
