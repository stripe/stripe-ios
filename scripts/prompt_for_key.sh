#!/bin/bash

echo "Please enter your Stripe test publishable key. This can be found at"
echo "https://dashboard.stripe.com/account/apikeys, and is of the format"
echo "pk_test_abc123."
read -p "> " stripe_key

cd $(dirname $0)
sed -i.old "s/REPLACE_ME/$stripe_key/" ../Example/Stripe\ iOS\ Example\ \(Custom\)/Constants.m
