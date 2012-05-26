#!/bin/bash

## Fetches my personal collection of landscape wallpapers.

URL=https://s3.amazonaws.com/nullprogram/personal/wallpapers.tar
wget $URL -O - | tar -xv
