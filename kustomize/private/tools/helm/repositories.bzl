visibility("//kustomize/private/extensions")

_TOOLS_BY_RELEASE = {
    "v4.3.0": {
        struct(os = "darwin", arch = "amd64"): "347a784877e0e20eac865e8d1c36a80f6bb0861d6f29abd34defb6570ef95d92",
        struct(os = "darwin", arch = "arm64"): "d3870437e1e95b67f8edbde964156c84a26503f560821d40c542441658934fba",
        struct(os = "linux", arch = "amd64"): "86584a54def73570558f66f5111cc53dfed56689637ae32c1201205d494f54fb",
        struct(os = "linux", arch = "arm64"): "31c5794dd55c66a51e6b7d2e2ac7a114ae8b1de41ff1d9ba51748ac973b06a08",
        struct(os = "windows", arch = "amd64"): "304ea163cce4d9ad14e189c01846c6a34de9cfdfe48536ae54b2e8ba7884e67c",
        struct(os = "windows", arch = "arm64"): "4a9eefa30d26eb73900a9a0f16e97eae678582172204db60cbd454c68acea246",
    },
    "v4.1.1": {
        struct(os = "darwin", arch = "amd64"): "6b8dbb03abb74e9ab8e69ca3f9b6459178be11317d0ac502f922621c05fdc866",
        struct(os = "darwin", arch = "arm64"): "b8f49e105b1d2fd8c8a90ba3fc9af48db91d2d1ca3b9e788352fc7c896bbb71a",
        struct(os = "linux", arch = "amd64"): "5d4c7623283e6dfb1971957f4b755468ab64917066a8567dd50464af298f4031",
        struct(os = "linux", arch = "arm64"): "02a5fb7742469d2d132e24cb7c3f52885894043576588c6788b6813297629edd",
        struct(os = "windows", arch = "amd64"): "665161eba861d86bdb6969aa15d0d0cac3f04ce950ca12b4ee0552d7967a61fa",
        struct(os = "windows", arch = "arm64"): "bd73ebc89311de201d6d86fc20ced76d7f448579332c54093fc086a2279d905d",
    },
    "v3.19.0": {
        struct(os = "darwin", arch = "amd64"): "09a108c0abda42e45af172be65c49125354bf7cd178dbe10435e94540e49c7b9",
        struct(os = "darwin", arch = "arm64"): "31513e1193da4eb4ae042eb5f98ef9aca7890cfa136f4707c8d4f70e2115bef6",
        struct(os = "linux", arch = "amd64"): "a7f81ce08007091b86d8bd696eb4d86b8d0f2e1b9f6c714be62f82f96a594496",
        struct(os = "linux", arch = "arm64"): "440cf7add0aee27ebc93fada965523c1dc2e0ab340d4348da2215737fc0d76ad",
        struct(os = "windows", arch = "amd64"): "6488630c2e5d5945ed990fa02fd9e99f9c6792cdbcd79eb264b6cfb90179d2d1",
        struct(os = "windows", arch = "arm64"): "488f7530a1776da1b46b14e988bf305c9d7419c78e7e73aeb92f198a41c9ef6b",
    },
}

_DEFAULT_TOOL_VERSION = "v4.3.0"

def known_release_versions():
    return _TOOLS_BY_RELEASE.keys()

_TOOL_REPO_PREFIX = "helm_tool"
_TOOLCHAINS_REPO_NAME = _TOOL_REPO_PREFIX + "_toolchains"

def _tool_repo_name(platform):
    return "{}_{}_{}".format(_TOOL_REPO_PREFIX, platform.os, platform.arch)

def _download_tool_impl(ctx):
    os, arch = ctx.attr.os, ctx.attr.arch
    version = ctx.attr.version

    sha256sum = _TOOLS_BY_RELEASE[version][struct(os = os, arch = arch)]
    ctx.report_progress('Downloading the "helm" tool for OS "{}" and CPU architecture "{}" at version {}.'.format(os, arch, version))
    ctx.download_and_extract(
        url = "https://get.helm.sh/helm-{}-{}-{}.{}".format(
            version,
            os,
            arch,
            "zip" if os == "windows" else "tar.gz",
        ),
        stripPrefix = "{}-{}".format(os, arch),
        sha256 = sha256sum,
    )

    ctx.template(
        "BUILD.bazel",
        Label("//kustomize/private/tools:BUILD.tool.bazel.template"),
        executable = False,
        substitutions = {
            "{extension}": ".exe" if os == "windows" else "",
            "{tool_name}": "helm",
            "{toolchain_bzl}": str(Label("//tools/helm:toolchain.bzl")),
            "{toolchains_repo}": _TOOLCHAINS_REPO_NAME,
            "{version}": version,
        },
    )
    return None

_download_tool = repository_rule(
    implementation = _download_tool_impl,
    attrs = {
        "arch": attr.string(mandatory = True),
        "os": attr.string(mandatory = True),
        "version": attr.string(
            values = _TOOLS_BY_RELEASE.keys(),
            default = _DEFAULT_TOOL_VERSION,
        ),
    },
)

def _toolchains_impl(ctx):
    version = ctx.attr.version
    platforms = {}
    for platform in _TOOLS_BY_RELEASE[version].keys():
        tool_repo = _tool_repo_name(platform)
        platforms["{}_{}".format(platform.os, platform.arch)] = {
            "binary": "@{}//:binary".format(tool_repo),
            "constraint_values": [
                str(Label("//kustomize/private/tools:cpu_{}".format(platform.arch))),
                str(Label("//kustomize/private/tools:os_{}".format(platform.os))),
            ],
            "toolchain": "@{}//:toolchain".format(tool_repo),
        }
    ctx.template(
        "BUILD.bazel",
        Label("//kustomize/private/tools:BUILD.toolchains.bazel.template"),
        executable = False,
        substitutions = {
            "{alias_visibility}": str(Label("//tools/helm:__pkg__")),
            "{platforms}": repr(platforms),
            "{tool_name}": "helm",
            "{toolchain_type}": str(Label("//tools/helm:toolchain_type")),
            "{version}": version,
        },
    )

_toolchains_repo = repository_rule(
    implementation = _toolchains_impl,
    attrs = {
        "version": attr.string(
            values = _TOOLS_BY_RELEASE.keys(),
            default = _DEFAULT_TOOL_VERSION,
        ),
    },
)

def download_tool(version = None):
    for platform in _TOOLS_BY_RELEASE[version or _DEFAULT_TOOL_VERSION].keys():
        _download_tool(
            name = _tool_repo_name(platform),
            arch = platform.arch,
            os = platform.os,
            version = version,
        )
    _toolchains_repo(
        name = _TOOLCHAINS_REPO_NAME,
        version = version,
    )
