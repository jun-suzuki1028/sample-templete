@echo off
set CFN_TEMPLATE= .\\templete\\rds.yml
set CFN_STACK_NAME=RdsStack
set CFN_OPTION=--capabilities CAPABILITY_NAMED_IAM
set PROFILE=testuser
set MULTI_AZ=true

rem テンプレート実行
aws cloudformation deploy %CFN_OPTION% --stack-name %CFN_STACK_NAME% --template-file %CFN_TEMPLATE% --parameter-overrides MultiAZ=%MULTI_AZ% --profile=%PROFILE% 
pause


