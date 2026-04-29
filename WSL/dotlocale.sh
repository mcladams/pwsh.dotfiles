#!/bin/bash
# https://stackoverflow.com/questions/1167746/how-to-assign-a-heredoc-value-to-a-variable-in-bash
# this will only work if the locales below have been defined by editting locale.gen then executing locale-gen
# (or installing locales-all)

set -eu

LOCALE=$(
cat <<'EOF'
LANGUAGE=en_AU.en_US.en
LANG="en_US.UTF-8"
LC_CTYPE="C.UTF-8"
LC_COLLATE="C.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_NUMERIC="en_AU.UTF-8"
LC_TIME="en_AU.UTF-8"
LC_MONETARY="en_AU.UTF-8"
LC_MEASUREMENT="en_AU.UTF-8"
LC_ALL="C.UTF-8"
EOF
)

for line in $LOCALE; do
    eval "export "$line
done
