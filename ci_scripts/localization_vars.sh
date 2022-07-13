# Shared variables used in our localization scripts

# DO NOT EDIT! edit l10n/config.rb instead.

# TODO(ramont): Remove after migrating other scripts to Ruby.

# Directories for projects that need to be localized.
LOCALIZATION_DIRECTORIES=($(ruby -e "\$LOAD_PATH << Dir.pwd;require './ci_scripts/l10n/config';puts LOCALIZATION_DIRECTORIES"))

# Languages that we localize to
LANGUAGES=($(ruby -I . -e "\$LOAD_PATH << Dir.pwd;require './ci_scripts/l10n/config';puts LANGUAGES.join(',')"))
