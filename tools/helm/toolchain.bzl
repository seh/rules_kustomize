visibility("public")

HelmInfo = provider(
    doc = 'Details pertaining to the toolchain for the "helm" tool.',
    fields = {
        "tool": 'The "helm" tool to invoke',
        "version": "This tool's released version name",
    },
)

def _toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        helminfo = HelmInfo(
            tool = ctx.executable.binary,
            version = ctx.attr.version,
        ),
    )
    return [toolchain_info]

helm_toolchain = rule(
    implementation = _toolchain_impl,
    doc = 'Defines a toolchain for the "helm" tool.',
    attrs = {
        "binary": attr.label(
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
            doc = 'The "helm" tool to invoke',
        ),
        "version": attr.string(
            mandatory = True,
            doc = "This tool's released version name",
        ),
    },
)
