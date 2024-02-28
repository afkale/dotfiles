#!/bin/bash

branch_name="$(cd $1 && git branch 2>/dev/null | sed -n -e 's/^\* \(.*\)/\1/p')"
echo $branch_name
