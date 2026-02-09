.. role:: command(emphasis)
.. role:: field(code)
.. role:: file(emphasis)
.. role:: cmdflag(code)
.. role:: krmkind(emphasis)
.. role:: macro(code)
.. role:: pfield(code)
.. role:: ruleattr(kbd)
.. role:: term(emphasis)
.. role:: tool(emphasis)
.. role:: type(emphasis)
.. role:: value(code)
.. |mandatory| replace:: **mandatory value**
.. |propagated requirement| replace:: Even if this :term:`kustomization`'s top-level resources don't require such use but any of its base :term:`kustomizations` do, this value is effectively :value:`True`.

=================================
:tool:`kustomize` rules for Bazel
=================================

.. External links
.. _sandboxing: https://docs.bazel.build/versions/master/sandboxing.html
.. _kustomization term: https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#kustomization
.. See https://stackoverflow.com/a/4836544/31818 for this abomination:
.. |the kustomize tool| replace:: the :tool:`kustomize` tool
.. _the kustomize tool:
.. _kustomize: https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#kustomize
.. _resources:
.. _resource: https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#resource
.. _root: https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#kustomization-root

Integrate |the kustomize tool|_ into your Bazel projects to build Kubernetes-style manifests.

.. contents:: :depth: 2

-----

Overview
========

These Bazel rules allow you to define `kustomizations <kustomization term_>`__ within your project workspace and capture the output of *building* those kustomizations with |the kustomize tool|_. Using :tool:`kustomize` within a Bazel project orchestrates both the preparation of the input files—for when static files won't do—and consumption of the resulting YAML document stream, situating :tool:`kustomize` as a transformer in the middle of that data flow.

:tool:`kustomize` operates on the Kubernetes Resource Model (KRM), and most often comes into play just ahead of Kubernetes API clients like :tool:`kubectl`, sending the YAML document stream to the Kubernetes API to apply the resources_ to the cluster. These rules do no include any such interaction with the Kubernetes API. Instead, they focus solely on emitting the resources defined by the :term:`kustomization`.

Simple Example
--------------

Here we'll walk through a simple example to give a feel for how to use these Bazel rules.

Assume you have a :term:`kustomization` that defines a single Kubernetes :krmkind:`ConfigMap`, taking its data entries from both a file containing "environment variable"-style line-by-line definitions and some inline definitions in the :file:`kustomization.yaml` file. First, the :file:`kustomization.yaml` file:

.. code:: yaml

    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    configMapGenerator:
    - name: translations
      envs:
      - config-bindings
      literals:
      - HELLO=hola
      - GOODBYE=adios

Note that the "envs" field references a sibling file named :file:`config-bindings`, with content as follows:

.. code::

    THANK_YOU=gracias

If we run the :command:`kustomize build` command against the directory containing these two files, it emits the following YAML document:

.. code:: yaml

    apiVersion: v1
    data:
      GOODBYE: adios
      HELLO: hola
      THANK_YOU: gracias
    kind: ConfigMap
    metadata:
      name: translations-74424tmdd8

Now, let's teach Bazel to produce the same document.

By convention, we'll add a couple of Bazel targets to the :file:`BUILD.bazel` file in the same directory. First, we define the `kustomization <kustomization term_>`__ itself, indicating where the :term:`kustomization` file sits and which other files it depends on. For this, we use the kustomization_ rule.

.. code:: bazel

   load(
        "@rules_kustomize//kustomize:kustomize.bzl",
        "kustomization",
    )

    kustomization(
        name = "base",
        srcs = [
            "config-bindings",
        ],
    )

By default, the kustomization_ rule assumes the :file:`kustomization` file is named :file:`kustomization.yaml`, but you can also point it at other file names, such as the :file:`kustomization.yml` or :file:`kustomization` alternatives that the :tool:`kustomize` tool accepts.

This "base" target we've defined doesn't produce any artifacts. It prepares the recipe for building artifacts, in the same way that a :term:`kustomization`'s files are inert input for the :tool:`kustomize` tool. When we'd like to build the :term:`kustomization` using particular options—as we would by invoking :command:`kustomize build`—we define another target in a :file:`BUILD.bazel` file. Here we'll add to the same Bazel package, this time using the kustomized_resources_ rule.

.. code:: bazel

    load(
        "@rules_kustomize//kustomize:kustomize.bzl",
        "kustomized_resources",
    )

    kustomized_resources(
        name = "simple",
        kustomization = ":base",
    )

