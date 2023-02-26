# Ansible Role: Template

[![CI](https://github.com/netr0m/ansible-role-template/workflows/CI/badge.svg?event=push)](https://github.com/netr0m/ansible-role-template/actions?query=workflow%3ACI)

Ansible role template

## Requirements

None

## Role Variables

Available variables are listed in [`docs/default-variables.md`](./docs/default-variables.md) (see [`defaults/main.yml`](./defaults/main.yml))

## Dependencies

None

## Example Playbook

```yml
---
- name: Example Playbook
  hosts: all
  become: true
  gather facts: true

  roles:
    - { role: netr0m.template }
...

```

## Development
This project uses [pre-commit](https://pre-commit.com/).

Currently, there are three hooks:
- [ansible-lint](https://pypi.org/project/ansible-lint/)
- [yamllint](https://pypi.org/project/yamllint/)
- [encryption-check](./scripts/encryption-check.sh)

To run `pre-commit` manually, run `pre-commit run -a`

### Requirements
To run pre-commit, you need three things:
1. A virtual environment in the parent directory of this repository
  - `$ python3 -m venv ../.venv`
  - `$ source ../.venv/bin/activate`
2. The Python dependencies (see [requirements.txt](./requirements.txt))
  - `$ pip install -r requirements.txt`
3. Pre-commit hooks installed
  - `$ pre-commit install`

### Updating the 'variables' docs
This project provides a script for generating markdown files representing ansible (YAML) variable definitions.

An example can be seen in [`docs/default-variables.md`](./docs/default-variables.md), which is generated from the variables defined in [`defaults/main.yml`](./defaults/main.yml).

#### Running the script
To run the generator, issue the following command. If no parameters are specified, this will generate a markdown file based on the variables in `defaults/main.yml`, and write it to `docs/default-variables.md`.

```sh
$ python3 generate-vars-md.py

# Display help message
$ python3 generate-vars-md.py --help

# Specify alternative input and output paths
$ python3 generate-vars-md.py --in-file vars/debian.yml --out-file docs/debian-vars.md --title "Debian Variables"
```

## License

[MIT](./LICENSE)

## Author Information

This role was created in 2022 by [netr0m](https://github.com/netr0m)
