#!/usr/bin/env bash
set -ex
# ARN is created by
create_arn(){
	aws iam create-role --role-name basic_lambda_role --assume-role-policy-document file://basic_lambda_role.json
}

ARN=arn:aws:iam::484485791251:role/basic_lambda_role

REGION=eu-central-1

FUNCTION_NAME=golang-test

deploy(){
	zip golang-app.zip golang-app
	aws lambda create-function \
	--region $REGION \
	--function-name $FUNCTION_NAME \
	--zip-file fileb://golang-app.zip \
	--role $ARN\
	--handler $binName \
	--runtime go1.x \
	--profile lambda_user
}
binName=golang-app
build(){
	GOOS=linux go build -o golang-app
	ls -la golang-app
}
list(){
	aws lambda list-functions --region $REGION
}
deleteLambda(){
	aws lambda delete-function --region $REGION --function-name $FUNCTION_NAME
}

cleanup(){
	deleteLambda
}

run(){
	aws lambda invoke \
	--invocation-type RequestResponse \
	--function-name $FUNCTION_NAME \
	--region $REGION \
	--log-type Tail \
	--payload '{"a":1, "b":2 }' \
	--profile lambda_user \
	outputfile.txt

	cat outputfile.txt
	echo
}

$@