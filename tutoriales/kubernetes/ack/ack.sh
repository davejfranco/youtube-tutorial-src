#!/bin/bash

SERVICES="ec2 s3"
ACK_SYSTEM_NAMESPACE="ack-system"

add_oidc() {
    EKS_CLUSTER_NAME=$1
    AWS_REGION=$2

    if [ -z "$EKS_CLUSTER_NAME" ] || [ -z "$AWS_REGION" ]; then
      echo "Usage: ./ack.sh add-oidc <cluster-name> <region>"
      exit 1
    fi
    
    echo "Creating OIDC provider for EKS cluster $EKS_CLUSTER_NAME in region $AWS_REGION..."
    eksctl utils associate-iam-oidc-provider --cluster $EKS_CLUSTER_NAME --region $AWS_REGION --approve
}

add_iam_role() {
  
  EKS_CLUSTER_NAME=$1
  SERVICE=$2

  if [ -z "$EKS_CLUSTER_NAME" ] || [ -z "$SERVICE" ]; then
    echo "Usage: ./ack.sh create-iam-role <cluster-name> <service>"
    exit 1
  fi

  echo "Creating IAM roles for ACK controllers..."
  OIDC_PROVIDER=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --region $AWS_REGION --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")

  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  ACK_SERVICE_ACCOUNT_NAME="ack-$SERVICE-controller"
    
    read -r -d '' TRUST_RELATIONSHIP <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:${ACK_SYSTEM_NAMESPACE}:${ACK_SERVICE_ACCOUNT_NAME}"
        }
      }
    }
  ]
}
EOF
echo "${TRUST_RELATIONSHIP}" > trust.json
  
  ACK_CONTROLLER_IAM_ROLE="ack-$SERVICE-controller-role"
  ACK_CONTROLLER_IAM_ROLE_DESCRIPTION="IAM role for ACK service account $ACK_SERVICE_ACCOUNT_NAME"
  
  aws iam create-role --role-name "${ACK_CONTROLLER_IAM_ROLE}" --assume-role-policy-document file://trust.json --description "${ACK_CONTROLLER_IAM_ROLE_DESCRIPTION}" #where the IAM role is created
  ACK_CONTROLLER_IAM_ROLE_ARN=$(aws iam get-role --role-name=$ACK_CONTROLLER_IAM_ROLE --query Role.Arn --output text)
  
  BASE_URL=https://raw.githubusercontent.com/aws-controllers-k8s/${SERVICE}-controller/main
  POLICY_ARN_URL=${BASE_URL}/config/iam/recommended-policy-arn
  POLICY_ARN_STRINGS="$(wget -qO- ${POLICY_ARN_URL})"

  INLINE_POLICY_URL=${BASE_URL}/config/iam/recommended-inline-policy
  INLINE_POLICY="$(wget -qO- ${INLINE_POLICY_URL})"

  while IFS= read -r POLICY_ARN; do
    echo -n "Attaching $POLICY_ARN ... "
    aws iam attach-role-policy \
        --role-name "${ACK_CONTROLLER_IAM_ROLE}" \
        --policy-arn "${POLICY_ARN}"
    echo "ok."
  done <<< "$POLICY_ARN_STRINGS"

  if [ ! -z "$INLINE_POLICY" ]; then
    echo -n "Putting inline policy ... "
    aws iam put-role-policy \
        --role-name "${ACK_CONTROLLER_IAM_ROLE}" \
        --policy-name "ack-recommended-policy" \
        --policy-document "$INLINE_POLICY"
    echo "ok."
  fi
  rm trust.json
}

install_controller() {
  SERVICE=$1 
  AWS_REGION=$2
  
  if [ -z "$SERVICE" ] || [ -z $AWS_REGION ]; then
    echo "Usage: ./ack.sh install-controller <service> <region>"
    exit 1
  fi

  echo "login into public ECR"
  aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws
  
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  RELEASE_VERSION=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/${SERVICE}-controller/releases/latest | jq -r '.tag_name | ltrimstr("v")')
  ACK_CONTROLLER_IAM_ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/ack-$SERVICE-controller-role" 
    
  helm upgrade --install -n $ACK_SYSTEM_NAMESPACE ack-$SERVICE-controller \
    oci://public.ecr.aws/aws-controllers-k8s/$SERVICE-chart \
    --create-namespace \
    --version=$RELEASE_VERSION \
    --set="serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$ACK_CONTROLLER_IAM_ROLE_ARN" \
    --set=aws.region=$AWS_REGION
}

delete_controller() {
  SERVICE=$1 
  if [ -z "$SERVICE" ]; then
    echo "Usage: ./ack.sh delete-controller <service>"
    exit 1
  fi
  echo "Uninstalling $SERVICE controller..."
  helm uninstall -n $ACK_SYSTEM_NAMESPACE ack-$SERVICE-controller
}

delete_iam_role() {
  SERVICE=$1 
  if [ -z "$SERVICE" ]; then
    echo "Usage: ./ack.sh delete-iam-role <service>"
    exit 1
  fi

  ACK_CONTROLLER_IAM_ROLE="ack-$SERVICE-controller-role"
  
  #get attached policies
  ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name $ACK_CONTROLLER_IAM_ROLE --query 'AttachedPolicies[].PolicyArn' --output text)
  INLINE_POLICIES=$(aws iam list-role-policies --role-name $ACK_CONTROLLER_IAM_ROLE --query 'PolicyNames' --output text)
    #detach AttachedPolicies
  for policy in $ATTACHED_POLICIES; do
    aws iam detach-role-policy --role-name $ACK_CONTROLLER_IAM_ROLE --policy-arn $policy
  done
  #delete inline policies
  for policy in $INLINE_POLICIES; do
    aws iam delete-role-policy --role-name $ACK_CONTROLLER_IAM_ROLE --policy-name $policy
  done
    echo "Deleting IAM role $ACK_CONTROLLER_IAM_ROLE..."
    aws iam delete-role --role-name $ACK_CONTROLLER_IAM_ROLE
}

help() {
  cat <<EOF
ack.sh is a script to help you install and uninstall ACK controllers on an EKS cluster.

Usage: ./ack.sh <command> 

Options:
  install <cluster-name> <region>  Install ACK controllers on the EKS cluster
  uninstall <cluster-name> <region>  Uninstall ACK controllers from the EKS cluster
  add-oidc <cluster-name> <region>  Add OIDC provider for the EKS cluster
  add-iam-role <cluster-name> <service>  Create IAM roles for ACK controllers
  install-controller <service> <region>  Install ACK controllers on the EKS cluster
  delete-controller <service> Delete ACK controllers from the EKS cluster
  delete-iam-role <service> Delete IAM roles for ACK controllers
  help  Display this help message

Examples:
./ack.sh install my-eks-cluster us-west-2

EOF
}

case $1 in
  add-oidc)
    add_oidc $2 $3
     ;;
  add-iam-role)
    add_iam_role $2 $3
    ;;
  install-controller)
    install_controller $2 $3
    ;;
  delete-controller)
    delete_controller $2
    ;;
  delete-iam-role)
    delete_iam_role $2
    ;;
  help)
    help
    ;;
  *)
    help
    exit 1
    ;;
esac
