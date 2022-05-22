load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
)

_helm_releases = {
    "v3.9.0": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "7e5a2f2a6696acf278ea17401ade5c35430e2caa57f67d4aa99c607edcc08f5e",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "1484ffb0c7a608d8069470f48b88d729e88c41a1b6602f145231e8ea7b43b50a",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "bcdc6c68dacfabeeb6963dc2e6761e2e87026ffd9ea1cde266ee36841e7c6e6a",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "631d333bce5f2274c00af753d54bb62886cdb17a958d2aff698c196612c9e8cb",
        },
    ],
    "v3.8.1": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "3b6d87d360a51bf0f2344edd54e3580a8e8de2c4a4fd92eccef3e811f7e81bb3",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "d643f48fe28eeb47ff68a1a7a26fc5142f348d02c8bc38d699674016716f61cd",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "dbf5118259717d86c57d379317402ed66016c642cc0d684f3505da6f194b760d",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "a75003fc692131652d3bd218dd4007692390a1dd156f11fd7668e389bdd8f765",
        },
    ],
}

_kustomize_releases = {
    "v4.5.4": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "8dfd2648948eac4b1bd996e0c87f6fe3f451db54e265cf42cbadb94b0c56f553",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "1159c5c17c964257123b10e7d8864e9fe7f9a580d4124a388e746e4003added3",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "094417546ab9b44ece44f3b31f3170080d0682519144301d5b6be080276a1f34",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "954dfa7e3fa0b3f86de5b62f0de7ac0e45cc1385eb8694afd2a5a1ac5dcb1e63",
        },
    ],
    "v4.5.3": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "b0a6b0568273d466abd7cd535c556e44aa9ff5f54c07e86ed9f3016b416de992",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "e4dc2f795235b03a2e6b12c3863c44abe81338c5c0054b29baf27dcc734ae693",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "97cf7d53214388b1ff2177a56404445f02d8afacb9421339c878c5ac2c8bc2c8",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "ad5ac5ed8d244309e4a41cfd61e87918096e159514e4867c9449409b67a6709f",
        },
    ],
    "v4.5.1": [
        {
            "os": "darwin",
            "arch": "amd64",
            "sha256": "427d1d32bdde47f3b36a848253d1c936f623ffc4dbe4137c1deadd2c099a9000",
        },
        {
            "os": "linux",
            "arch": "amd64",
            "sha256": "cc26e18e814fd162dacd5e2a1357aa133fb91589e23a15ccc8b7c163fd259c54",
        },
        {
            "os": "linux",
            "arch": "arm64",
            "sha256": "4873fb965cad3a646bea4ffc2f2f9189501fe7bc6f0ae8854920593b9ba13d73",
        },
        {
            "os": "windows",
            "arch": "amd64",
            "sha256": "1b8062331e6af223017d015d6df2b32f8580bf9ed2f9c92bcd718aa371e6e218",
        },
    ],
}

def _maybe(repo_rule, name, **kwargs):
    """Executes the given repository rule if it hasn't been executed already.

    Args:
      repo_rule: The repository rule to be executed (e.g., `native.git_repository`.)
      name: The name of the repository to be defined by the rule.
      **kwargs: Additional arguments passed directly to the repository rule.
    """
    if not native.existing_rule(name):
        repo_rule(name = name, **kwargs)

def helm_register_tool(version = "v3.9.0"):
    for platform in _helm_releases[version]:
        suffix = "tar.gz"
        if platform["os"] == "windows":
            suffix = "zip"
        _maybe(
            http_archive,
            name = "helm_tool_%s_%s" % (platform["os"], platform["arch"]),
            build_file_content = """
filegroup(
    name = "binary",
    srcs = ["helm%s"],
    visibility = ["//visibility:public"],
)
""" % (".exe" if platform["os"] == "windows" else ""),
            strip_prefix = "%s-%s" % (platform["os"], platform["arch"]),
            url = "https://get.helm.sh/helm-%s-%s-%s.%s" % (version, platform["os"], platform["arch"], suffix),
            sha256 = platform["sha256"],
        )

def kustomize_register_tool(version = "v4.5.4"):
    for platform in _kustomize_releases[version]:
        _maybe(
            http_archive,
            name = "kustomize_tool_%s_%s" % (platform["os"], platform["arch"]),
            build_file_content = """
filegroup(
    name = "binary",
    srcs = ["kustomize%s"],
    visibility = ["//visibility:public"],
)
""" % (".exe" if platform["os"] == "windows" else ""),
            url = "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/%s/kustomize_%s_%s_%s.tar.gz" % (version, version, platform["os"], platform["arch"]),
            sha256 = platform["sha256"],
        )
