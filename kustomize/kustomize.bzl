load(
    "@rules_shell//shell:sh_binary.bzl",
    "sh_binary",
)
load(
    "//kustomize/private:future.bzl",
    _runfile_path = "runfile_path",
)

KustomizationInfo = provider(
    doc = "Kustomization root summary",
    fields = {
        "requires_exec_functions": "Whether this kustomization requires use of exec functions (raw executables).",
        "requires_helm": "Whether this kustomization requires use of the Helm chart inflator generator.",
        "requires_plugins": "Whether this kustomization requires use of kustomize plugins.",
        "requires_starlark_functions": "Whether this kustomization requires use of Starlark functions.",
        "target_file": "The top-level kustomization file defining this kustomization.",
        "transitive_resources": "The set of files (including other kustomizations) referenced by this kustomization.",
    },
)

_kustomization_attrs = {
    "deps": attr.label_list(
        doc = "The set of kustomizations referenced as resources by this kustomization.",
        providers = [KustomizationInfo],
    ),
    "file": attr.label(
        doc = "kustomization.yaml, kustomization.yml, or kustomization file for this kustomization.",
        allow_single_file = True,
    ),
    "requires_exec_functions": attr.bool(
        doc = """Whether this kustomization requires use of exec functions (raw executables).

Even if this kustomization's top-level resources don't require such
use but any of its base kustomizations do, this value is effectively
True.""",
    ),
    "requires_helm": attr.bool(
        doc = """Whether this kustomization requires use of the Helm chart inflator generator.

Even if this kustomization's top-level resources don't require such
use but any of its base kustomizations do, this value is effectively
True.""",
    ),
    "requires_plugins": attr.bool(
        doc = """Whether this kustomization requires use of kustomize plugins.

Even if this kustomization's top-level resources don't require such
use but any of its base kustomizations do, this value is effectively
True.""",
    ),
    "requires_starlark_functions": attr.bool(
        doc = """Whether this kustomization requires use of Starlark functions.

Even if this kustomization's top-level resources don't require such
use but any of its base kustomizations do, this value is effectively
True.""",
    ),
    "srcs": attr.label_list(
        doc = "Files referenced as resources for this kustomization.",
        allow_files = True,
    ),
}

def _kustomization_impl(ctx):
    k_file = ctx.file.file

    return [
        KustomizationInfo(
            requires_exec_functions =
                ctx.attr.requires_exec_functions or
                any([dep[KustomizationInfo].requires_exec_functions for dep in ctx.attr.deps]),
            requires_helm =
                ctx.attr.requires_helm or
                any([dep[KustomizationInfo].requires_helm for dep in ctx.attr.deps]),
            requires_plugins =
                ctx.attr.requires_plugins or
                any([dep[KustomizationInfo].requires_plugins for dep in ctx.attr.deps]),
            requires_starlark_functions =
                ctx.attr.requires_starlark_functions or
                any([dep[KustomizationInfo].requires_starlark_functions for dep in ctx.attr.deps]),
            target_file = k_file,
            transitive_resources = depset(
                direct = [ctx.file.file] + ctx.files.srcs,
                transitive = [dep[KustomizationInfo].transitive_resources for dep in ctx.attr.deps],
            ),
        ),
    ]

_kustomization = rule(
    attrs = _kustomization_attrs,
    implementation = _kustomization_impl,
)

def kustomization(name, **kwargs):
    file = kwargs.pop("file", "kustomization.yaml")

    _kustomization(
        name = name,
        file = file,
        **kwargs
    )

def _kustomization_runfiles_impl(ctx):
    kustomization = ctx.attr.kustomization[KustomizationInfo]
    return [
        DefaultInfo(runfiles = ctx.runfiles(
            files = [kustomization.target_file],
            transitive_files = kustomization.transitive_resources,
        )),
    ]

_kustomization_runfiles = rule(
    implementation = _kustomization_runfiles_impl,
    attrs = {
        "kustomization": attr.label(
            doc = "kustomization to build.",
            providers = [KustomizationInfo],
            mandatory = True,
        ),
    },
)

_kustomized_resources_attrs = {
    # Unfortunately, we can't use a private attribute for an implicit
    # dependency here, because we can't fix the default label value.
    "kustomize_build": attr.label(
        executable = True,
        allow_files = True,
        cfg = "exec",
        mandatory = True,
    ),
    "env_bindings": attr.string_dict(
        doc = "Names and values of environment variables to be used by functions.",
    ),
    "env_exports": attr.string_list(
        doc = "Names of exported environment variables to be used by functions.",
    ),
    "kustomization": attr.label(
        doc = "kustomization to build.",
        providers = [KustomizationInfo],
        mandatory = True,
    ),
    "load_restrictor": attr.string(
        doc = "Control whether kustomizations may load files from outsider their root directory.",
        values = [
            "None",
            "RootOnly",
        ],
        default = "RootOnly",
    ),
    "result": attr.output(
        doc = "The built result, as a YAML stream of KRM resources in separate documents.",
        mandatory = True,
    ),
}

