# We must accommodate loading this file from repositories generated by
# our repository rules.
visibility("public")

_TOOLS_BY_RELEASE = {
    "v5.2.1": {
        struct(os = "darwin", arch = "amd64"): "b7aba749da75d33e6fea49a5098747d379abc45583ff5cd16e2356127a396549",
        struct(os = "darwin", arch = "arm64"): "f6a5f3cffd45bac585a0c80b5ed855c2b72d932a1d6e8e7c87aae3be4eba5750",
        struct(os = "linux", arch = "amd64"): "88346543206b889f9287c0b92c70708040ecd5aad54dd33019c4d6579cd24de8",
        struct(os = "linux", arch = "arm64"): "5566f7badece5a72d42075d8dffa6296a228966dd6ac2390de7afbb9675c3aaa",
        struct(os = "windows", arch = "amd64"): "870ccb282cb3404c471a7f270299ae0cf1310f354822b8c0a626f1edd0b3dcff",
        struct(os = "windows", arch = "arm64"): "ef5b2953cf792fa0118429c090113f697aca1810f6d5015838ad0917351ade9d",
    },
    "v5.1.0": {
        struct(os = "darwin", arch = "amd64"): "08664a17820138a68b7cbe302b1b63f4ec19c6e0838385f789ee0470f026ba25",
        # NB: There is no Darwin build available for the ARM64 architecture.
        struct(os = "linux", arch = "amd64"): "52f4cf1ba34d38fd55a9bef819e329c9a4561f5f57f8f539346038ab5026dda8",
        struct(os = "linux", arch = "arm64"): "4e333ccf092bb72ef5d6bfd3e1f8abb161b5540ce47a53474d70c58eeb99f0a9",
        struct(os = "windows", arch = "amd64"): "ac48286444a33417e5251393f1b1b9972b00cff82fd3ab8d21ca8d8c29411199",
        # NB: There is no Windows build available for the ARM64 architecture.
    },
    "v5.0.3": {
        struct(os = "darwin", arch = "amd64"): "a3300ccc81ed8e7df415f3537b49e70d89f985a28c9ade8a885ebf6f1689b4e0",
        struct(os = "darwin", arch = "arm64"): "ecb15ba64356507f8c73796acbe79b445c17f637963b05be72a905c05f6abfc1",
        struct(os = "linux", arch = "amd64"): "c627b1575c3fecbc7ad1c181c23a7adcacf19732dab627eb57e89a7bc4c1e929",
        struct(os = "linux", arch = "arm64"): "c92e9b4ad3ccd10077566eddddfc58748aa19ccc2b0fe17600fd57f6472b8bfe",
        struct(os = "windows", arch = "amd64"): "8228a69802ff97452afbbebcc3f4b42fb6c6cd859c66fc644dd03b438a3f7e32",
        struct(os = "windows", arch = "arm64"): "2ea55994009f91cbc90b5e56d72b8f1a5d2adfba016299c5e84fcdbb6fb578de",
    },
    "v5.0.1": {
        struct(os = "darwin", arch = "amd64"): "4a2b9f7fad0355c8bea08da6dd9c48e790df5f357983280998d80b8dc7ad3def",
        struct(os = "darwin", arch = "arm64"): "b264fe931e85d8ca7c7ac47872695b1fa39fe2b73cfc0d58cbdca0bde69d0bc0",
        struct(os = "linux", arch = "amd64"): "dca623b36aef84fbdf28f79d02e9b3705ff641424ac1f872d5420dadb12fb78d",
        struct(os = "linux", arch = "arm64"): "c6e036c5c7eee4c15f7544e441ced5cb6cf9eba24a011c25008df5617cd2fb85",
        struct(os = "windows", arch = "amd64"): "d9053411276df9fff3abc082fdb6dae4b2901d5b6c6c65d0e27f241dddbb9cb4",
        struct(os = "windows", arch = "arm64"): "3447de7560295843f698358823336d08738509dcafd47ad52385e0549894d51b",
    },
    "v5.0.0": {
        struct(os = "darwin", arch = "amd64"): "75bd0e776a1e1c44639aa017bba9b6a305ce7332b89b9e8089e99fee2b83d04a",
        struct(os = "darwin", arch = "arm64"): "74c576a9d6de9d6abb3e886141635b81e8cf3c2331b011535d4e8b5119f291db",
        struct(os = "linux", arch = "amd64"): "2e8c28a80ce213528251f489db8d2dcbea7c63b986c8f7595a39fc76ff871cd7",
        struct(os = "linux", arch = "arm64"): "e97b12a83e7b9b0407cac97cac4c25bc135c42383bd3764d5544e32c96542eca",
        struct(os = "windows", arch = "amd64"): "19d5e98dbe9a66fc0a75897b6557243c6f9d69c113c1fa4b34c1d3fa892cf74c",
        struct(os = "windows", arch = "arm64"): "55fe8b00b07b5701a6b537287b54bf0b70db05ffa9b0d7aa8f298256c8da57af",
    },
}

_DEFAULT_TOOL_VERSION = "v5.2.1"

def known_release_versions():
    return _TOOLS_BY_RELEASE.keys()

KustomizeInfo = provider(
    doc = "Details pertaining to the Kustomize toolchain.",
    fields = {
        "tool": "Kustomize tool to invoke",
        "version": "This tool's released version name",
    },
)

KustomizeToolInfo = provider(
    doc = "Details pertaining to the Kustomize tool.",
    fields = {
        "binary": "Kustomize tool to invoke",
        "version": "This tool's released version name",
    },
)

