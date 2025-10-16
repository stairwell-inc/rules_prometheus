def _amtool_impl(ctx):
    amtool_info = (
        ctx.toolchains["@io_bazel_rules_prometheus//prometheus:toolchain"]
            .prometheusToolchainInfo
            .amtool
    )
    output = ctx.actions.declare_file("%s.out.sh" % ctx.label.name)

    runfiles = ctx.runfiles(
        files = ctx.files._template,
        transitive_files = amtool_info.tool.files,
    )
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = output,
        is_executable = True,
        substitutions = {
            "%tool_path%": "%s" % amtool_info.tool.files_to_run.executable.short_path,
        },
    )
    return [DefaultInfo(runfiles = runfiles, executable = output)]

_amtool = rule(
    implementation = _amtool_impl,
    doc = """Private rule implemented for invocation in public promtool() runner""",
    attrs = {
        "_template": attr.label(
            default = Label("@io_bazel_rules_prometheus//prometheus/internal:amtool.manual_runner.sh.tpl"),
            allow_single_file = True,
        ),
    },
    executable = True,
    toolchains = ["@io_bazel_rules_prometheus//prometheus:toolchain"],
)

def amtool(name, **kwargs):
    """Amtool runner which will launch amtool

    This rule will emit a sh_binary target which invokes the amtool binary with provided args.

    Example:
    ```
    //:amtool
    load("//prometheus:defs.bzl", "amtool")

    package(default_visibility = ["//visibility:public"])

    amtool(
        name = "amtool",
        args = [
          "check-config",
          "$(locations :config.yaml)",
        ],
        data = [":config.yaml"],
    )
    ```

    Args:
      name: A unique name for this target.
      **kwargs: Attributes to be passed along
    """
    runner = name + "-runner"
    _amtool(
        name = runner,
        tags = ["manual"],
        **kwargs
    )
    native.sh_binary(
        name = name,
        srcs = [runner],
        tags = ["manual"],
    )

def _amtool_config_test_impl(ctx):
    amtool_info = (
      ctx.toolchains["@io_bazel_rules_prometheus//prometheus:toolchain"]
      .prometheusToolchainInfo
      .amtool
    )

    runfiles = ctx.runfiles(
      files = ctx.files.config,
      transitive_files = amtool_info.tool.files,
    )

    test = ctx.actions.declare_file("%s.out.sh" % ctx.label.name)

    ctx.actions.expand_template(
      template = amtool_info.template.files.to_list()[0],
      output = test,
      is_executable = True,
      substitutions = {
        "%tool_path%": str(amtool_info.tool.files_to_run.executable.short_path),
        "%action%": ctx.attr._action,
        "%srcs%": ctx.file.config.short_path,
      },
    )
    return [DefaultInfo(runfiles = runfiles, executable = test)]

amtool_config_test = rule(
    implementation = _amtool_config_test_impl,
    doc = """
Run "amtool check-config" on a configuration.

Example:
```
//examples:config_test

load("//prometheus:defs.bzl", "amtool_config_test")
amtool_config_test(
    name = "config_test",
    config = ":config.yaml",
)
```

```bash
bazel test //examples:config_test

//examples:config_test                                                PASSED in 0.1s
```

""",
    test = True,
    attrs = {
        "_action": attr.string(default = "check-config"),
        "config": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "The alertmanager config to test",
        ),
    },
    toolchains = ["@io_bazel_rules_prometheus//prometheus:toolchain"],
)

def _amtool_routes_test_impl(ctx):
    amtool_info = (
      ctx.toolchains["@io_bazel_rules_prometheus//prometheus:toolchain"]
      .prometheusToolchainInfo
      .amtool
    )

    runfiles = ctx.runfiles(
      files = ctx.files.config,
      transitive_files = amtool_info.tool.files,
    )

    test = ctx.actions.declare_file("%s.out.sh" % ctx.label.name)

    ctx.actions.expand_template(
      template = amtool_info.template.files.to_list()[0],
      output = test,
      is_executable = True,
      substitutions = {
        "%tool_path%": str(amtool_info.tool.files_to_run.executable.short_path),
        "%action%": ctx.attr._action + " --config.file=" + ctx.file.config.short_path + " --verify.receivers=\"" + " ".join(ctx.attr.receivers) + "\" --tree",
        "%srcs%": " ".join(ctx.attr.labels),
      },
    )
    return [DefaultInfo(runfiles = runfiles, executable = test)]

amtool_routes_test = rule(
    implementation = _amtool_routes_test_impl,
    doc = """
Run "amtool config routes test" on a configuration, using labels and expected receivers.

Example:
```
//examples:routes_test

load("//prometheus:defs.bzl", "amtool_rountes_test")
amtool_routes_test(
    name = "routes_test",
    config = ":config.yaml",
    labels = ["severity=page"],
    receivers = ["oncall-pager"],
)
```

```bash
bazel test //examples:routes_test

//examples:routes_test                                                PASSED in 0.1s
```

""",
    test = True,
    attrs = {
        "_action": attr.string(default = "config routes test"),
        "config": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "The alertmanager config to use for the test",
        ),
        "labels": attr.string_list(
            mandatory = True,
            doc = "The alert labels against which to test",
        ),
        "receivers": attr.string_list(
            mandatory = True,
            doc = "The expected receivers the provided labels should match to",
        ),
    },
    toolchains = ["@io_bazel_rules_prometheus//prometheus:toolchain"],
)

def amtool_routes_multi_test(name, config, labels_to_receivers):
    """Macro wrapping amtool_routes_test, allowing easy construction of tests asserting that alerts with a set of labels resolve to expected receiver(s).

    Example:

    ```
    amtool_routes_multi_test(
        name = "multi_test_amtool_routes",
        config = ":amconfig.yml",
        labels_to_receivers = {
            "severity=page": "oncall-pager",
            "severity=page scope=workday": "slack-alerts",
            "severity=catastrophe": "fires oncall-pager slack-alerts",
        }
    )
    ```

    Args:
      name: A unique name prefix for the tests generated.
      config: The alertmanager config against which to test.
      labels_to_receivers: A dictionary mapping a set of labels to the expected set of receivers. The key should be a string of label=value pairs, space separated. The value should be space-separated receiver names, in the expected resolution order.
    """
    for i, (labels, receivers) in enumerate(labels_to_receivers.items()):
        amtool_routes_test(
            name = "{}_{}".format(name, i),
            labels = labels.split(" "),
            receivers = receivers.split(" "),
            config = config,
        )