_kustomize_toolchain_type = "//tools/kustomize:toolchain_type"
_helm_toolchain_type = "//tools/helm:toolchain_type"

def _kustomized_resources_impl(ctx):
    kustomization = ctx.attr.kustomization[KustomizationInfo]
    kustomize_tool = ctx.toolchains[_kustomize_toolchain_type].kustomizeinfo.tool
    helm_tool = None
    args = ctx.actions.args()

    args.add(_runfile_path(ctx, kustomization.target_file))
    if kustomization.requires_helm:
        info = ctx.toolchains[_helm_toolchain_type].helminfo
        if not info:
            fail("No Helm toolchain is available; unable to proceed with invoking kustomize without it")
        helm_tool = info.tool
        args.add("--enable-helm")
        args.add("--helm-command", helm_tool.path)
    if kustomization.requires_exec_functions:
        args.add("--enable-exec")
    if kustomization.requires_plugins:
        args.add("--enable-alpha-plugins")
    if kustomization.requires_starlark_functions:
        args.add("--enable-star")

    # Place exported environment varibles first, allowing shadowing by
    # explicit bindings
    for name in ctx.attr.env_exports:
        if len(name) == 0:
            fail(msg = "exported environment variable name must not be empty")
        args.add("--env", name)
    for name, v in ctx.attr.env_bindings.items():
        if len(name) == 0:
            fail(msg = "bound environment variable name must not be empty")
        args.add(
            "--env",
            "{}={}".format(name, v),
        )
    if ctx.attr.load_restrictor != "RootOnly":
        args.add("--load-restrictor", "LoadRestrictionsNone")
    args.add("--output", ctx.outputs.result)

    # Allow inclusion of "--action_env" variables when they're likely to be
    # significant:
    use_default_shell_env = len(ctx.attr.env_exports) > 0
    mnemonic = "KustomizeBuild"
    progress_message = "Building the \"{}\" kustomization target {}".format(ctx.label.name, kustomization.target_file)

    # In order to allow kustomize to find all the input files in the
    # same directory tree, as opposed to spread among different Bazel
    # "roots" depending on whether the file is derived or not, consume
    # the files as Bazel runfiles, folding together contributions from
    # each of these "roots."
    #
    # If there are no derived files involved, we don't need to adjust
    # the paths like that.
    ctx.actions.run(
        executable = ctx.executable.kustomize_build,
        arguments = [
            kustomize_tool.path,
            args,
        ],
        tools = [kustomize_tool] +
                ([helm_tool] if kustomization.requires_helm else []),
        outputs = [ctx.outputs.result],
        use_default_shell_env = use_default_shell_env,
        mnemonic = mnemonic,
        progress_message = progress_message,
    )

_kustomized_resources = rule(
    attrs = _kustomized_resources_attrs,
    implementation = _kustomized_resources_impl,
    toolchains = [
        _kustomize_toolchain_type,
        config_common.toolchain_type(
            _helm_toolchain_type,
            mandatory = False,
        ),
    ],
)

def kustomized_resources(name, **kwargs):
    result = kwargs.pop("result", name + ".yaml")
    target_kustomization = kwargs["kustomization"]
    tags = kwargs.get("tags", [])

    runfiles_name = name + "_kustomization_runfiles"
    kustomize_build_name = name + "_kustomize_build_from_runfiles"
    _kustomization_runfiles(
        name = runfiles_name,
        kustomization = target_kustomization,
        tags = tags,
    )
    native.config_setting(
        name = name + "_lacks_runfiles_directory",
        constraint_values = [
            Label("@platforms//os:windows"),
        ],
    )
    sh_binary(
        name = kustomize_build_name,
        # NB: On Windows, we don't expect to have a runfiles directory
        # available, so instead we rely on a runfiles manifest to tell
        # us which files should be present where. We use a ZIP archive
        # to collect and project these runfiles into the right place.
        srcs = select({
            ":{}_lacks_runfiles_directory".format(name): [Label("//kustomize:kustomize-build-from-archived-runfiles")],
            "//conditions:default": [Label("//kustomize:kustomize-build-from-runfiles")],
        }),
        data = [":" + runfiles_name] + select({
            ":{}_lacks_runfiles_directory".format(name): ["@bazel_tools//tools/zip:zipper"],
            "//conditions:default": [],
        }),
        deps = ["@bazel_tools//tools/bash/runfiles"],
        tags = tags,
    )
    _kustomized_resources(
        name = name,
        kustomize_build = ":" + kustomize_build_name,
        result = result,
        **kwargs
    )
