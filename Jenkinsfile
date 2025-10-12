pipeline {
  agent any

  parameters {
    choice(name: 'APP', choices: ['notes-api', 'snake-app'], description: 'Qué app desplegar')
    string(name: 'VERSION', defaultValue: 'v1', description: 'Tag de imagen (v1, v2, commit, etc.)')
    choice(name: 'DEPLOY_STRATEGY', choices: ['rolling', 'bluegreen'], description: 'Estrategia de despliegue k8s')
    booleanParam(name: 'RUN_TERRAFORM', defaultValue: false, description: 'Ejecutar Terraform antes de deploy')
  }

  options { timestamps(); ansiColor('xterm'); disableConcurrentBuilds() }

  environment {
    ENV_FILE = '.env'                                // archivo local (no subir a git)
    REGISTRY = 'docker.io'                           // default; puede sobreescribirse por .env o variables globales de Jenkins
    DOCKER_CREDENTIALS_ID = 'dockerhub-creds'        // Jenkins > Credentials (no en git)
    KUBECONFIG_CREDENTIALS_ID = 'kubeconfig-minikube'// Jenkins > Credentials (Secret file)
    TF_WORKDIR = 'infra'                              // carpeta .tf (si aplica)
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Load env') {
      steps {
        script {
          // Cargar variables desde .env si existe
          if (fileExists(env.ENV_FILE)) {
            def props = readProperties file: env.ENV_FILE
            props.each { k, v -> env."${k}" = v }
          }

          // Validación mínima: necesitamos REGISTRY_NAMESPACE para taggear/pushear
          if (!env.REGISTRY_NAMESPACE?.trim()) {
            error "REGISTRY_NAMESPACE no definido. Definilo en ${env.ENV_FILE} o como variable global de Jenkins."
          }

          // Calcular IMAGE en runtime (después de cargar .env)
          env.IMAGE = "${env.REGISTRY}/${env.REGISTRY_NAMESPACE}/${params.APP}:${params.VERSION}"
          echo "Usando imagen: ${env.IMAGE}"
        }
      }
    }

    stage('Build & Test') {
      steps {
        sh '''
          set -e
          echo "Construyendo imagen ${IMAGE}"
          docker build -t "${IMAGE}" -f "${params.APP}/Dockerfile" .
          # acá correrías tests si corresponde (unit/e2e)
        '''
      }
    }

    stage('Push Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin "${REGISTRY}"
            docker push "${IMAGE}"
          '''
        }
      }
    }

    stage('Terraform (opcional)') {
      when { expression { return params.RUN_TERRAFORM } }
      steps {
        dir("${TF_WORKDIR}") {
          sh '''
            set -e
            terraform init -input=false
            terraform plan -out=plan.tfplan -input=false
            terraform apply -input=false plan.tfplan
          '''
        }
      }
    }

    stage('Kubeconfig') {
      steps {
        withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIALS_ID, variable: 'KCFG')]) {
          sh 'export KUBECONFIG="$KCFG"; kubectl version --client=true'
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIALS_ID, variable: 'KCFG')]) {
          sh '''
            set -e
            export KUBECONFIG="$KCFG"

            # 1) ConfigMap/Manifiestos base (ej.: notes/configmap.yml, snake/configmap.yml)
            if [ -f "${APP}/k8s/configmap.yml" ]; then
              kubectl apply -f "${APP}/k8s/configmap.yml"
            fi
            if [ -d "${APP}/k8s/base" ]; then
              kubectl apply -f "${APP}/k8s/base"
            fi

            # 2) Estrategia de despliegue
            case "${DEPLOY_STRATEGY}" in
              rolling)
                # rolling: set image sobre el Deployment activo
                DEPLOY_NAME="${APP}-deploy"
                kubectl set image deployment/${DEPLOY_NAME} ${APP}-ctr="${IMAGE}" --record
                kubectl rollout status deployment/${DEPLOY_NAME} --timeout=120s
                ;;
              bluegreen)
                # blue/green: asume deployments ${APP}-blue y ${APP}-green y Service con selector "color"
                NEW_COLOR=$(kubectl get svc ${APP}-svc -o jsonpath='{.spec.selector.color}')
                if [ "$NEW_COLOR" = "blue" ]; then NEXT="green"; else NEXT="blue"; fi

                kubectl set image deployment/${APP}-${NEXT} ${APP}-ctr="${IMAGE}" --record
                kubectl rollout status deployment/${APP}-${NEXT} --timeout=120s

                # smoke test simple (podría ser curl a /health)
                kubectl get pods -l app=${APP},color=${NEXT}

                # switch del Service al color "NEXT"
                kubectl patch svc ${APP}-svc -p "{\"spec\": {\"selector\": {\"app\": \"${APP}\", \"color\": \"${NEXT}\"}}}"

                # opcional: rollback simple si falla smoke test extendido
                ;;
              *)
                echo "Estrategia desconocida"; exit 1
                ;;
            esac
          '''
        }
      }
    }
  }

  post {
    always { archiveArtifacts artifacts: '**/k8s/**/*.yml', allowEmptyArchive: true }
    success { echo "✅ Deploy OK: ${params.APP}:${params.VERSION} con ${params.DEPLOY_STRATEGY}" }
    failure { echo "❌ Falló el pipeline" }
  }
}