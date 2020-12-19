def _promtool_impl(ctx):
    promtool_info = ctx.toolchains["@io_bazel_rules_prometheus//prometheus/internal:toolchain_type"].prometheusToolchainInfo.promtool
    promtool_unit_test_runner_template = ctx.file._template
    exec = ctx.actions.declare_file("%s.out.sh" % ctx.label.name)

    runfiles = ctx.runfiles(
        files = ctx.files._template,
        transitive_files = promtool_info.tool.files,
    )
    ctx.actions.expand_template(
        template = promtool_unit_test_runner_template,
        output = exec,
        is_executable = True,
        substitutions = {
            "%tool_path%": "%s" % promtool_info.tool.files_to_run.executable.short_path,
        },
    )
    return [DefaultInfo(runfiles = runfiles, executable = exec)]

_promtool = rule(
    implementation = _promtool_impl,
    attrs = {
        "_template": attr.label(
            default = Label("@io_bazel_rules_prometheus//prometheus/internal:promtool.manual_runner.sh.tpl"),
            allow_single_file = True,
        ),
    },
    executable = True,
    toolchains = ["@io_bazel_rules_prometheus//prometheus/internal:toolchain_type"],
)

def promtool(name, **kwargs):
    """emit runnable sh_binary rule that is preconfigured to be able to run within the local workspace directory"""
    runner = name + "-runner"
    _promtool(
        name = runner,
        tags = ["manual"],
        **kwargs
    )
    native.sh_binary(
        name = name,
        srcs = [runner],
        tags = ["manual"],
    )

def _promtool_unit_test_impl(ctx):
    """promtool_unit_test implementation: we spawn test runner task from template and provide required tools and actions from toolchain"""

    # To ensure the files needed by the script are available, we put them in
    # the runfiles.
    promtool_info = ctx.toolchains["@io_bazel_rules_prometheus//prometheus/internal:toolchain_type"].prometheusToolchainInfo.promtool
    promtool_unit_test_runner_template = promtool_info.template.files.to_list()[0]

    runfiles = ctx.runfiles(
        files = ctx.files.srcs + ctx.files.rules,
        transitive_files = promtool_info.tool.files,
    )

    test = ctx.actions.declare_file("%s.out.sh" % ctx.label.name)

    ctx.actions.expand_template(
        template = promtool_unit_test_runner_template,
        output = test,
        is_executable = True,
        substitutions = {
            "%srcs%": " ".join([_file.short_path for _file in ctx.files.srcs]),
            "%tool_path%": "%s" % promtool_info.tool.files_to_run.executable.short_path,
            "%action%": ctx.attr._action,
        },
    )
    return [DefaultInfo(runfiles = runfiles, executable = test)]

promtool_unit_test = rule(
    implementation = _promtool_unit_test_impl,
    test = True,
    attrs = {
        "_action": attr.string(default = "test rules"),
        "srcs": attr.label_list(mandatory = True, allow_files = True, cfg = "target"),
        "rules": attr.label_list(mandatory = True, allow_files = True),
    },
    toolchains = ["@io_bazel_rules_prometheus//prometheus/internal:toolchain_type"],
)

def _promtool_config_test_impl(ctx):
    """promtool_unit_test implementation: we spawn executor task from template and provide required tools"""

    # To ensure the files needed by the script are available, we put them in
    # the runfiles.

    promtool_info = ctx.toolchains["@io_bazel_rules_prometheus//prometheus/internal:toolchain_type"].prometheusToolchainInfo.promtool
    promtool_unit_test_runner_template = promtool_info.template.files.to_list()[0]

    runfiles = ctx.runfiles(
        files = ctx.files.srcs,
        transitive_files = promtool_info.tool.files,
    )

    test = ctx.actions.declare_file("%s.out.sh" % ctx.label.name)

    ctx.actions.expand_template(
        template = promtool_unit_test_runner_template,
        output = test,
        is_executable = True,
        substitutions = {
            "%srcs%": " ".join([_file.short_path for _file in ctx.files.srcs]),
            "%tool_path%": "%s" % promtool_info.tool.files_to_run.executable.short_path,
            "%action%": ctx.attr._action,
        },
    )
    return [DefaultInfo(runfiles = runfiles, executable = test)]

promtool_config_test = rule(
    implementation = _promtool_config_test_impl,
    test = True,
    attrs = {
        "_action": attr.string(default = "check config"),
        "srcs": attr.label_list(mandatory = True, allow_files = True),
    },
    toolchains = ["@io_bazel_rules_prometheus//prometheus/internal:toolchain_type"],
)

def _promtool_rules_test_impl(ctx):
    pass

promtool_rules_test = rule(
    implementation = _promtool_config_test_impl,
    test = True,
    attrs = {
        "_action": attr.string(default = "check rules"),
        "srcs": attr.label_list(mandatory = True, allow_files = True),
    },
    toolchains = ["@io_bazel_rules_prometheus//prometheus/internal:toolchain_type"],
)
