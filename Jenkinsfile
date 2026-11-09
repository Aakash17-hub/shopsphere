// ShopSphere: deploy to the Minikube host over SSH with a least-privilege ServiceAccount.
// Started manually from Jenkins (Build with Parameters). GitLab CI keeps deploying on push to main.
//
// Jenkins runs as the "jenkins" OS user and logs in as "jenkins-deploy" on the Minikube host.
// That user only has a kubeconfig for the jenkins-deployer ServiceAccount (see bootstrap/jenkins-deployer.yaml).

pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    parameters {
        booleanParam(name: 'DEPLOY', defaultValue: true,
                     description: 'Apply the manifests. Untick for a validate-only run.')
    }

    stages {
        stage('Validate') {
            steps {
                sh '''
                    set -eu
                    SSH="ssh -i $HOME/.ssh/minikube_deploy -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=yes jenkins-deploy@10.0.1.237"
                    FILES=$(ls k8s/*.yaml | grep -v -E '/(00-namespace|01-rbac)[.]yaml$')
                    echo "Manifests: $FILES"
                    for f in $FILES; do cat "$f"; echo; echo '---'; done | $SSH "kubectl apply --dry-run=server -f -"
                '''
            }
        }

        stage('Deploy') {
            when { expression { return params.DEPLOY } }
            steps {
                sh '''
                    set -eu
                    SSH="ssh -i $HOME/.ssh/minikube_deploy -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=yes jenkins-deploy@10.0.1.237"
                    FILES=$(ls k8s/*.yaml | grep -v -E '/(00-namespace|01-rbac)[.]yaml$')

                    # Remember each Deployment's generation, so that only Deployments
                    # changed by THIS deploy can be rolled back.
                    gens() {
                        $SSH "kubectl -n shopsphere get deploy -o custom-columns=NAME:.metadata.name,GEN:.metadata.generation --no-headers" | awk '{print $1, $2}' | sort
                    }
                    gens > before.txt
                    [ -s before.txt ] || { echo "Cannot read the Deployments on the cluster"; exit 1; }

                    for f in $FILES; do cat "$f"; echo; echo '---'; done | $SSH "kubectl apply -f -"

                    gens > after.txt
                    CHANGED=$(comm -13 before.txt after.txt | awk '{print $1}')
                    echo "Changed by this deploy: ${CHANGED:-none}"

                    FAILED=""
                    for d in $($SSH "kubectl -n shopsphere get deploy -o name"); do
                        $SSH "kubectl -n shopsphere rollout status $d --timeout=180s" || FAILED="$FAILED ${d#deployment.apps/}"
                    done

                    if [ -n "$FAILED" ]; then
                        for d in $FAILED; do
                            if echo "$CHANGED" | grep -qx "$d"; then
                                echo "Rolling back $d"
                                $SSH "kubectl -n shopsphere rollout undo deployment/$d"
                                $SSH "kubectl -n shopsphere rollout status deployment/$d --timeout=180s" || true
                            else
                                echo "$d is unhealthy but this deploy did not change it, so it is not rolled back"
                            fi
                        done
                        echo "Deploy failed for:$FAILED"
                        exit 1
                    fi
                '''
            }
        }

        stage('Verify') {
            when { expression { return params.DEPLOY } }
            steps {
                sh '''
                    set -eu
                    SSH="ssh -i $HOME/.ssh/minikube_deploy -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=yes jenkins-deploy@10.0.1.237"
                    $SSH "kubectl -n shopsphere get pods"
                '''
            }
        }
    }
}
