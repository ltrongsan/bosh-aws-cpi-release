#!/usr/bin/env bash

set -e

source bosh-cpi-release/ci/tasks/utils.sh

check_param base_os
check_param BAT_VCAP_PASSWORD
check_param BAT_VCAP_PRIVATE_KEY

source /etc/profile.d/chruby.sh
chruby 2.1.2

source terraform-exports/terraform-${base_os}-exports.sh

export BAT_DIRECTOR=$DIRECTOR
export BAT_DNS_HOST=$DIRECTOR
export BAT_STEMCELL="${PWD}/stemcell/stemcell.tgz"
export BAT_DEPLOYMENT_SPEC="${PWD}/bosh-concourse-ci/pipelines/bosh-aws-cpi/${base_os}-bats-config.yml"
export BAT_INFRASTRUCTURE=aws
export BAT_NETWORKING=manual
export BAT_VIP=$VIP
export BAT_SUBNET_ID=$SUBNET_ID
export BAT_SECURITY_GROUP_NAME=$SECURITY_GROUP_NAME

eval $(ssh-agent)
chmod go-r $BAT_VCAP_PRIVATE_KEY
ssh-add $BAT_VCAP_PRIVATE_KEY

bosh -n target $BAT_DIRECTOR

sed -i.bak s/"uuid: replace-me"/"uuid: $(bosh status --uuid)"/ $BAT_DEPLOYMENT_SPEC
sed -i.bak s/"vip: replace-me"/"vip: $BAT_VIP"/ $BAT_DEPLOYMENT_SPEC
sed -i.bak s/"subnet: replace-me"/"subnet: $BAT_SUBNET_ID"/ $BAT_DEPLOYMENT_SPEC
sed -i.bak s/"security_groups: replace-me"/"security_groups: [$BAT_SECURITY_GROUP_NAME]"/ $BAT_DEPLOYMENT_SPEC

cd bats
bundle install
bundle exec rspec spec