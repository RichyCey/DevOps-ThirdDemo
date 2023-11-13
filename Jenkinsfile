pipeline {
    agent any
    stages {
        stage('Destroy previous infrastructure') {
            steps {
                sh '''
                    cd ~/DevOps-ThirdDemo/
                    kubectl delete -f k8s/aws-test.yaml
                    kubectl delete -f k8s/deployment.yaml
                    kubectl delete -f k8s/public-lb.yaml
                    terraform init
                    terraform destroy -auto-approve
                    cd ~
                    rm -rf ~/DevOps-ThirdDemo/
                '''
            }
        } 
        stage('Clone repository') {
            steps {
                sh '''
                    cd ~
                    git clone https://github.com/RichyCey/DevOps-ThirdDemo.git
                '''
            }
        }
        stage('Creating Infrastructure') {
            steps {
                withCredentials([string(credentialsId: 'AWS_REGION', variable: 'aws_region'), string(credentialsId: 'ROUTE53_ID', variable: 'route53_zone_id')]) {
                    sh '''
                        cd ~/DevOps-ThirdDemo/
                        terraform init
                        terraform apply -auto-approve
                    '''
                }
            }
        }
        stage('Build&Push to Registry') {
            steps {
                withCredentials([string(credentialsId: 'AWS_REGION', variable: 'aws_region'), string(credentialsId: 'AWS_ID', variable: 'aws_id')]) {
                    sh '''
                        aws --version
                        cd ~/DevOps-ThirdDemo/
                        docker build . -t softserve-demo:latest
                        aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${aws_id}.dkr.ecr.${aws_region}.amazonaws.com
                        docker tag softserve-demo ${aws_id}.dkr.ecr.${aws_region}.amazonaws.com/softserve-demo:lastest
                        docker push ${aws_id}.dkr.ecr.${aws_region}.amazonaws.com/softserve-demo:lastest
                    '''
                }
            }
        }
        stage('Launching app') {
            steps {
                withCredentials([string(credentialsId: 'AWS_REGION', variable: 'aws_region'), string(credentialsId: 'ROUTE53_ID', variable: 'route53_zone_id')]) {
                    sh '''
                        cd ~/DevOps-ThirdDemo/
                        aws eks --region ${aws_region} update-kubeconfig --name demo
                        kubectl apply -f k8s/aws-test.yaml
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/public-lb.yaml
                        
                    '''
                }
            }
        }      
        stage("Cleaning build environment"){
            steps{
                sh '''
                    docker system prune -a --volumes -f
                '''
            }
        }
        stage("Add DNS"){
            steps{
                withCredentials([string(credentialsId: 'AWS_REGION', variable: 'aws_region')]) {
                    sh '''
                        aws eks --region ${aws_region} update-kubeconfig --name demo
                        ~/update_route53.sh
                    '''
                }
            }
        }
    }
}