When we tell Bazel to build this new "simple" target, it will invoke :command:`kustomize build` and write the output to a file named :file:`simple.yaml`. That's the default mapping from target name to output file name, but you can change it with the kustomized_resources_ rule's :ruleattr:`result` attribute. Other Bazel targets can then demand this file as input, forcing Bazel to rebuild the file whenever—and only when—any of the input files change.

Integrating Into Your Project
=============================

In order to use these rules in your Bazel project, you must instruct Bazel to download the source and run the functions that make the rules available. Add the following to your project's :file:`MODULE.bazel` file.

.. code:: bazel

    bazel_dep(name = "rules_kustomize", version = "0.5.3")

This declaration registers a particular version of the :tool:`helm` and :tool:`kustomize` tools, respectively. By default, it registers `the latest version known to the rules <Tool Versions_>`_. You can specify a preferred version for each tool by supplying the known version slug (e.g. "v5.8.0") as an argument to the respective module extension's :field:`download` tag.

.. code:: bazel

    bazel_dep(name = "rules_kustomize", version = "0.5.3")

    kustomize = use_extension("@rules_kustomize//kustomize:extensions.bzl", "kustomize")
    kustomize.download(version = "v5.8.0")
    helm = use_extension("@rules_kustomize//kustomize:extensions.bzl", "helm")
    helm.download(version = "v3.13.1")

If any number of modules wind up specifying different version values for these tags, the latest version—per :term:`Semantic Versioning` sorting—among the proposed candidate versions wins. If any of the tags also include the :field:`tolerate_newer` attribute with a value of :value:`False`, then no competing version newer than that tag's proposed version can win.

With those calls in place, you're now ready to use the rules in your Bazel packages.

Tool Versions
=============

At present, these rules can load the following versions of these tools:

* :tool:`kustomize`

  * `v5.8.1 <https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.8.1>`__ (default)
  * `v5.8.0 <https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.8.0>`__
  * `v5.7.1 <https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.7.1>`__
  * `v5.7.0 <https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.7.0>`__
  * `v5.6.0 <https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.6.0>`__
  * `v5.5.0 <https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.5.0>`__

* :tool:`helm`

  * `v3.19.0 <https://github.com/helm/helm/releases/tag/v3.19.0>`__ (default)
  * `v3.17.4 <https://github.com/helm/helm/releases/tag/v3.17.4>`__
  * `v3.17.3 <https://github.com/helm/helm/releases/tag/v3.17.3>`__
  * `v3.13.1 <https://github.com/helm/helm/releases/tag/v3.13.1>`__

Rules
=====

kustomization
-------------

This defines a `kustomization <kustomization term_>`__ from a set of source files and other `kustomizations <kustomization_>`_, intended for referencing from one or more dependent kustomized_resources_ targets.

Providers
^^^^^^^^^

* KustomizationInfo_

Attributes
^^^^^^^^^^
+-----------------------------------------+-----------------------------+---------------------------------------+
| **Name**                                | **Type**                    | **Default value**                     |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`name`                        | :type:`string`              | |mandatory|                           |
+-----------------------------------------+-----------------------------+---------------------------------------+
| A unique name for the :term:`kustomization`. As there is usually only one such target defined  per Bazel      |
| package (assuming that the target is in the same package as the :term:`kustomization` file), a simple name    |
| like "base" is fitting.                                                                                       |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`deps`                        | :type:`label_list`          | :value:`[]`                           |
+-----------------------------------------+-----------------------------+---------------------------------------+
| The set of `kustomizations <kustomization_>`_ referenced as resources_ by this :term:`kustomization`.         |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`file`                        | :type:`label`               | :value:`kustomization.yaml`           |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :file:`kustomization.yaml`, :file:`kustomization.yml`, or :file:`kustomization` file for this                 |
| :term:`kustomization`.                                                                                        |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`requires_exec_functions`     | :type:`bool`                | :value:`False`                        |
+-----------------------------------------+-----------------------------+---------------------------------------+
| Whether this :term:`kustomization` requires use of exec functions (raw executables) (per the                  |
| :cmdflag:`--enable-exec` :tool:`kustomize` flag).                                                             |
|                                                                                                               |
| |propagated requirement|                                                                                      |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`requires_helm`               | :type:`bool`                | :value:`False`                        |
+-----------------------------------------+-----------------------------+---------------------------------------+
| Whether this :term:`kustomization` requires use of the Helm chart inflator generator (per the                 |
| :cmdflag:`--enable-helm` :tool:`kustomize` flag).                                                             |
|                                                                                                               |
| |propagated requirement|                                                                                      |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`requires_plugins`            | :type:`bool`                | :value:`False`                        |
+-----------------------------------------+-----------------------------+---------------------------------------+
| Whether this :term:`kustomization` requires use of :tool:`kustomize` plugins (per the                         |
| :cmdflag:`--enable-alpha-plugins` :tool:`kustomize` flag).                                                    |
|                                                                                                               |
| |propagated requirement|                                                                                      |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`requires_starlark_functions` | :type:`bool`                | :value:`False`                        |
+-----------------------------------------+-----------------------------+---------------------------------------+
| Whether this :term:`kustomization` requires use of Starlark functions (per the :cmdflag:`--enable-star`       |
| :tool:`kustomize` flag).                                                                                      |
|                                                                                                               |
| |propagated requirement|                                                                                      |
+-----------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`srcs`                        | :type:`label_list`          | :value:`[]`                           |
+-----------------------------------------+-----------------------------+---------------------------------------+
| Files referenced as resources_ for this :term:`kustomization`.                                                |
+-----------------------------------------+-----------------------------+---------------------------------------+

