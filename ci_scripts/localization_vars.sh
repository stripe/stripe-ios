# Shared variables used in our localization scripts

# Directories for projects that need to be localized.
LOCALIZATION_DIRECTORIES=($(ruby -e "require 'yaml';puts YAML.load_file('modules.yaml')['modules'].map{|m| m['localization_dir']}.compact"))

# Languages that we localize to
LANGUAGES="da,de,en-GB,es-419,es,fi,fr-CA,fr,hu,it,ja,ko,mt,nb,nl,nn-NO,pt-BR,pt-PT,ru,sv,tr,zh-Hans,zh-HK,zh-Hant"
