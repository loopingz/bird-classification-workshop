#!/bin/bash

# This script creates a set of BirdWorkshop sagemaker notebook instances.
# The first argument is an AWS credentials profile that corresponds to a configured
# entry in the AWS credentials configuration file to refer to a specific IAM user.
# The second argument is the workshop Pod number.  At reInvent, there are 15 pods
# in a room, with each pod containing 8 stations.

# ./delete_stacks.sh account1 01 us-east-1
# ./delete_stacks.sh account1 02 us-east-1
# ./delete_stacks.sh account2 03 us-east-1
# ./delete_stacks.sh account2 04 us-east-1
# ...
# ./delete_stacks.sh account7 13 us-east-1
# ./delete_stacks.sh account7 14 us-east-1
# ./delete_stacks.sh account8 15 us-east-1

Profile=$1
Pod=$2
Region=$3

if [ $# -lt 3 ]
then
  echo Pass the aws profile name and the instance name, as in: ./delete_stacks.sh deeplens-1 04 us-east-1
  exit 1
fi

echo $Profile
set -x

let Seat=0
while [ $Seat -lt 8 ]
do
  let Seat=$Seat+1
  UserSuffix=${Pod}-"0${Seat}"
  echo $UserSuffix

  aws --profile ${Profile} --region ${Region} \
    cloudformation delete-stack --stack-name bw${UserSuffix}
done
