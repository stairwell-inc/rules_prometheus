load(
    "@io_bazel_rules_prometheus//prometheus/internal:repositories.bzl",
    _prometheus_repositories = "prometheus_repositories",
)
load(
    "@io_bazel_rules_prometheus//prometheus/internal:amtool.bzl",
    _amtool = "amtool",
    _amtool_config_test = "amtool_config_test",
)
load(
    "@io_bazel_rules_prometheus//prometheus/internal:promtool.bzl",
    _promtool = "promtool",
    _promtool_config_test = "promtool_config_test",
    _promtool_rules_test = "promtool_rules_test",
    _promtool_unit_test = "promtool_unit_test",
)
load(
    "@io_bazel_rules_prometheus//prometheus/internal:prom.bzl",
    _prometheus = "prometheus",
)
load(
    "@io_bazel_rules_prometheus//prometheus/internal:toolchain.bzl",
    _prometheus_toolchains = "prometheus_toolchains",
)

amtool = _amtool
amtool_config_test = _amtool_config_test
prometheus_toolchains = _prometheus_toolchains
prometheus_repositories = _prometheus_repositories
promtool_unit_test = _promtool_unit_test
promtool_config_test = _promtool_config_test
promtool = _promtool
promtool_rules_test = _promtool_rules_test
prometheus = _prometheus
