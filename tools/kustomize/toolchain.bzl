visibility("public")

KustomizeInfo = provider(
    doc = 'Details pertaining to the toolchain for the "kustomize" tool.',
    fields = {
        "tool": 'The "kustomize" tool to invoke',
        "version": "This tool's released version name",
    },
)

def _toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        kustomizeinfo = KustomizeInfo(
            tool = ctx.executable.binary,
            version = ctx.attr.version,
        ),
    )
    return [toolchain_info]

kustomize_toolchain = rule(
    implementation = _toolchain_impl,
    doc = 'Defines a toolchain for the "kustomize" tool.',
    attrs = {
        "binary": attr.label(
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
            doc = 'The "kustomize" tool to invoke',
        ),
        "version": attr.string(
            mandatory = True,
            doc = "This tool's released version name",
        ),
    },
)
