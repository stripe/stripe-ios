#!/usr/bin/env ruby
# encoding: utf-8
#
# Usage:
# $ ./ci_scripts/temp_pull_translations.rb `fetch-password PhraseApp-access-token`
# (running fetch-password from within this script causes strange dependency issues)
#
# PhraseApp has been updated with translations for `sources-ui`, so it is
# currently out of sync with `master`. Until `sources-ui` has been merged,
# we'll manually add new keys to PhraseApp: https://jira.corp.stripe.com/browse/LOCAL-16
#
# Use this script instead of `pull_translations.sh` to bring in new translations.
# It will:
# 1. determine which new keys have been added locally
# 2. find translations for those keys on PhraseApp
# 3. rewrite our .strings files, inserting any new translations
#
# It will not change or remove any existing translations.

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
if @new_keys.count == 0
  abort("No new keys")
end

puts "▸ Found new keys: #{@new_keys}"
puts "▸ Downloading translations from PhraseApp"
`phraseapp pull -t #{ARGV[0]}`

# If the given tuple matches a new key, returns that key
def new_key_in_tuple(tuple)
  for key in @new_keys
    if tuple[1].include?(key)
      return key
    end
  end
  return nil
end

# Generate new .strings files, inserting new translations
for lang in @langs
  # Collect translations matching new keys from downloaded .strings file
  tuples_to_insert = {}
  tuples = split_tuples(strings_file(lang))
  for tuple in tuples
    if (new_key = new_key_in_tuple(tuple))
      tuples_to_insert[new_key] = tuple
    end
  end
  # Generate new .strings file, inserting new translations
  orig_tuples = split_tuples(orig_strings_file(lang))
  new_tuples = []
  last_cons = []
  for cons in orig_tuples.each_cons(2)
    tuple1 = cons[0]
    tuple2 = cons[1]
    key1 = extract_key(tuple1[1]).downcase
    key2 = extract_key(tuple2[1]).downcase
    new_tuples.push(tuple1)
    for new_key in tuples_to_insert.keys
      if new_key.downcase > key1 && new_key.downcase < key2
        tuple = tuples_to_insert[new_key]
        new_tuples.push(tuple)
      end
    end
    last_cons = cons
  end
  new_tuples.push(last_cons[1])
  file = strings_file(lang)
  puts "▸ Updating #{file}"
  write_tuples(new_tuples, file)
end

# Cleanup any untracked files
`git clean -fd`
