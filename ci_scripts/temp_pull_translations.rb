#!/usr/bin/env ruby
# encoding: utf-8
#
# Usage:
# $ ./ci_scripts/temp_pull_translations.rb `fetch-password PhraseApp-access-token`
# (running fetch-password from within this script causes strange dependency issues)
#
# PhraseApp has been updated with translations for `sources-ui`, so it is
# currently out of sync with `master`. Until `sources-ui` has been merged,
# we'll manually add new keys to PhraseApp. For an example localizations ask,
# see: https://jira.corp.stripe.com/browse/LOCAL-16
#
# Use this script instead of `pull_translations.sh` to bring in new translations.
# It will:
# 1. determine which new keys have been added locally
# 2. pull translations from PhraseApp
# 3. generate new .strings files:
#    - any existing translations that have changed on PhraseApp will be updated
#    - any new local keys that have translations on PhraseApp will be inserted

LOCALIZATIONS_DIR = "Stripe/Resources/Localizations"

def lproj(lang)
  "#{LOCALIZATIONS_DIR}/#{lang}.lproj"
end

def strings_file(lang)
  "#{lproj(lang)}/Localizable.strings"
end

def orig_strings_file(lang)
  "#{lproj(lang)}/Localizable_orig.strings"
end

# Splits a .strings file into tuples consisting of [comment, keypair, newline]
def split_tuples(file)
  File.readlines(file).each_slice(3).to_a
end

# Extracts the key from a keypair line
def extract_key(keypair)
  keypair[/"([^"]*)"/].gsub("\"", "")
end

def write_tuples(tuples, file)
  File.open(file, "w+") { |f| f.puts(tuples) }
end

# Make a temporary copy of original .strings files
@langs = ["de", "en", "es", "fr", "it", "ja", "nl", "zh-Hans"]
for l in @langs do
  `cp #{strings_file(l)} #{orig_strings_file(l)}`
end

# Update English .strings file
# (This results in a UTF-16 file, so we convert to UTF-8)
`find Stripe -name \*.m | xargs genstrings -s STPLocalizedString -o #{lproj("en")}`
`recode UTF-16LE..UTF-8 #{strings_file("en")}`

# Get new keys in updated English .strings file
orig_en_strings = File.readlines(orig_strings_file("en"))
current_en_strings = File.readlines(strings_file("en"))
@new_keys = (current_en_strings - orig_en_strings).select { |s|
  !s.include?("/*")
}.map { |s|
  extract_key(s)
}

@orig_keys = []
orig_tuples = split_tuples(strings_file("en"))
for tuple in orig_tuples
  key = extract_key(tuple[1])
  @orig_keys.push(key)
end

puts "▸ Downloading translations from PhraseApp"
`phraseapp pull -t #{ARGV[0]}`

# Generate new .strings files, inserting new translations
for lang in @langs
  # Collect translations in downloaded .strings file
  key_to_tuple = {}
  tuples = split_tuples(strings_file(lang))
  for tuple in tuples
    key = extract_key(tuple[1])
    key_to_tuple[key] = tuple
  end
  # Generate new .strings file, updating any changed translations,
  # and inserting new translations
  orig_tuples = split_tuples(orig_strings_file(lang))
  new_tuples = []
  last_cons = []
  for cons in orig_tuples.each_cons(2)
    tuple1 = cons[0]
    tuple2 = cons[1]
    key1 = extract_key(tuple1[1])
    key2 = extract_key(tuple2[1])
    if (new_tuple = key_to_tuple[key1])
      new_tuples.push(new_tuple)
    else
      if @orig_keys.include?(key1)
        new_tuples.push(tuple1)
      end
    end
    for new_key in @new_keys
      if new_key.downcase > key1.downcase && new_key.downcase < key2.downcase &&
        (new_tuple = key_to_tuple[new_key])
        new_tuples.push(new_tuple)
      end
    end
    last_cons = cons
  end
  tuple = last_cons[1]
  key = extract_key(tuple[1])
  if (new_tuple = key_to_tuple[key])
    new_tuples.push(new_tuple)
  else
    new_tuples.push(tuple)
  end
  file = strings_file(lang)
  puts "▸ Updating #{file}"
  write_tuples(new_tuples, file)
end

# Cleanup any untracked files
`git clean -fd`
