# frozen_string_literal: true

require 'yaml'

# The language that we use for development.
DEVELOPMENT_LANGUAGE = 'en'

# Languages that we localize to.
LANGUAGES = %w[
  bg-BG
  ca-ES
  cs-CZ
  da
  de
  el-GR
  en-GB
  es-419
  es
  et-EE
  fi
  fil
  fr-CA
  fr
  hr
  hu
  id
  it
  ja
  ko
  lt-LT
  lv-LV
  ms-MY
  mt
  nb
  nl
  pl-PL
  pt-BR
  pt-PT
  ro-RO
  ru
  sk-SK
  sl-SI
  sv
  th
  tr
  vi
  zh-Hans
  zh-Hant
  zh-HK
].freeze

LOCALIZATION_DIRECTORIES = YAML.load_file('modules.yaml')['modules'].map do |m|
  m['localization_dir']
end.compact.freeze

LOKALISE_FILENAMES = LOCALIZATION_DIRECTORIES.map do |d|
  "#{d}/Resources/Localizations/%LANG_ISO%.lproj/Localizable.strings"
end.compact.freeze