Example
^^^^^^^

.. code:: bazel

    kustomization(
        name = "overlay",
        deps = [
            # This target "base:base" is another kustomization.
            "//apps/base"
        ],
        # We can omit the "file" attribute because our kustomization
        # file is named "kustomization.yaml," matching the default.
        srcs = [
            # This target "charts:charts" is a filegroup.
            "//apps/base/charts",
            "extras.yaml",
        ],
        requires_helm = True,
    )

kustomized_resources
--------------------

This defines an invocation of the :command:`kustomize build` command against a :term:`kustomization` `target <https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#target>`_, creating a resulting set of :term:`resources` (collectively, a `variant <https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#variant>`_).

See the Difficulties_ section below for considerations both with :term:`kustomizations` that involve use of the :field:`helmCharts` :krmkind:`Kustomization` (or :krmkind:`Component`) field and when executing Bazel actions on some computers.

Attributes
^^^^^^^^^^

+---------------------------------------+-----------------------------+---------------------------------------+
| **Name**                              | **Type**                    | **Default value**                     |
+---------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`name`                      | :type:`string`              | |mandatory|                           |
+---------------------------------------+-----------------------------+---------------------------------------+
| A unique name for the :term:`variant`.                                                                      |
+---------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`env_bindings`              | :type:`string_dict`         | :value:`{}`                           |
+---------------------------------------+-----------------------------+---------------------------------------+
| Names and values of environment variables to be used by functions (per the :cmdflag:`--env`                 |
| :tool:`kustomize` flag).                                                                                    |
|                                                                                                             |
| These bindings specify a value for each environment variable. To forward an exported environment variable's |
| through instead, use the :ruleattr:`env_exports` attribute.                                                 |
+---------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`env_exports`               | :type:`string_list`         | :value:`[]`                           |
+---------------------------------------+-----------------------------+---------------------------------------+
| Names of exported environment variables to be used by functions (per the :cmdflag:`--env` :tool:`kustomize` |
| flag).                                                                                                      |
|                                                                                                             |
| These bindings forward each exported environment variable's value. To specify a value for each environment  |
| variable instead, use the :ruleattr:`env_bindings` attribute.                                               |
+---------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`kustomization`             | :type:`label`               | |mandatory|                           |
+---------------------------------------+-----------------------------+---------------------------------------+
| The :term:`kustomization` to build.                                                                         |
|                                                                                                             |
| This may refer to a target using the kustomization_ rule or another rule that yields a KustomizationInfo_   |
| provider.                                                                                                   |
+---------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`load_restrictor`           | :type:`string`              | :value:`RootOnly`                     |
+---------------------------------------+-----------------------------+---------------------------------------+
| Control whether :term:`kustomizations` may load files from outsider their root directory (per the           |
| :cmdflag:`--load-restrictor` :tool:kustomize flag). May be one of :value:`None` or :value:`RootOnly`.       |
|                                                                                                             |
| See the Difficulties_ section for cases where you may need to set this value to :value:`None` within        |
| Bazel when you could normally get by with the :tool:`kustomize` tool's default behavior of preventing       |
| :term:`kustomizations` from loading files from outside their root_.                                         |
+---------------------------------------+-----------------------------+---------------------------------------+
| :ruleattr:`result`                    | :type:`output`              | :value:`<name>.yaml`                  |
+---------------------------------------+-----------------------------+---------------------------------------+
| The built result, as a YAML stream of KRM resources in separate documents (per the :cmdflag:`--output`      |
| :tool:`kustomize` flag).                                                                                    |
+---------------------------------------+-----------------------------+---------------------------------------+

