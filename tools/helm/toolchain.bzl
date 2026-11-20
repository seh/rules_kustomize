visibility("public")

HelmInfo = provider(
    doc = 'Details pertaining to the toolchain for the "helm" tool.',
    fields = {
        "tool": 'The "helm" tool to invoke',
        "version": "This tool's released version name",
    },
)

_TOOLCHAIN_TYPE = Label("//tools/helm:toolchain_type")
_RUNTIME_TOOLCHAIN_TYPE = Label("//tools/helm:runtime_toolchain_type")

def _toolchain_attrs(binary_cfg):
    return {
        "binary": attr.label(
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = binary_cfg,
            doc = 'The "helm" tool to invoke',
        ),
        "version": attr.string(
            mandatory = True,
            doc = "This tool's released version name",
        ),
    }

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
    attrs = _toolchain_attrs("exec"),
)

helm_runtime_toolchain = rule(
    implementation = _toolchain_impl,
    doc = 'Defines a runtime toolchain for the "helm" tool.',
    attrs = _toolchain_attrs("target"),
)

def _runtime_binary_impl(ctx):
    tool = ctx.toolchains[_RUNTIME_TOOLCHAIN_TYPE].helminfo.tool
    executable = ctx.actions.declare_file("{}/{}".format(ctx.label.name, tool.basename))
    ctx.actions.symlink(
        output = executable,
        target_file = tool,
        is_executable = True,
    )
    return [DefaultInfo(
        executable = executable,
        files = depset([executable]),
    )]

helm_runtime_binary = rule(
    implementation = _runtime_binary_impl,
    doc = 'Yields the "helm" tool from the runtime toolchain that Bazel selects.',
    executable = True,
    toolchains = [_RUNTIME_TOOLCHAIN_TYPE],
)

def helm_toolchains(name, binary, version, constraint_values = []):
    """Declares a toolchain and a runtime toolchain for a "helm" tool.

    Args:
      name: The name of the "helm_toolchain" target. The other targets'
        names start with this name.
      binary: The "helm" tool to invoke.
      version: This tool's released version name.
      constraint_values: The constraint values of the platform on which
        this tool runs. Leave this empty for a tool built from source.
    """
    runtime_name = name + "_runtime"
    helm_toolchain(
        name = name,
        binary = binary,
        version = version,
    )
    helm_runtime_toolchain(
        name = runtime_name,
        binary = binary,
        version = version,
    )
    native.toolchain(
        name = name + "_toolchain",
        exec_compatible_with = constraint_values,
        toolchain = ":" + name,
        toolchain_type = _TOOLCHAIN_TYPE,
    )
    native.toolchain(
        name = runtime_name + "_toolchain",
        target_compatible_with = constraint_values,
        toolchain = ":" + runtime_name,
        toolchain_type = _RUNTIME_TOOLCHAIN_TYPE,
    )
