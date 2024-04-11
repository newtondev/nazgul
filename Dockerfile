FROM argoproj/argocd:v2.6.15 as argocd-builder

FROM alpine:3.19

ARG KUBECTL_VERSION=1.27.8
ARG KUBECTL_PLUGIN_ARGO_ROLLOUTS_VERSION=1.6.6
ARG KUSTOMIZE_VERSION=5.3.0
ARG HELM_VERSION=3.14.2
ARG OS=linux
ARG ARCH=amd64

# Be up to date with security patches
RUN apk update && apk upgrade --no-cache  && apk add --no-cache bash curl gettext git jq zip yq

# Kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/${OS}/${ARCH}/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl
# add Argo Rollouts kubectl plugin
RUN curl -LO https://github.com/argoproj/argo-rollouts/releases/download/v${KUBECTL_PLUGIN_ARGO_ROLLOUTS_VERSION}/kubectl-argo-rollouts-${OS}-${ARCH} && \
    chmod +x kubectl-argo-rollouts-${OS}-${ARCH} && \
    mv kubectl-argo-rollouts-${OS}-${ARCH} /usr/local/bin/kubectl-argo-rollouts

# Kustomize
RUN curl -LO "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_${OS}_${ARCH}.tar.gz"  && \
    tar xfvz kustomize* && \
    chmod +x kustomize && \
    mv kustomize /usr/local/bin/kustomize && \
    rm -rf kustomize*

# Helm
RUN curl -sL https://get.helm.sh/helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz | tar -xvz && \
    mv ${OS}-${ARCH}/helm /usr/local/bin/helm && \
    chown root:root /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    rm -rf ${OS}-${ARCH}
# add helm-diff plugin
RUN helm plugin install https://github.com/databus23/helm-diff && rm -rf /tmp/helm-*
# add helm-unittest
RUN helm plugin install https://github.com/helm-unittest/helm-unittest && rm -rf /tmp/helm-*

# ArgoCD CLI
COPY --from=argocd-builder /usr/local/bin/argocd /usr/local/bin/argocd

# Add a non-root user
RUN adduser --uid 1001 --disabled-password kube

USER kube
