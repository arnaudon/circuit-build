#!/usr/bin/env python

import imp
from setuptools import setup, find_packages

with open('README.rst', encoding='utf-8') as f:
    README = f.read()
VERSION = imp.load_source("", "circuit_build/version.py").__version__

setup(
    name="circuit-build",
    author="bbp-ou-nse",
    author_email="bbp-ou-nse@groupes.epfl.ch",
    version=VERSION,
    long_description=README,
    long_description_content_type="text/x-rst",
    description="Tool for building circuits",
    url="https://bbpteam.epfl.ch/documentation/projects/Circuit%20Building/latest/index.html",
    project_urls={
        "Tracker": "https://bbpteam.epfl.ch/project/issues/projects/NSETM/issues",
        "Source": "ssh://bbpcode.epfl.ch/common/circuit-build",
    },
    entry_points={
        'console_scripts': ['circuit-build=circuit_build.cli:cli']},
    license="BBP-internal-confidential",
    # see `basepython` in tox.ini for explanation on the version.
    python_requires='>=3.7',
    install_requires=[
        'click>=7.0',
        'snakemake>=5.10.0,<6.0.0',
    ],
    packages=find_packages(),
    include_package_data=True,
    package_data={
        'circuit_build': ['circuit_build/snakemake/**/*'],
    },
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.6',
    ],
)