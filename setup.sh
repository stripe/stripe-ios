#!/bin/bash

echo '▸ Installing dependencies for Stripe iOS Example (Simple)';
cd Example;
rm Cartfile.resolved;
carthage bootstrap --platform ios;
echo '▸ Finished installing dependencies for Stripe iOS Example (Simple)';
