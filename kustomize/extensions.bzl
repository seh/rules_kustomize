load(
    "//kustomize/private/extensions:helm.bzl",
    _helm = "helm",
)
load(
    "//kustomize/private/extensions:kustomize.bzl",
    _kustomize = "kustomize",
)

visibility("public")

helm = _helm
kustomize = _kustomize
