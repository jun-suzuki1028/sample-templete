@echo off

set CFN_TEMPLATE= .\\templete\\web.yml 
set CFN_STACK_NAME=WebStack
set CFN_OPTION=--capabilities CAPABILITY_NAMED_IAM
set PROFILE=testuser
set SNS_MAIL=aws.jsuzuki@gmail.com

rem テンプレート実行
aws cloudformation deploy %CFN_OPTION% --stack-name %CFN_STACK_NAME% --template-file %CFN_TEMPLATE% --parameter-overrides SnsEmail=%SNS_MAIL% --profile=%PROFILE% 
pause


