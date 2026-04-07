pipeline {
    // Run on any available Jenkins agent
    agent any

    // Variables used across all stages
    environment {
        DOCKER_IMAGE = "samm11000/task-api"
        DOCKER_TAG   = "${BUILD_NUMBER}"  // auto-increments
        APP_SERVER = "13.203.157.50"
    }

    stages {

        stage('Checkout') {
            steps {
                // Clone your GitHub repo
                checkout scm
                echo 'Code checked out successfully'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build image with build number as tag
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    // Use credentials stored in Jenkins (see step 4.4)
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub123',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        sh "docker push ${DOCKER_IMAGE}:latest"
                    }
                }
            }
        }

       stage('Deploy with Ansible') {
    steps {
        script {
            withCredentials([sshUserPrivateKey(
                credentialsId: 'ec2-key',
                keyFileVariable: 'SSH_KEY'
            )]) {
                sh """
                ansible-playbook \
                  -i ansible/inventory.ini \
                  ansible/deploy.yml \
                  -e "docker_image=${DOCKER_IMAGE}:${DOCKER_TAG}" \
                  --private-key $SSH_KEY \
                  --ssh-extra-args='-o StrictHostKeyChecking=no'
                """
            }
        }
    }
}
           

        stage('Health Check') {
            steps {
                script {
                    sleep(10)  // wait for container to start
                    sh "curl -f http://${APP_SERVER}/health || exit 1"
                    echo 'App is healthy!'
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline succeeded! App deployed successfully.'
        }
        failure {
            echo 'Pipeline FAILED. Check logs above.'
        }
    }
}