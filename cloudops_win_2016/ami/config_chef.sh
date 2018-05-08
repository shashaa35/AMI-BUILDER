#!/bin/bash

# Script for reading values from userdata, assuming role and executing recipes from chef organization

function fatal_error
{
  local _MSG=$1
  local _EXIT_CODE=$2

  if [ -z "${_EXIT_CODE}" ];
  then
    _EXIT_CODE=255
  fi

  echo "$_MSG"
  exit ${_EXIT_CODE}
}

function get_chef_info
{
  local _KEY=$1

  key_value=$(curl -s http://169.254.169.254/latest/user-data/ | \
    grep "^${_KEY}=" | \
    awk -F'=' '{print $2}' | \
    sed 's/^[ \t]*//;s/[ \t]*$//'
  )

  echo -n $key_value
}

function get_iam_role {
  curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/ -I | grep "404 Not Found" > /dev/null
  if [ $? != 0 ];
  then
        echo -n $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/)
  else
        return 1
  fi
}

function get_iam_role_info
{

  local _KEY=$1
  local _ROLE=$2

  echo -n $(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${_ROLE}/ | \
    jq -r ".${_KEY}" 
  )
}

function get_s3_file
{
  local _bucket=$1
  local _file=$2
  local _local_path=$3

  if [ -x aws ]
  then
    fatal_error "Cannot locate aws in path"
  fi
 
  aws s3 cp s3://${_bucket}/${_file} ${_local_path}
  if [ $? != 0 ]
  then
    fatal_error "Failed to retrieve file ${_file} from s3://${_bucket}/${_file}" 1
  fi
}

# If this script is executed before, exit out
CHEF_HOME=/cygdrive/c/opscode/chef
if [ -e $CHEF_HOME/firstboot.json ]
then
  fatal_error "Chef already executed, exiting out ..."
fi

# Check if user-data is available or not
HEADER=`curl -Is http://169.254.169.254/latest/user-data/ | head -1 | awk '{print $2}'`
if [ $HEADER -ne 200 ]
then
  fatal_error "No user-data found. Cannot continue"
fi

IAM_ROLE=$( get_iam_role )
if [ $? -eq 0 ]
then
    debug "Using IAM role = $IAM_ROLE"
else
    debug "No IAM role found."
fi


# Chef specific info
CHEF_ENV=$(get_chef_info "chef.env")
CHEF_ORG=$(get_chef_info "chef.org")
CHEF_ROLE=$(get_chef_info "chef.role")
CHEF_RECIPE=$(get_chef_info "chef.recipe")
CHEF_BUCKET=$(get_chef_info "chef.bucket" )
CHEF_ENABLED=$(get_chef_info "chef.enabled")
# Optional
CHEF_RUN_LIST_SOURCE=$(get_chef_info "chef.run_list_source")

# Exit out if chef is not enabled
if [[ $CHEF_ENABLED == "false" ]]; then
  fatal_error "chef.enabled=false. Exiting!" 0
fi

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id )
NODE_NAME="${CHEF_ENV}_${CHEF_ROLE}_${CHEF_RECIPE}_${INSTANCE_ID}"
export AWS_ACCESS_KEY_ID=$(get_iam_role_info "AccessKeyId" $IAM_ROLE)
export AWS_SECRET_ACCESS_KEY=$(get_iam_role_info "SecretAccessKey" $IAM_ROLE)
export AWS_SESSION_TOKEN=$(get_iam_role_info "Token" $IAM_ROLE)


cd ${CHEF_HOME}

# Install AWS cli
curl -O https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install awscli

# Download all required files
for _FILE in ${CHEF_ORG}-validator.pem ${CHEF_ORG}-encrypted_data_bag_secret.pem
do
    _DOWNLOAD_URL="https://s3.amazonaws.com/${CHEF_BUCKET}/${_FILE}"
    echo "Downloading ${_DOWNLOAD_URL}"
    get_s3_file ${CHEF_BUCKET} ${_FILE} .
done

# Populate client.rb
sed 's/^[    ]*//' <<- EOF > ${CHEF_HOME}/client.rb
    log_level               :info
    log_location            STDOUT
    chef_server_url         "https://api.opscode.com/organizations/${CHEF_ORG}"
    validation_client_name  "${CHEF_ORG}-validator"
    node_name               "${NODE_NAME}"
    environment             "${CHEF_ENV}"
EOF

mv ${CHEF_HOME}/${CHEF_ORG}-encrypted_data_bag_secret.pem ${CHEF_HOME}/encrypted_data_bag_secret
chmod 400 ${CHEF_HOME}/${CHEF_ORG}-validator.pem ${CHEF_HOME}/*encrypted_data_bag_secret*
cp ${CHEF_HOME}/${CHEF_ORG}-validator.pem /cygdrive/c/chef/validation.pem

# Create logging directory, if one does not exist
CHEF_LOG_DIR=${CHEF_HOME}/logs
if [ ! -d ${CHEF_LOG_DIR} ]
then
  mkdir -p ${CHEF_LOG_DIR}
fi

# Generate firstboot.json
if [[ $CHEF_RUN_LIST_SOURCE == "role" ]]; then
  NODE_NAME="${CHEF_ENV}_${CHEF_ROLE}_${INSTANCE_ID}"
  echo "{\"run_list\": [\"role[$CHEF_ROLE]\"]}" > ${CHEF_HOME}/firstboot.json
else
  res=""
  for i in `echo $CHEF_RECIPE | xargs -d ','`; do res=${res}recipe[$i], ; done
  echo "{\"run_list\": [\"${res::-1}\"]}" > ${CHEF_HOME}/firstboot.json
fi

# Run Chef client to execute recipes
cmd /c 'chef-client -c c:\opscode\chef\client.rb -j c:\opscode\chef\firstboot.json -L c:\opscode\chef\logs\client.log'


