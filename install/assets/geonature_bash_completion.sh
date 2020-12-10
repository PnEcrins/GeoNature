#!/usr/bin/env bash

# Bash completion for GeoNature command line
# To use, add "source ~/<path-to-completion-file>/geonature_completion" in your ~/.bashrc file

[ "$BASH_VERSION" ] || return

if ! command -v nvm &> /dev/null; then
  return
fi

function __geonature_commands() {
	declare current_word
	declare command

	current_word="${COMP_WORDS[COMP_CWORD]}"
	previous_word="${COMP_WORDS[COMP_CWORD-1]}"

	local readonly OPTS="--help"
	local readonly COMMANDS='
		activate_gn_module deactivate_gn_module dev_back
		dev_front frontend_build generate_frontend_config generate_frontend_modules_route
		generate_frontend_tsconfig generate_frontend_tsconfig_app
		install_gn_module start_gunicorn supervisor test update_configuration
		update_module_configuration'

	case "${current_word}" in
		-*) __gn_options ;;
		*) __gn_generate_completion "${COMMANDS}" ;;
	esac
}

function __gn_options() {
	case "$previous_word" in
        geonature)
            OPTIONS="--version" ;;
		activate_gn_module | deactivate_gn_module)
			OPTIONS="--backend --frontend" ;;
		dev_back)
			OPTIONS="--host --port --conf-file" ;;
		frontend_build)
			OPTIONS="--build-sass" ;;
		generate_frontend_config)
			OPTIONS="--conf-file --build" ;;
		install_gn_module)
			OPTIONS="--conf-file --build --enable_backend" ;;
		start_gunicorn)
			OPTIONS="--conf-file --uri --worker" ;;
		supervisor)
			OPTIONS="--action --app_name" ;;# TODO: add actions names
		update_configuration)
			OPTIONS="--conf-file --build --prod" ;;
		update_module_configuration)
			OPTIONS="--build --prod" ;;
		*)
			OPTIONS="" ;;
	esac

	OPTIONS="${OPTIONS} --help"
	__gn_generate_completion "${OPTIONS}"
}

function __gn_generate_completion() {
  declare current_word
  current_word="${COMP_WORDS[COMP_CWORD]}"
  # shellcheck disable=SC2207
  COMPREPLY=($(compgen -W "$1" -- "${current_word}"))
  return 0
}

# complete is a bash builtin, but recent versions of ZSH come with a function
# called bashcompinit that will create a complete in ZSH. If the user is in
# ZSH, load and run bashcompinit before calling the complete function.
if [[ -n ${ZSH_VERSION-} ]]; then
  autoload -U +X bashcompinit && bashcompinit
  autoload -U +X compinit && if [[ ${ZSH_DISABLE_COMPFIX-} = true ]]; then
    compinit -u
  else
    compinit
  fi
fi

complete -o default -F __geonature_commands geonature
