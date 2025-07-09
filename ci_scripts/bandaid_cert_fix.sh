mkdir -p certs && cd certs
wget https://www.apple.com/certificateauthority/AppleRootCA-G3.cer
openssl x509 -inform DER -in AppleRootCA-G3.cer -out AppleRootCA-G3.pem
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain AppleRootCA-G3.pem


wget https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
openssl x509 -inform DER -in AppleWWDRCAG3.cer -out AppleWWDRCAG3.pem
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain AppleWWDRCAG3.pem
