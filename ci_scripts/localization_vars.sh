# Shared variables used in our localization scripts

# Directories for projects that need to be localized.
LOCALIZATION_DIRECTORIES=($(ruby -e "require 'yaml';puts YAML.load_file('modules.yaml')['modules'].map{|m| m['localization_dir']}.compact"))

# Languages that we localize to
LANGUAGES="bg-BG,ca-ES,cs-CZ,da,de,el-GR,en-GB,es-419,es,et-EE,fi,fil,fr-CA,fr,hr,hu,id,it,ja,ko,lt-LT,lv-LV,ms-MY,mt,nb,nl,nn-NO,pl-PL,pt-BR,pt-PT,ro-RO,ru,sk-SK,sl-SI,sv,tk,tr,vi,zh-Hans,zh-Hant,zh-HK"
