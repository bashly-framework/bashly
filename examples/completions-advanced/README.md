# Advanced Runtime Completions Example

Demonstrates configured runtime completions, including static candidates,
dynamic external commands and internal functions, file and directory sources,
and the `no-space` option.

Runtime completions are enabled in `settings.yml`. Users can load the generated
wrapper for their shell with:

```bash
# Bash
source <(cli completions)

# Zsh
source <(cli completions zsh)
```

```fish
# Fish
cli completions fish | source
```

<!-- include: settings.yml src/completions_command.sh src/lib/completions.sh -->

-----

## `bashly.yml`

````yaml
name: cli
help: Advanced runtime completions example
version: 0.1.0

commands:
- name: completions
  help: Generate a shell completion script
  args:
  - name: shell
    help: Shell to generate completions for
    allowed: [bash, fish, zsh]
    default: bash

- name: deploy
  help: Deploy a branch
  args:
  - name: branch
    help: Branch to deploy
    required: true

    # Run an external Bash command and add each output line as a candidate.
    completions:
      dynamic:
      - git branch --format='%(refname:short)'
  - name: environment
    help: Environment to deploy to

    # Combine literal candidates with an internal function. Prevent the shell
    # from appending a space after the selected completion.
    completions:
      static: [staging, production]
      dynamic: [completion_environments]
      options: [no-space]
  flags:
  - long: --config
    arg: file
    help: Deployment configuration file

    # Ask the shell to add file and directory candidates.
    completions:
      options: [files]
  - long: --directory
    arg: path
    help: Deployment directory

    # Ask the shell to add directory candidates only.
    completions:
      options: [directories]
````
## `settings.yml`

````yaml
completions: full

````

## `src/completions_command.sh`

````bash
send_completions "${args[shell]}"

````

## `src/lib/completions.sh`

````bash
completion_environments() {
  printf 'development\nstaging\n'
}

````


## Output

### `$ ./cli completions | head -n3`

````shell
_cli_completions() {
  local completion_command="${COMP_WORDS[0]}"
  local completion_current="${COMP_WORDS[COMP_CWORD]:-}"


````

### `$ ./cli __complete ""`

````shell
completions
deploy
:options=


````

### `$ ./cli __complete deploy main st`

````shell
staging
:options=no-space


````

### `$ ./cli __complete deploy --config ""`

````shell
:options=files


````

### `$ ./cli __complete deploy --directory ""`

````shell
:options=directories


````
