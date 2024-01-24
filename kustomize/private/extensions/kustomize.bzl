load(
    "//kustomize/private/tools/kustomize:toolchain.bzl",
    "download_tool",
    "known_release_versions",
)
load(
    ":download.bzl",
    "make_tag_class",
    "maximal_selected_version",
)

visibility("//kustomize")

def _kustomize_impl(ctx):
    download_tool(
        name = "kustomize_tool",
        version = maximal_selected_version(ctx, "kustomize"),
    )

kustomize = module_extension(
    implementation = _kustomize_impl,
    tag_classes = {
        "download": make_tag_class(known_release_versions()),
    },
)