def _kustomize_tool_impl(ctx):
    return [KustomizeToolInfo(
        binary = ctx.executable.binary,
        version = ctx.attr.version,
    )]

kustomize_tool = rule(
    implementation = _kustomize_tool_impl,
    attrs = {
        "binary": attr.label(
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
            doc = "Kustomize tool to invoke",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "This tool's released version name",
        ),
    },
)

def _toolchain_impl(ctx):
    tool = ctx.attr.tool[KustomizeToolInfo]
    toolchain_info = platform_common.ToolchainInfo(
        kustomizeinfo = KustomizeInfo(
            tool = tool.binary,
            version = tool.version,
        ),
    )
    return [toolchain_info]

kustomize_toolchain = rule(
    implementation = _toolchain_impl,
    attrs = {
        "tool": attr.label(
            mandatory = True,
            providers = [KustomizeToolInfo],
            cfg = "exec",
            doc = "Kustomize tool to use for building kustomizations.",
        ),
    },
)

# buildifier: disable=unnamed-macro
def declare_kustomize_toolchains(kustomize_tool):
    for version, platforms in _TOOLS_BY_RELEASE.items():
        for platform in platforms.keys():
            kustomize_toolchain(
                name = "{}_{}_{}".format(platform.os, platform.arch, version),
                tool = kustomize_tool,
            )

def _translate_host_platform(ctx):
    # NB: This is adapted from rules_go's "_detect_host_platform" function.
    os = ctx.os.name
    if os == "mac os x":
        os = "darwin"
    elif os.startswith("windows"):
        os = "windows"

    arch = ctx.os.arch
    if arch == "aarch64":
        arch = "arm64"
    elif arch == "x86_64":
        arch = "amd64"

    return os, arch

_MODULE_REPOSITORY_NAME = "rules_kustomize"
_CONTAINING_PACKAGE_PREFIX = "//kustomize/private/tools/kustomize"

def _download_tool_impl(ctx):
    if not ctx.attr.arch and not ctx.attr.os:
        os, arch = _translate_host_platform(ctx)
    else:
        if not ctx.attr.arch:
            fail('"os" is set but "arch" is not')
        if not ctx.attr.os:
            fail('"arch" is set but "os" is not')
        os, arch = ctx.attr.os, ctx.attr.arch
    version = ctx.attr.version
    extension = ".zip" if os == "windows" else ".tar.gz"

    sha256sum = _TOOLS_BY_RELEASE[version][struct(os = os, arch = arch)]
    if not sha256sum:
        fail('No Kustomize tool is available for OS "{}" and CPU architecture "{}" at version {}'.format(os, arch, version))
    ctx.report_progress('Downloading Kustomize tool for OS "{}" and CPU architecture "{}" at version {}.'.format(os, arch, version))
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
        Label("{}:BUILD.tool.bazel".format(_CONTAINING_PACKAGE_PREFIX)),
        executable = False,
        substitutions = {
            "{containing_package_prefix}": "@{}{}".format(_MODULE_REPOSITORY_NAME, _CONTAINING_PACKAGE_PREFIX),
            # NB: In version 5.2.1, the released tools built for
            # Windows lacked an extension. Other releases use the
            # conventional ".exe" extension.
            "{extension}": ".exe" if os == "windows" and version != "v5.2.1" else "",
            "{version}": version,
        },
    )
    return None

_download_tool = repository_rule(
    implementation = _download_tool_impl,
    attrs = {
        "arch": attr.string(),
        "os": attr.string(),
        "version": attr.string(
            values = _TOOLS_BY_RELEASE.keys(),
            default = _DEFAULT_TOOL_VERSION,
        ),
    },
)

# buildifier: disable=unnamed-macro
def declare_bazel_toolchains(version, toolchain_prefix):
    native.constraint_value(
        name = version,
        constraint_setting = "{}:tool_version".format(_CONTAINING_PACKAGE_PREFIX),
    )
    constraint_value_prefix = "@{}//kustomize/private/tools".format(_MODULE_REPOSITORY_NAME)
    for platform in _TOOLS_BY_RELEASE[version].keys():
        native.toolchain(
            name = "{}_{}_{}_toolchain".format(platform.os, platform.arch, version),
            exec_compatible_with = [
                "{}:cpu_{}".format(constraint_value_prefix, platform.arch),
                "{}:os_{}".format(constraint_value_prefix, platform.os),
            ],
            toolchain = toolchain_prefix + (":{}_{}_{}".format(platform.os, platform.arch, version)),
            toolchain_type = "@{}//tools/kustomize:toolchain_type".format(_MODULE_REPOSITORY_NAME),
        )

def _toolchains_impl(ctx):
    ctx.template(
        "BUILD.bazel",
        Label("{}:BUILD.toolchains.bazel".format(_CONTAINING_PACKAGE_PREFIX)),
        executable = False,
        substitutions = {
            "{containing_package_prefix}": "@{}{}".format(_MODULE_REPOSITORY_NAME, _CONTAINING_PACKAGE_PREFIX),
            "{tool_repo}": ctx.attr.tool_repo,
            "{version}": ctx.attr.version,
        },
    )

_toolchains_repo = repository_rule(
    implementation = _toolchains_impl,
    attrs = {
        "tool_repo": attr.string(mandatory = True),
        "version": attr.string(
            values = _TOOLS_BY_RELEASE.keys(),
            default = _DEFAULT_TOOL_VERSION,
        ),
    },
)

def download_tool(name, version = None):
    _download_tool(
        name = name,
        version = version,
    )
    _toolchains_repo(
        name = name + "_toolchains",
        tool_repo = name,
        version = version,
    )
