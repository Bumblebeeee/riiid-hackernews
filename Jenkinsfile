def builder = null
def deploy_stage = null
if (env.BRANCH_NAME =~ ".*master") {
    deploy_stage = "prod"
} else {
    deploy_stage = "dev"
}
node {
    try {
        stage ('checkout') {
            checkout scm
        }
        stage ('Create Building Environment') {
            withCredentials([
                string(credentialsId: "terraform-s3-backend-access-key-id", variable: 'S3_BACKEND_ACCESS_KEY_ID'),
                string(credentialsId: "terraform-s3-backend-secret-access-key", variable: 'S3_BACKEND_SECRET_ACCESS_KEY'),
                string(credentialsId: "riiid-hackernews-dev-secret-access-key", variable: 'DEV_SECRET_ACCESS_KEY'),
                string(credentialsId: "riiid-hackernews-dev-access-key-id", variable: 'DEV_ACCESS_KEY_ID'),
                string(credentialsId: "riiid-hackernews-prod-access-key-id", variable: 'PROD_ACCESS_KEY_ID'),
                string(credentialsId: "riiid-hackernews-prod-secret-access-key", variable: 'PROD_SECRET_ACCESS_KEY'),
            ]){
                builder = docker.build("riiid-hackernews:${env.BUILD_ID}"
                    , "--build-arg S3_BACKEND_SECRET_ACCESS_KEY='${S3_BACKEND_SECRET_ACCESS_KEY}' --build-arg S3_BACKEND_ACCESS_KEY_ID='${S3_BACKEND_ACCESS_KEY_ID}' --build-arg DEV_SECRET_ACCESS_KEY='${DEV_SECRET_ACCESS_KEY}' --build-arg DEV_ACCESS_KEY_ID='${DEV_ACCESS_KEY_ID}' --build-arg PROD_ACCESS_KEY_ID='${PROD_ACCESS_KEY_ID}' --build-arg PROD_SECRET_ACCESS_KEY='${PROD_SECRET_ACCESS_KEY}' -f ./build.dockerfile ."
                )

            }
        }
        builder.inside('-v $PWD:/source') { c ->
            stage ('test') {
            }
            stage ('package') {
                sh (script: '''#!/bin/bash
                    [ -d "python" ] && rm -rf python/
                    mkdir python && pip install -r function/requirements.txt --prefix python
                    [ -f "function.zip" ] && rm -f function.zip
                    zip -j function.zip $(ls -d function/*)
                    [ -f "riiid_hacknews_runtime.zip" ] && rm -f riiid_hacknews_runtime.zip
                    zip -r riiid_hacknews_runtime.zip python/*
                    ''')
            }
            stage ('Depoly') {
                dir('terraform') {
                    sh (script: '''#!/bin/bash
                        terraform init

                        prod_exists=`terraform workspace list | grep prod`
                        if [ "X" == "X${prod_exists}" ];then
                            terraform workspace new prod
                        fi

                        dev_exists=`terraform workspace list | grep dev`
                        if [ "X" == "X${dev_exists}" ];then
                            terraform workspace new dev
                        fi
                        ''')
                    if (deploy_stage == "dev") {
                        stage('Deploy to Dev target'){
                            sh (script: '''#!/bin/bash
                                terraform workspace select dev
                                terraform plan --out=plan.txt --var env=dev
                            ''')
                            def confirm = input(id:'confirm', message: "Ready to deploy to " + deploy_stage.toUpperCase() + " env?\n type YES to proceed"
                                        , parameters: [[$class: 'TextParameterDefinition', defaultValue: '', name: 'proceed']])
                            if (confirm.toUpperCase() == "YES") {
                                sh (script: '''#!/bin/bash
                                    terraform workspace list
                                    terraform apply --auto-approve --var env=dev
                                ''')
                            }
                        }
                    } else if (deploy_stage == "prod") {                    
                        stage('Deploy to Prod target'){
                            sh (script: '''#!/bin/bash
                                terraform workspace select prod
                                terraform plan --out=plan.txt --var env=prod
                            ''')
                            def confirm = input(id:'confirm', message: "Ready to deploy to " + deploy_stage.toUpperCase() + " env?\n type YES to proceed"
                                        , parameters: [[$class: 'TextParameterDefinition', defaultValue: '', name: 'proceed']])
                            if (confirm.toUpperCase() == "YES") {
                                sh (script: '''#!/bin/bash
                                    terraform workspace list
                                    terraform apply --auto-approve --var env=prod
                                ''')
                            }
                        }

                    }
                }
            }

        }

    } catch (e) {
        currentBuild.result = "FAILED"
    }
}