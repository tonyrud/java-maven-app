#!/usr/bin/env groovy

library identifier: 'jenkins-shared-library@master', retriever: modernSCM(
    [$class: 'GitSCMSource',
    remote: 'https://github.com/tonyrud/jenkins-shared-library.git',
    credentialsID: 'github-creds'
    ]
)

pipeline {
    agent any
    tools {
       maven 'maven-3.9'
    }
    environment {
        DOCKER_REPO_SERVER = '326347646211.dkr.ecr.us-east-2.amazonaws.com'
        DOCKER_REPO = "${DOCKER_REPO_SERVER}/java-maven-app"
    }

    stages {
        stage('increment version') {
            steps {
                script {
                    echo 'incrementing app version...'
                    sh 'mvn build-helper:parse-version versions:set \
                        -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
                        versions:commit'
                    def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                    def version = matcher[0][1]
                    env.IMAGE_VERSION = "$version"
                }
            }
        }
        stage('build app') {
            steps {
                echo 'building application jar...'
                buildJar()
            }
        }
        stage('build image') {
            steps {
                script {
                    echo "building the docker image..."
                    withCredentials([usernamePassword(credentialsId: 'aws-ecr-credentials', passwordVariable: 'PASS', usernameVariable: 'USER')]){
                        sh "docker build -t ${DOCKER_REPO}:${IMAGE_VERSION} ."
                        sh 'echo $PASS | docker login -u $USER --password-stdin ${DOCKER_REPO_SERVER}'
                        sh "docker push ${DOCKER_REPO}:${IMAGE_VERSION}"
                    }
                }
            }
        }

        stage("provision server") {
            environment {
                AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
                TF_VAR_env_prefix = 'test'
            }
            steps {
                script {
                    dir('terraform') {
                        sh "terraform init"
                        sh "terraform apply --auto-approve"
                        EC2_PUBLIC_IP = sh(
                        script: "terraform output ec2-public_ip",
                        returnStdout: true
                        ).trim()
                    }
                }
            }
        }


        // stage("deploy with Docker on EC2") {
        //     steps {
        //         script {
        //             echo 'deploying docker image to EC2...'
        //             def dockerCmd = "docker run -p 8080:8080 -d ${IMAGE_VERSION}"
        //             sshagent(['ec2-server-key']) {
        //                 sh "ssh -o StrictHostKeyChecking=no ec2-user@3.145.156.253 ${dockerCmd}"
        //             }
        //         }
        //     }
        // }

        stage("deploy with Docker Compose on EC2") {
            environment {
                DOCKER_CREDS = credentials('docker-hub-repo')
            }

            steps {
                script {
                            echo "waiting for EC2 server to initialize"
                            sleep(time: 90, unit: "SECONDS")

                            echo 'deploying docker image to EC2...'
                            echo "${EC2_PUBLIC_IP}"


                            def shellCmd = "bash ./server-cmds.sh ${IMAGE_NAME} ${DOCKER_CREDS_USR} ${DOCKER_CREDS_PSW}"
                            def ec2Instance = "ec2-user@${EC2_PUBLIC_IP}"

                            sshagent(['jenkins-ssh']) {
                                // copy files from repo to ec2 instance
                                sh "scp -o StrictHostKeyChecking=no server-cmds.sh ${ec2Instance}:/home/ec2-user"
                                sh "scp -o StrictHostKeyChecking=no docker_compose.yml ${ec2Instance}:/home/ec2-user"
                                // ssh into ec2 instance and run commands
                                sh "ssh -o StrictHostKeyChecking=no ${ec2Instance} ${shellCmd}"
                            }
                }
            }
        }

        // with Kubernetes

        // stage('k8s deploy') {
        //     environment {
        //         AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
        //         AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
        //         APP_NAME = 'java-maven-app'
        //         // KUBECONFIG = credentials('kubeconfig')
        //     }
        //     steps {
        //         echo 'kubectl deployment...'
        //         sh 'envsubst < kubernetes/deployment.yaml | kubectl apply -f -'
        //         sh 'envsubst < kubernetes/service.yaml | kubectl apply -f -'

        //     }
        // }

        stage('commit version update'){
            steps {
                script {
                    withCredentials([string(credentialsId: 'github-access-token', variable: 'TOKEN')]){
                        sh 'git config --global user.email "jenkins@example.com"'
                        sh 'git config --global user.name "jenkins"'

                        sh 'git status'
                        sh 'git branch'
                        sh 'git config --list'

                        sh "git remote set-url origin https://${TOKEN}@github.com/tonyrud/java-maven-app.git"
                        sh 'git add .'
                        sh 'git commit -m "ci: version bump - ${IMAGE_VERSION}"'
                        sh "git push origin HEAD:${GIT_BRANCH}"
                    }
                }
            }
        }
    }
}
