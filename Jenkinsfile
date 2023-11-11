pipeline {
    agent any
    stages {      
        stage('Destroy previous infrastructure') {
            steps {
                sh '''
                    cd ~/DevOps-SecondDemo/
                    terraform init
                    terraform state rm aws_route53_zone.primary
                    terraform destroy -auto-approve
                    cd ~
                    rm -rf ~/DevOps-SecondDemo/
                '''
            }
        }
/*     
        stage('Clone repository') {
            steps {
                sh '''
                    cd ~
                    git clone https://github.com/RichyCey/DevOps-SecondDemo.git
                '''
            }
        }
        stage('Create EC Registry') {
            steps {
                withCredentials([string(credentialsId: 'DATADOG_API', variable: 'datadog_id')]) {
                    sh '''
                        cd ~/DevOps-SecondDemo/
                        terraform init
                        terraform apply -auto-approve -target=module.ecr -var "DATADOG_API_KEY=${datadog_id}"
                    '''
                }
            }
        }
        stage('Build&Push to Registry') {
            steps {
                withCredentials([string(credentialsId: 'AWS_REGION', variable: 'aws_region'), string(credentialsId: 'AWS_ID', variable: 'aws_id')]) {
                    sh '''
                        aws --version
                        cd ~/DevOps-SecondDemo/
                        docker build . -t softserve-demo-ecr:latest
                        aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${aws_id}.dkr.ecr.${aws_region}.amazonaws.com
                        docker tag softserve-demo-ecr ${aws_id}.dkr.ecr.${aws_region}.amazonaws.com/softserve-demo-ecr:lastest
                        docker push ${aws_id}.dkr.ecr.${aws_region}.amazonaws.com/softserve-demo-ecr:lastest
                    '''
                }
            }
        }
        stage('Creating Infrastructure') {
            steps {
                withCredentials([string(credentialsId: 'DATADOG_API', variable: 'datadog_id'), string(credentialsId: 'ROUTE53_ID', variable: 'route53_zone_id')]) {
                    sh '''
                        cd ~/DevOps-SecondDemo/
                        terraform init
                        terraform import aws_route53_zone.primary ${route53_zone_id}
                        terraform apply -auto-approve -var "DATADOG_API_KEY=${datadog_id}"
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
*/
    }
}