#!/usr/bin/env bash

if [ $1 = "server" ] && [ $2 = "0" ]
  then
    text="leader"
elif [ $1 = "server" ] && [ $2 -gt 0 ]
  then
    text="follower"
  else
    text="client"
fi

# if [[ $# -eq 2 ]]
#   then
#     text="$1, $2"
# elif [[ $# -eq 3 ]]
#   then
#     text="$1, $2, $3"
# elif [[ $# -eq 4 ]]
#   then
#     text="$1, $2, $3, $4"
# elif [[ $# -eq 5 ]]
#   then
#     text="$1, $2, $3, $4, $5"
# else
#   echo "Script has at least 2 arguments: $0 <datacenter name | consul servers>"
#   exit 1
# fi

# echo "Argument 1: $1"
# echo "Argument 2: $2"
# echo "Argument 3: $3"
# echo "Argument 4: $4"
# echo "Argument 5: $5"
echo "I am a $text!"
