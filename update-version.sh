#!/bin/sh
sed -E "s/(Version )[0-9: -]+/\1$(date '+%Y-%m-%d %H:%M:%S')/"
