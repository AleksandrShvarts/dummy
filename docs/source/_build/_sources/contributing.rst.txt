Contributing
============

This document describes how to contribute to QFlow core. You can also contribute to the wider QFlow ecosystem by creating new :ref:`plugins`.

General guidelines
------------------

* **main should always be releasable**. Incomplete features should live in branches. This ensures that any small bug fixes can be quickly released.
* **The ideal pull request** should bundle together the implementation, tests, and documentation updates. The commit message should link to an associated issue.

.. _devenvironment:
Setting up a development environment
------------------------------------
If you want to get started without creating your own fork, you can do this instead::

    git clone git@github.com:quantori/ml-pipelines

The next step is to create a virtual environment for your project and use it to install QFlow's dependencies::

    cd ml-pipelines
    # Install the package and all dependencies
    poetry install --all-extras
    # Install pre-commit hooks
    pre-commit install
