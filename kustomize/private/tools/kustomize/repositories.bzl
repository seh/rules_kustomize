visibility("//kustomize/private/extensions")

_TOOLS_BY_RELEASE = {
    "v5.8.3": {
        struct(os = "darwin", arch = "amd64"): "d08fb85846c3d977f0e2a66e7ff45f1b5264c294685e5e726e1a8bdfe0da8dee",
        struct(os = "darwin", arch = "arm64"): "4cbb08e209d8fff47cd60bfb6407daaf5ee699f9b9295849a1065024fac2d1ef",
        struct(os = "linux", arch = "amd64"): "cb9e31198d3f63b44848bd0afc4c8efc56e6cfef9c93a4a39a211940e6decd61",
        struct(os = "linux", arch = "arm64"): "9867b76482cfc6d25b546abc1d2b5a32bd137505aba640649b4b378f64f6d68f",
        struct(os = "windows", arch = "amd64"): "763c4040ff01435bfce39661072452ebdf1cf2808bb91f5708ab4420834fbd42",
        struct(os = "windows", arch = "arm64"): "b86236917e649e2f9531899c519f333e554cd1fc0c87132b86b885bf315735dc",
    },
    "v5.8.1": {
        struct(os = "darwin", arch = "amd64"): "ee7cf0c1e3592aa7bb66ba82b359933a95e7f2e0b36e5f53ed0a4535b017f2f8",
        struct(os = "darwin", arch = "arm64"): "8886f8a78474e608cc81234f729fda188a9767da23e28925802f00ece2bab288",
        struct(os = "linux", arch = "amd64"): "029a7f0f4e1932c52a0476cf02a0fd855c0bb85694b82c338fc648dcb53a819d",
        struct(os = "linux", arch = "arm64"): "0953ea3e476f66d6ddfcd911d750f5167b9365aa9491b2326398e289fef2c142",
        struct(os = "windows", arch = "amd64"): "8ec7f5e815e526d4622c06df0a7793d8cfb6eb1c74f816b46166097fef8b26c6",
        struct(os = "windows", arch = "arm64"): "f6f5090c373965760a30a59af84c81853b80d2c7dbb3236424f440e47eed3f5a",
    },
    "v5.8.0": {
        struct(os = "darwin", arch = "amd64"): "2deaa6f96450c0b3204cccd9f159a22278eb6cf85ad545d212d608d2428aeb57",
        struct(os = "darwin", arch = "arm64"): "d098f62ecda500c752303163838af823f947d245927f3000b629199c1eeeae0f",
        struct(os = "linux", arch = "amd64"): "4dfa8307358dd9284aa4d2b1d5596766a65b93433e8fa3f9f74498941f01c5ef",
        struct(os = "linux", arch = "arm64"): "a4f48b4c3d4ca97d748943e19169de85a2e86e80bcc09558603e2aa66fb15ce1",
        struct(os = "windows", arch = "amd64"): "7779999c8eb7bdbbaa55c6ecf4fadfdbe7508199ea189f06862835e7e5cb1e41",
        struct(os = "windows", arch = "arm64"): "a08acc2b1191f7bd192f31ed7ee1c0a5a743228a21ac239862248a47f800a016",
    },
    "v5.7.1": {
        struct(os = "darwin", arch = "amd64"): "4a0dff80c5644df6bc8f51b342842969004cb6ba5f94dddaabbea7483493273d",
        struct(os = "darwin", arch = "arm64"): "073e9d16d5a235e2ff83e62d6b76edb5d962adbc33be1e4860c4b3f1f39b33b9",
        struct(os = "linux", arch = "amd64"): "ea375e7372f9aa029129d4b2d16c66b7750b7f1213c4f66f910d981c895818d8",
        struct(os = "linux", arch = "arm64"): "4261a040217df3bd6896597c3986d1465925726e4f22a945304b5233a4dcdbda",
        struct(os = "windows", arch = "amd64"): "4704f8b47582c1c52bf76a50b37178f7f7de17f892713794a8bf44b01b50e0ce",
        struct(os = "windows", arch = "arm64"): "d838872ffd5efcd240e6b308a7899b2bb537352b2eb99a6b3fbb023df9ca7c0d",
    },
    "v5.7.0": {
        struct(os = "darwin", arch = "amd64"): "277a7401f969ce3945e8f0ff8b0cce6f4353854db1ff89ba070001e3246e7f22",
        struct(os = "darwin", arch = "arm64"): "c0dac68dc7870e1f673ae4d8fb554df971e0b9b9f0affc4be4c0852f62d0796e",
        struct(os = "linux", arch = "amd64"): "0d98f06d6d2c2c0ff8923cc136a517af74aaa187f1b9f3e17ff370d0625ede84",
        struct(os = "linux", arch = "arm64"): "744bb1bc1854b6634dea9eaf6db2f401a734ed25d6837baa6f91157d79c27d5e",
        struct(os = "windows", arch = "amd64"): "eacee576f22e8c0cb1ff2840ec6496aa42346d5a23936fed9899f7019ed2af62",
        struct(os = "windows", arch = "arm64"): "acb94b010781663abe4ffce7d674da31a644c6df9839f73fa6711d5fe13574c0",
    },
}

_DEFAULT_TOOL_VERSION = "v5.8.3"

def known_release_versions():
    return _TOOLS_BY_RELEASE.keys()

_TOOL_REPO_PREFIX = "kustomize_tool"
_TOOLCHAINS_REPO_NAME = _TOOL_REPO_PREFIX + "_toolchains"

def _tool_repo_name(platform):
    return "{}_{}_{}".format(_TOOL_REPO_PREFIX, platform.os, platform.arch)

def _download_tool_impl(ctx):
    os, arch = ctx.attr.os, ctx.attr.arch
    version = ctx.attr.version
    extension = ".zip" if os == "windows" else ".tar.gz"

    sha256sum = _TOOLS_BY_RELEASE[version][struct(os = os, arch = arch)]
    ctx.report_progress('Downloading the "kustomize" tool for OS "{}" and CPU architecture "{}" at version {}.'.format(os, arch, version))
    ctx.download_and_extract(
        url = "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F{version}/kustomize_{version}_{os}_{arch}{extension}".format(
            arch = arch,
            extension = extension,
            os = os,
            version = version,
        ),
        sha256 = sha256sum,
    )

    ctx.template(
        "BUILD.bazel",
        Label("//kustomize/private/tools:BUILD.tool.bazel.template"),
        executable = False,
        substitutions = {
            "{extension}": ".exe" if os == "windows" else "",
            "{tool_name}": "kustomize",
            "{toolchain_bzl}": str(Label("//tools/kustomize:toolchain.bzl")),
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
            "{alias_visibility}": str(Label("//tools/kustomize:__pkg__")),
            "{platforms}": repr(platforms),
            "{runtime_toolchain_type}": str(Label("//tools/kustomize:runtime_toolchain_type")),
            "{tool_name}": "kustomize",
            "{toolchain_bzl}": str(Label("//tools/kustomize:toolchain.bzl")),
            "{toolchain_type}": str(Label("//tools/kustomize:toolchain_type")),
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
