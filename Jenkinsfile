pipeline {
    // Run on any available Jenkins agent
    agent any

    // Variables used across all stages
    environment {
        DOCKER_IMAGE = "YOUR_USERNAME/task-api"
        DOCKER_TAG   = "${BUILD_NUMBER}"  // auto-increments
        APP_SERVER   = "13.235.xx.xx"
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
                        credentialsId: 'dockerhub-creds',
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
                    // Run Ansible playbook to deploy to app server
                    sh """
                        ansible-playbook \
                          -i ansible/inventory.ini \
                          ansible/deploy.yml \
                          --vault-password-file ~/.vault_pass \
                          -e "docker_image=${DOCKER_IMAGE}:${DOCKER_TAG}"
                    """
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