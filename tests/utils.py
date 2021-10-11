import os
from contextlib import contextmanager
from pathlib import Path

import pkg_resources
import yaml

import circuit_build

TEST_DIR = Path(__file__).resolve().parent
TEST_DATA_DIR = TEST_DIR / "proj66-tiny"
TEST_DATA_DIR_SYNTH = TEST_DIR / "proj66-tiny-synth"
SNAKEFILE = pkg_resources.resource_filename(circuit_build.__name__, "snakemake/Snakefile")
SNAKEMAKE_ARGS = ["--bioname", str(TEST_DATA_DIR), "-u", str(TEST_DATA_DIR / "cluster.yaml")]


@contextmanager
def cwd(path):
    """Context manager to temporarily change the working directory."""
    original_cwd = os.getcwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(original_cwd)


@contextmanager
def edit_yaml(yaml_file):
    """Context manager within which you can edit a yaml file.

    Args:
        yaml_file (Path): path to a yaml file

    Returns:
        Yields a dict instance of `yaml_file`. This instance will be saved later on the context
            manager leave.
    """
    with yaml_file.open("r") as f:
        config = yaml.safe_load(f)
    try:
        yield config
    finally:
        with yaml_file.open("w") as f:
            yaml.safe_dump(config, f)
