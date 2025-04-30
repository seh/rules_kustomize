load(
    "@bazel_skylib//rules:diff_test.bzl",
    "diff_test",
)
load(
    "//kustomize:kustomize.bzl",
    "kustomization",
    "kustomized_resources",
)

def kustomize_test(
        name,
        srcs = [],
        deps = [],
        kustomization_file = None,
        golden_file = None,
        requires_helm = False,
        **kwargs):
    kustomization(
        name = name,
        deps = deps,
        file = kustomization_file or "testdata/%s/kustomization.yaml" % name,
        requires_helm = requires_helm,
        srcs = srcs,
    )

    genrule_name = name + "_resources"
    generated_resources_file = genrule_name + ".yaml"

    kustomized_resources(
        name = genrule_name,
        kustomization = name,
        # Allow running these basic tests in CI with fewer
        # requirements imposed on the host machines, trusting that the
        # tests don't attempt anything unsafe against which kustomize
        # defends by default.
        load_restrictor = "None",
        result = generated_resources_file,
        **kwargs
    )
    diff_test(
        name = name + "_test",
        file1 = generated_resources_file,
        file2 = golden_file or "testdata/%s/golden.yaml" % name,
        size = "small",
    )
