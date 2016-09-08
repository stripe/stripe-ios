echo "Generating strings files..."
find Stripe -name \*.m | xargs genstrings -s STPLocalizedString -o Stripe/Resources/Localizations/en.lproj

if [[ $? -eq 0 ]]; then

  if [[ -z $(which recode) ]]; then
    if [[ -z $(which brew) ]]; then
      echo "Please install homebrew or the recode command line tool"
      exit 1
    else
      brew install recode
    fi
  fi

  if [[ $? -eq 0 ]]; then

    echo "Converting to utf8..."
    # Genstrings outputs in utf16 but we want to store in utf8
    recode utf16..utf8 Stripe/Resources/Localizations/en.lproj/Localizable.strings

    if [[ -z $(which phraseapp) ]]; then
      if [[ -z $(which brew) ]]; then
        echo "Please install homebrew/phraseapp cli client"
        exit 1
      else
        echo "Installing phraseapp via homebrew..."
        brew tap phrase/brewed
        brew install phraseapp
      fi
    fi

    echo "Uploading to Phrase..."
    phraseapp push -t `fetch-password PhraseApp-access-token`

  else
    echo "Error recoding into utf8"
  fi
else
  echo "Error occured generating english strings file."
fi
