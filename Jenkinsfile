pipeline {
  agent any

  options {
    timeout(time: 20, unit: 'MINUTES')
  }

  parameters {
    string(name: 'IMAGE_NAME', defaultValue: 'myflask', description: 'Docker 镜像名称')
    string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Docker 镜像标签')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Docker image') {
      steps {
        script {
          // 需要 Jenkins 构建节点安装 Docker CLI 并具备运行权限
          env.BUILT_IMAGE = "${params.IMAGE_NAME}:${params.IMAGE_TAG}"
          currentBuild.displayName = "${env.BUILD_NUMBER} ${env.BUILT_IMAGE}"
          sh label: 'Docker build', script: """
            set -euxo pipefail
            docker version
            docker build -t "${BUILT_IMAGE}" .
          """
        }
      }
    }

    stage('Deploy Service') {
        steps {
            script {
                def image = "${params.IMAGE_NAME}:${params.IMAGE_TAG}"
                def cname = "myflask-prod" // 使用一个永久的名称
                def hostPort = "5000"      // 或您想要的任何对外端口

                sh label: 'Deploy Production Container', script: """
                    set -euxo pipefail
                    # 停止并移除旧的生产容器
                    docker rm -f "${cname}" >/dev/null 2>&1 || true

                    # 部署新容器，绑定到 0.0.0.0 (允许所有接口访问)
                    # 移除 127.0.0.1
                    docker run -d --name "${cname}" -p ${hostPort}:5000 "${image}"
                """
                echo "Flask 服务已部署到 http://[Jenkins主机的IP]:${hostPort}"
            }
        }
    }

    // 如需推送镜像，可在此添加 withRegistry(...) 并 docker.push()
  }

  post {
    always {
      archiveArtifacts artifacts: 'Dockerfile,main.py,inspect-*.json,container-*.log', fingerprint: true, onlyIfSuccessful: false
    }
  }
}