Example
^^^^^^^

.. code:: bazel

    kustomized_resources(
        name = "production",
        env_bindings = {
            "CLUSTER_NAME": "prod1234",
            "ENVIRONMENT": "production",
        },
        kustomization = ":overlay",
    )

Providers
=========

KustomizationInfo
-----------------

:type:`KustomizationInfo` summarizes a :term:`kustomization` root_, as provided by the kustomization_ rule.

Fields
^^^^^^

+---------------------------------------+----------------------------------------------------------+
| **Name**                              | **Type**                                                 |
+---------------------------------------+----------------------------------------------------------+
| :pfield:`requires_exec_functions`     | :type:`bool`                                             |
+---------------------------------------+----------------------------------------------------------+
| Whether this :term:`kustomization` requires use of exec functions (raw executables) (per the     |
| :cmdflag:`--enable-exec` :tool:`kustomize` flag).                                                |
+---------------------------------------+----------------------------------------------------------+
| :pfield:`requires_helm`               | :type:`bool`                                             |
+---------------------------------------+----------------------------------------------------------+
| Whether this :term:`kustomization` requires use of the Helm chart inflator generator (per the    |
| :cmdflag:`--enable-helm` :tool:`kustomize` flag).                                                |
+---------------------------------------+----------------------------------------------------------+
| :pfield:`requires_plugins`            | :type:`bool`                                             |
+---------------------------------------+----------------------------------------------------------+
| Whether this :term:`kustomization` requires use of :tool:`kustomize` plugins (per the            |
| :cmdflag:`--enable-alpha-plugins` :tool:`kustomize` flag).                                       |
+---------------------------------------+----------------------------------------------------------+
| :pfield:`requires_starlark_functions` | :type:`bool`                                             |
+---------------------------------------+----------------------------------------------------------+
| Whether this :term:`kustomization` requires use of Starlark functions (per the                   |
| :cmdflag:`--enable-star` :tool:`kustomize` flag).                                                |
+---------------------------------------+----------------------------------------------------------+
| :pfield:`target_file`                 | :type:`string`                                           |
+---------------------------------------+----------------------------------------------------------+
| The top-level :term:`kustomization` file defining this :term:`kustomization`.                    |
+---------------------------------------+----------------------------------------------------------+
| :pfield:`transitive_resources`        | :type:`depset of File`                                   |
+---------------------------------------+----------------------------------------------------------+
| The set of files (including other :term:`kustomizations`) referenced by this                     |
| :term:`kustomization`.                                                                           |
+---------------------------------------+----------------------------------------------------------+

Difficulties
============

These rules attempt to make using :tool:`kustomize` with Bazel easier, but there are a few features of the tools that interact poorly, or at least surprisingly, even when they're individually doing their job as intended. We can work around each problem once we know better what to expect.

Bazel's Sandbox and Load Restrictors
------------------------------------

:tool:`kustomize` prefers to load files only from the :term:`kustomization` root directory—the one containing the :file:`kustomization.yaml` file—or any of its subdirectories. The :command:`kustomize build` subcommand runs with a :term:`load restrictor` to enforce this restrictive policy. By default, the :cmdflag:`--load-restrictor` flag uses the value :value:`LoadRestrictionsRootOnly`. With that value in effect, :command:`kustomize build` will refuse to read any files referenced by a :term:`kustomization` that lie outside of the :term:`kustomization` root directory tree, per `this FAQ entry <https://kubectl.docs.kubernetes.io/faq/kustomize/#security-file-foo-is-not-in-or-below-bar>`__.

Bazel can execute the actions for its :command:`build` and :command:`test` commands in a restricted environment called a :term:`sandbox`, using a technique called sandboxing_. On some operating systems, Bazel uses symbolic links to make only some files available to programs it runs in its actions. These symbolic links point upward and outward to files that lie outside of the :term:`kustomization` root in the sandbox. Even though the links are within the :term:`kustomization` root, their target files are not. :tool:`kustomize` considers this to transgress its :value:`LoadRestrictionsRootOnly` load restriction and blocks the attempt to load the referenced file.

