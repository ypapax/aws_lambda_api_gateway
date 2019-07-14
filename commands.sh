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

create_restapi(){
#	https://docs.aws.amazon.com/apigateway/latest/developerguide/create-api-using-awscli.html
	apiID=$(aws apigateway create-rest-api --name 'rest-api-for-golang' --region $REGION | jq -r .id)
	resourceID=$(aws apigateway get-resources --rest-api-id $apiID --region $REGION | jq -r '.items | .[0] | .id')

	resourceID=$(aws apigateway create-resource --rest-api-id $apiID \
      --region $REGION \
      --parent-id $resourceID \
      --path-part greeting | jq -r .id)

   aws apigateway put-method --rest-api-id $apiID \
       --region $REGION \
       --resource-id $resourceID \
       --http-method GET \
       --authorization-type "NONE" \
       --request-parameters method.request.querystring.greeter=false

   aws apigateway put-method-response \
        --region $REGION \
        --rest-api-id $apiID \
        --resource-id $resourceID \
        --http-method GET \
        --status-code 200

   aws apigateway put-integration \
        --region $REGION \
        --rest-api-id $apiID \
        --resource-id $resourceID \
        --http-method GET \
        --type AWS \
        --integration-http-method POST \
        --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:123456789012:function:$FUNCTION_NAME/invocations \
        --request-templates file://./integration-request-template.json \
        --credentials $ARN
}
$@