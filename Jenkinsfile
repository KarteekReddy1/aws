pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        // Jenkins "AWS Credentials" with this ID
        AWS_CREDS = credentials('ec2-user')
    }

    parameters {
        choice(name: 'ENV', choices: ['dev', 'stage', 'prod'])
        booleanParam(
            name: 'APPLY_CHANGES',
            defaultValue: false,
            description: 'Run terraform apply'
        )
        booleanParam(
            name: 'DESTROY_RESOURCES',
            defaultValue: false,
            description: 'Run terraform destroy'
        )
    }

    options {
        timestamps()
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/KarteekReddy1/aws.git'
            }
        }

        /* =======================
           BOOTSTRAP STAGE
           ======================= */
        stage('Terraform Bootstrap') {
            steps {
                withEnv([
                    "AWS_ACCESS_KEY_ID=${AWS_CREDS_USR}",
                    "AWS_SECRET_ACCESS_KEY=${AWS_CREDS_PSW}"
                ]) {
                    dir('terraform-bootstrap') {
                        sh '''
                          terraform init
                          terraform apply -auto-approve \
                            -var="env=${ENV}" \
                            -var="region=${AWS_DEFAULT_REGION}"
                        '''
                    }
                }
            }
        }

        /* =======================
           MAIN INFRA
           ======================= */
        stage('Terraform Init') {
            steps {
                withEnv([
                    "AWS_ACCESS_KEY_ID=${AWS_CREDS_USR}",
                    "AWS_SECRET_ACCESS_KEY=${AWS_CREDS_PSW}"
                ]) {
                    dir('terraform') {
                        sh '''
                          terraform init -input=false -backend-config=backend-${ENV}.hcl -reconfigure
                        '''
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withEnv([
                    "AWS_ACCESS_KEY_ID=${AWS_CREDS_USR}",
                    "AWS_SECRET_ACCESS_KEY=${AWS_CREDS_PSW}"
                ]) {
                    dir('terraform') {
                        sh '''
                          terraform plan -input=false \
                            -var-file="${ENV}.tfvars" \
                            -out=tfplan
                        '''
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.APPLY_CHANGES }
            }
            steps {
                withEnv([
                    "AWS_ACCESS_KEY_ID=${AWS_CREDS_USR}",
                    "AWS_SECRET_ACCESS_KEY=${AWS_CREDS_PSW}"
                ]) {
                    dir('terraform') {
                        sh '''
                          terraform apply -input=false -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.DESTROY_RESOURCES }
            }
            steps {
                withEnv([
                    "AWS_ACCESS_KEY_ID=${AWS_CREDS_USR}",
                    "AWS_SECRET_ACCESS_KEY=${AWS_CREDS_PSW}"
                ]) {
                    dir('terraform') {
                        sh '''
                          terraform destroy -input=false -auto-approve \
                            -var-file="${ENV}.tfvars"
                        '''
                    }
                }
            }
        }


stage('Destroy Bootstrap') {
    when { expression { params.DESTROY_RESOURCES } }
    steps {
        dir('terraform-bootstrap') {
            withEnv(["AWS_ACCESS_KEY_ID=${AWS_CREDS_USR}", "AWS_SECRET_ACCESS_KEY=${AWS_CREDS_PSW}"]) {
                sh '''
                  # Force empty S3 bucket first
                  aws s3 rm s3://my2-terraform2-state2-${ENV} --recursive
                  
                  # Now destroy succeeds
                  terraform init
                  terraform destroy -input=false -auto-approve \
                    -var="env=${ENV}"
                '''
            }
        }
    }
}

    }











    post {
        always {
            archiveArtifacts artifacts: '**/*.tfstate*', onlyIfSuccessful: false
            archiveArtifacts artifacts: '**/tfplan', onlyIfSuccessful: false
        }
    }
}
