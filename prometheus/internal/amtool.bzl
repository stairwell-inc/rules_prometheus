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
