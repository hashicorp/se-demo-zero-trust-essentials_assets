# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

from setuptools import setup

setup(
    name='explainer',
    packages=['app'],
    include_package_data=True,
    install_requires=[
        'flask',
    ],
)

