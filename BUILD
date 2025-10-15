load("@io_bazel_rules_prometheus//prometheus:defs.bzl", "prometheus", "promtool", "amtool")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ["//visibility:public"])

exports_files(["deps.bzl"])

amtool(
    name = "amtool",
)

promtool(
    name = "promtool",
)

prometheus(
    name = "prom",
)

bzl_library(
    name = "deps",
    srcs = ["deps.bzl"],
)
