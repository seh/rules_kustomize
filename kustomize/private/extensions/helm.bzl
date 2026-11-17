load(
    "//kustomize/private/tools/helm:repositories.bzl",
    "download_tool",
    "known_release_versions",
)
load(
    ":download.bzl",
    "make_tag_class",
    "maximal_selected_version",
)

visibility("//kustomize")

def _helm_impl(ctx):
    download_tool(
        version = maximal_selected_version(ctx, "helm"),
    )

helm = module_extension(
    implementation = _helm_impl,
    tag_classes = {
        "download": make_tag_class(known_release_versions()),
    },
)
