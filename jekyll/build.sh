#!/usr/bin/env bash
jekyll build

echo
echo "copying files to site root.."
cp -vR _site/* ../
