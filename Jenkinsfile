pipeline {
    agent any

    environment {
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
    }

    stages {
        stage('Validate Deployments') {
            steps {
                sh '''
                    set -e
                    kubectl get deployments
                    kubectl rollout status deployment/myapp-blue --timeout=120s
                    kubectl rollout status deployment/myapp-green --timeout=120s
                '''
            }
        }

        stage('Switch Traffic to Green') {
            steps {
                sh '''
                    set -e
                    kubectl patch service myapp-service \
                      -p '{"spec":{"selector":{"app":"myapp","color":"green"}}}'
                    kubectl get service myapp-service -o yaml
                '''
            }
        }

        stage('Verify Green Version') {
            steps {
                sh '''
                    set -eu

                    kubectl port-forward --address 127.0.0.1 \
                      service/myapp-service 18081:80 \
                      > /tmp/jenkins-blue-green-portforward.log 2>&1 &
                    PF_PID=$!
                    trap 'kill "$PF_PID" 2>/dev/null || true' EXIT

                    for i in $(seq 1 20); do
                        if curl --fail --silent http://127.0.0.1:18081 \
                          | grep -q 'GREEN VERSION - v2'; then
                            echo "SUCCESS: Green version is serving traffic"
                            exit 0
                        fi
                        sleep 2
                    done

                    echo "ERROR: Green health check failed"
                    cat /tmp/jenkins-blue-green-portforward.log
                    exit 1
                '''
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed. Rolling traffic back to Blue.'
            sh '''
                kubectl patch service myapp-service \
                  -p '{"spec":{"selector":{"app":"myapp","color":"blue"}}}' \
                  || true
                kubectl get service myapp-service -o yaml
            '''
        }

        success {
            echo 'SUCCESS: Green deployment is live.'
        }
    }
}
