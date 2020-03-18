
@echo off
set CFN_TEMPLATE= .\\templete\\security.yml
set CFN_STACK_NAME=SecurityStack
set CFN_OPTION=--capabilities CAPABILITY_NAMED_IAM
set PROFILE=testuser

rem テンプレート実行
aws cloudformation deploy %CFN_OPTION% --stack-name %CFN_STACK_NAME% --template-file %CFN_TEMPLATE% --profile=%PROFILE% 
pause