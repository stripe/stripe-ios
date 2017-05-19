#!/bin/bash

echo '▸ Installing dependencies for Stripe iOS Example (Simple)';
cd Example;
carthage bootstrap --platform ios;
echo '▸ Finished installing dependencies for Stripe iOS Example (Simple)';
