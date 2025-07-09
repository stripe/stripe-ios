#!/bin/bash

sudo security delete-certificate -Z 'F16CD3C54C7F83CEA4BF1A3E6A0819C8AAA8E4A1528FD144715F350643D2DF3A' /Library/Keychains/System.keychain
sudo security delete-certificate -Z 'CE057691D730F89CA25E916F7335F4C8A15713DCD273A658C024023F8EB809C2' /Library/Keychains/System.keychain
sudo security delete-certificate -Z 'DCF21878C77F4198E4B4614F03D696D89C66C66008D4244E1B99161AAC91601F' /Library/Keychains/System.keychain

security find-certificate -a -c 'Apple Worldwide Developer Relations Certification Authority' -Z

curl -o ~/AppleWWDRCAG3.cer https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
sudo security add-certificates -k /Library/Keychains/System.keychain ~/AppleWWDRCAG3.cer


curl -o ~/DeveloperIDG2CA.cer https://www.apple.com/certificateauthority/DeveloperIDG2CA.cer
sudo security add-certificates -k /Library/Keychains/System.keychain ~/DeveloperIDG2CA.cer
