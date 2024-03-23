#!/bin/bash

EKS_CLUSTER_NAME=$1
AWS_REGION=$2

if [ -z "$EKS_CLUSTER_NAME" ]; then
    echo "Usage: $0 <EKS_CLUSTER_NAME> <AWS_REGION>"
    exit 1
fi

export AWS_REGION=$AWS_REGION

SERVICES="ec2 s3"
ACK_SYSTEM_NAMESPACE="ack-system"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

create_oidc() {
    echo "Creating OIDC provider for EKS cluster $EKS_CLUSTER_NAME in region $AWS_REGION..."
    eksctl utils associate-iam-oidc-provider --cluster $EKS_CLUSTER_NAME --region $AWS_REGION --approve
}

iam_role() {  
  echo "Creating IAM roles for ACK controllers..."
  OIDC_PROVIDER=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")

  for service in $SERVICES; do
    ACK_SERVICE_ACCOUNT_NAME="ack-$service-controller"
    
    read -r -d '' TRUST_RELATIONSHIP <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
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
  
  ACK_CONTROLLER_IAM_ROLE="ack-$service-controller-role"
  ACK_CONTROLLER_IAM_ROLE_DESCRIPTION="IAM role for ACK service account $ACK_SERVICE_ACCOUNT_NAME"
  
  aws iam create-role --role-name "${ACK_CONTROLLER_IAM_ROLE}" --assume-role-policy-document file://trust.json --description "${ACK_CONTROLLER_IAM_ROLE_DESCRIPTION}" #where the IAM role is created
  ACK_CONTROLLER_IAM_ROLE_ARN=$(aws iam get-role --role-name=$ACK_CONTROLLER_IAM_ROLE --query Role.Arn --output text)
  
  BASE_URL=https://raw.githubusercontent.com/aws-controllers-k8s/${service}-controller/main
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
  done

}

install_controllers() {
  echo "login into public ECR"

  #aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws
   
  for service in $SERVICES; do
    
    RELEASE_VERSION=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/${service}-controller/releases/latest | jq -r '.tag_name | ltrimstr("v")')
    ACK_CONTROLLER_IAM_ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/ack-$service-controller-role" 
    #echo $ACK_CONTROLLER_IAM_ROLE
    helm template -n $ACK_SYSTEM_NAMESPACE ack-$service-controller \
      oci://public.ecr.aws/aws-controllers-k8s/$service-chart \
      --version=$RELEASE_VERSION \
      --set="serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$ACK_CONTROLLER_IAM_ROLE_ARN" \
      --set=aws.region=$AWS_REGION
  done

}

install_controllers