There are three ways around this problem:

* Relax :tool:`kustomize`'s load restrictor by passing :value:`LoadRestrictionsNone` to its :cmdflag:`--load-restrictor` flag, by way of specifying the value :value:`None` for the kustomized_resources_ rule's :ruleattr:`load_restrictor` attribute.

* Use a Bazel sandboxing_ implementation that doesn't rely on symbolic links, such as its `sandboxfs <https://docs.bazel.build/versions/master/sandboxing.html#sandboxfs_>`__ FUSE file system. With the :tool:`sandboxfs` tool installed, pass the :cmdflag:`--experimental_use_sandboxfs` `flag <https://docs.bazel.build/versions/master/command-line-reference.html#flag--experimental_use_sandboxfs>`__ to :command:`bazel build`, :command:`bazel test`, or :command:`bazel run`.

  **NB:** As of Bazel version 7.0.0, per `commit b6e2693f83a7ece37c902416de26a3807b541ceb <https://github.com/bazelbuild/bazel/commit/b6e2693f83a7ece37c902416de26a3807b541ceb>`__, the :cmdflag:`--experimental_use_sandboxfs` flag is no longer available. Bazel no longer supports use of the :tool:`sandboxfs` tool. See :tool:`kustomize` `issue 5216 <https://github.com/kubernetes-sigs/kustomize/issues/5216>`__ for an alternate proposed workaround, which is implemented but not merged.

.. _disable sandboxing:

* Disable Bazel sandboxing_ entirely by omitting :value:`sandboxed` from the values supplied via its :cmdflag:`--spawn_strategy` `flag <https://docs.bazel.build/versions/master/command-line-reference.html#flag--spawn_strategy>`__. With sandboxing disabled, Bazel will present the input files to :tool:`kustomize` as regular files. So long as those files lie within the :term:`kustomization` root, the :value:`LoadRestrictionsRootOnly` load restrictor will not intervene.


Downloading Helm Charts
-----------------------

The :tool:`kustomize` tool can expand Helm charts using the :krmkind:`Kustomization` manifest's :field:`helmCharts` `field <https://github.com/kubernetes-sigs/kustomize/blob/master/examples/chart.md>`__. If the Helm chart's source files are not available already locally, :tool:`kustomize` can fetch the chart archive and unpack within the directory specified in the :field:`helmGlobals.chartHome` `field <https://github.com/kubernetes-sigs/kustomize/blob/master/examples/chart.md#build-the-base-and-the-variants>`__. By default, this :field:`chartHome` field's value is :value:`charts`, meaning that :tool:`kustomize` will download and expand chart archives in the :file:`charts/<chart name>` directory within the :term:`kustomization` root.

Now, first, let's acknowledge that the :tool:`kustomize` maintainers do **not** recommend `downloading Helm charts automatically <https://github.com/kubernetes-sigs/kustomize/blob/master/examples/chart.md#but-its-not-really-about-performance>`__, nor `even relying on Helm for repeated expansion at all <https://github.com/kubernetes-sigs/kustomize/blob/master/examples/chart.md#best-practice>`__. The capability is there in :tool:`kustomize` today, though, so let's clarify how Bazel might interfere.

What could go wrong? Consider:

* If Bazel sandboxing_ is enabled, you can't have :tool:`kustomize` download and write files within the sandbox directory tree.

  Instead, you can set the :krmkind:`Kustomization` :field:`helmGlobals.chartHome` field to a directory to which Bazel is allowed to write, such as :file:`/tmp`. Alternately, you can `disable sandboxing`_ entirely.

* If your :term:`kustomization` directs :tool:`kustomize` to store Helm chart files outside of the :term:`kustomization` root, or even just refers to such distant files, the default load restrictor will block :tool:`kustomize` from reading them.

  You must relax the default load restrictor by specifying the value :value:`None` for the kustomized_resources_ rule's :ruleattr:`load_restrictor` attribute.

Given that your chosen use of Bazel likely implies a preference for hermetic and repeatable builds, it's best to at least acquire and unpack the Helm chart archives beforehand, committing the resulting files for future use. Expanding the Helm chart as manifests outside of :tool:`kustomize` is even better, though it's then harder to include artifacts generated by other Bazel rules. Finding the right balance will take some experimentation.
