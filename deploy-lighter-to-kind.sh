#!/bin/bash
set -e

echo "==> Deploying Lighter to Kind cluster..."

CLUSTER_NAME="${KIND_CLUSTER_NAME:-lighter-test}"
IMAGE_NAME="${LIGHTER_IMAGE:-lighter:test}"
NAMESPACE="spark"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed."
    exit 1
fi

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Create namespace if it doesn't exist
echo "==> Creating namespace '${NAMESPACE}'..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# Create ServiceAccount
echo "==> Creating ServiceAccount..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: lighter
  namespace: ${NAMESPACE}
EOF

# Create Role
echo "==> Creating Role..."
cat <<EOF | kubectl apply -f -
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: lighter
  namespace: ${NAMESPACE}
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "pods/log"]
    verbs: ["*"]
EOF

# Create RoleBinding
echo "==> Creating RoleBinding..."
cat <<EOF | kubectl apply -f -
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: lighter
  namespace: ${NAMESPACE}
subjects:
  - kind: ServiceAccount
    name: lighter
    namespace: ${NAMESPACE}
roleRef:
  kind: Role
  name: lighter
  apiGroup: rbac.authorization.k8s.io
EOF

# Create Service
echo "==> Creating Service..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: lighter
  namespace: ${NAMESPACE}
  labels:
    run: lighter
spec:
  type: NodePort
  ports:
    - name: api
      port: 8080
      targetPort: 8080
      nodePort: 30080
      protocol: TCP
    - name: javagw
      port: 25333
      targetPort: 25333
      protocol: TCP
  selector:
    run: lighter
EOF

# Create Deployment
echo "==> Creating Deployment..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: ${NAMESPACE}
  name: lighter
spec:
  selector:
    matchLabels:
      run: lighter
  replicas: 1
  strategy:
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  template:
    metadata:
      labels:
        run: lighter
    spec:
      containers:
        - image: ${IMAGE_NAME}
          name: lighter
          imagePullPolicy: Never
          readinessProbe:
            httpGet:
              path: /health/readiness
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 15
          resources:
            requests:
              cpu: "0.25"
              memory: "512Mi"
          ports:
            - containerPort: 8080
          env:
            - name: LIGHTER_KUBERNETES_ENABLED
              value: "true"
            - name: LIGHTER_MAX_RUNNING_JOBS
              value: "15"
            - name: LIGHTER_KUBERNETES_SERVICE_ACCOUNT
              value: lighter
            - name: LIGHTER_SESSION_TRACK_RUNNING_INTERVAL
              value: 10s
      serviceAccountName: lighter
EOF

echo ""
echo "==> Deployment complete!"
echo ""
echo "Waiting for Lighter pod to be ready..."
kubectl wait --for=condition=ready pod -l run=lighter -n "${NAMESPACE}" --timeout=300s

echo ""
echo "==> Lighter is running!"
echo ""
echo "Access Lighter at: http://localhost:8080/lighter/"
echo "Access Swagger UI at: http://localhost:8080/swagger-ui/"
echo ""
echo "To check status: kubectl get all -n ${NAMESPACE}"
echo "To view logs: kubectl logs -f deployment/lighter -n ${NAMESPACE}"
echo "To port-forward (if NodePort doesn't work): kubectl port-forward -n ${NAMESPACE} svc/lighter 8080:8080"
