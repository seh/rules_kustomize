load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

ResolvedToolchainInfo = provider(fields = ["tool_path"])

def _current_toolchain_impl(ctx):
    tool_path = ctx.toolchains["//tools/kustomize:toolchain_type"].kustomizeinfo.tool.path
    return [ResolvedToolchainInfo(tool_path = tool_path)]

current_toolchain = rule(
    implementation = _current_toolchain_impl,
    toolchains = ["//tools/kustomize:toolchain_type"],
)

def _toolchain_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    actual_path = target[ResolvedToolchainInfo].tool_path
    expected_repo = ctx.attr.expected_repo

    asserts.true(
        env,
        expected_repo in actual_path,
        "Expected tool repository to contain '%s', got %s" % (expected_repo, actual_path),
    )

    return analysistest.end(env)

amd64_toolchain_test = analysistest.make(
    _toolchain_test_impl,
    attrs = {"expected_repo": attr.string()},
    config_settings = {"//command_line_option:extra_execution_platforms": ["//test:linux_amd64"]},
)

arm64_toolchain_test = analysistest.make(
    _toolchain_test_impl,
    attrs = {"expected_repo": attr.string()},
    config_settings = {"//command_line_option:extra_execution_platforms": ["//test:linux_arm64"]},
)

def toolchain_test_suite(name):
    current_toolchain(
        name = name + "_current_toolchain",
    )
    amd64_toolchain_test(
        name = name + "_amd64",
        target_under_test = ":" + name + "_current_toolchain",
        expected_repo = "kustomize_tool_linux_amd64",
    )
    arm64_toolchain_test(
        name = name + "_arm64",
        target_under_test = ":" + name + "_current_toolchain",
        expected_repo = "kustomize_tool_linux_arm64",
    )
