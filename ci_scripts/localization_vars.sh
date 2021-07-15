# Shared variables used in our localization scripts

# Directories for projects that need to be localized.
# After adding a directory to this list,
# run `./ci_scripts/create_localizable_strings_files.sh` to create the directory
# structure and drag the resulting `Resources` folder into the project.
LOCALIZATION_DIRECTORIES=(
  "Stripe"
  "StripeCore/StripeCore"
  "StripeIdentity/StripeIdentity"
)

# Languages that we localize to
LANGUAGES="da,de,en-GB,es-419,es,fi,fr-CA,fr,hu,it,ja,ko,mt,nb,nl,nn-NO,pt-BR,pt-PT,ru,sv,tr,zh-Hans,zh-HK,zh-Hant"
