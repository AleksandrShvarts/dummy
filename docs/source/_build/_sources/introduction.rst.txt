============
Introduction
============

QFlow is a tool for managing machine learning (ML) development.

QFLow is meant to be used in all stages of the project "maturity"; however, it is not meant
to manage models in production and it offers very little help in data discovery phase.

Requirements
============

QFlow works with Linux and OSX (It should also work on Windows, however, it is not yet guaranteed) and it
requires Python 3.8 and above.

Managing QFlow Project
========================

Creating Project
------------------------

QFlow allows creating projects using CLI tool:

.. code-block:: bash

    qflow new

This will create an empty project with QFlow structure. Next you may create a workflow.

.. code-block:: bash

    # you need to be inside the project to create the workflow
    cd example_project
    qflow workflow new --workflow-name example_workflow

Writing Workflows
------------------------

Artifacts
^^^^^^^^^^

The main QFlow concept is an artifact: artifacts are the object transformed and created within ML workflows.
For example, we may consider the following class describing a vector.

.. code-block:: python
    :linenos:
    :caption: workflows/example_workflow/workflow.py

    @dataclass
    class Vector:
        data: list[float]

In order to track and pass artifacts between machines used to run the workflow, we need to introduce the notion of a
factory. Factory is a class implementing ``qflow.core.protocols.ArtifactFactory`` protocol; it needs to support ``save``
and ``load`` operations. For example, we may create the following factory for the vector class we described above.

.. code-block:: python
    :lineno-start: 5
    :caption: workflows/example_workflow/workflow.py

    class VectorFactory:
        def load(self, path: ptyping.AnyPath) -> Vector:
            with path.open("r") as f:
                return Vector(list(map(int, f.read().split("\n")))

        def save(
            self,
            artifact: Vector,
            path: ptyping.AnyPath,
        ) -> Vector:
            with path.open("w") as f:
                f.write("\n".join(map(str, artifact.data)))

.. note::

    The best practice for naming factories is to concatenate the name of the artifact and the word `Factory`.

To tell the framework that you want to us a factory for a specific class, you may use ``add_factory`` decorator.

.. code-block:: python
    :lineno-start: 4
    :emphasize-lines: 1
    :caption: workflows/example_workflow/workflow.py

    @registry.add_factory
    class VectorFactory:
        def load(self, path: ptyping.AnyPath) -> Vector:
            with path.open("r") as f:
                return Vector(list(map(int, f.read().split("\n")))

        def save(
            self,
            artifact: Vector,
            path: ptyping.AnyPath,
        ) -> Vector:
            with path.open("w") as f:
                f.write("\n".join(map(str, artifact.data)))


Steps
^^^^^^^^^^

Workflow consists of steps manipulating the artifacts; each step is essentially a pure function (i.e., it must be
deterministic and it shouldn't have side-effects). The step logic needs to be defined inside of the ``apply`` function.
For example, the following step adds up two vectors.

.. code-block:: python
    :lineno-start: 17
    :caption: workflows/example_workflow/workflow.py

    @qflow.step
    class Add:
        def apply(self, left: Vector, right: Vector) -> Vector:
            return Vector(
                list(map(lambda p: p[0] + p[1], zip(left.data, right.data)))
            )


.. warning::
    We use type annotations to determine which factory to use with the result of a step. Hence, you cannot
    use ``from __future__ import annotations`` in the file defining the step.

Some steps may have several parameters, for example, the following step compute linear combination of vectors.

.. code-block:: python
    :lineno-start: 23
    :caption: workflows/example_workflow/workflow.py

    @qflow.step
    class LinearCombination:
        coef_0: float
        coef_1: float

        def apply(self, left: Vector, right: Vector) -> Vector:
            return Vector(
                list(map(
                    lambda p: self.coef_0 * p[0] + self.coef_1 * p[1],
                    zip(left.data, right.data),
                ))
            )

Note that you can define parameters as you would normally do in dataclasses.

.. note::
    Although it looks like declaration of dataclasses fields we actually create a ``pydantic.BaseModel`` behind the scenes.
    So if your class requires configuration treat it as ``pydantic.BaseModel``, preferably explicitly.

Workflows
^^^^^^^^^^

To define a workflow one needs to create a class and decorate it using ``qflow.workflow``.

.. code-block:: python
    :lineno-start: 39
    :emphasize-lines: 1,2
    :caption: workflows/example_workflow/workflow.py

    @qflow.workflow
    class ExampleWorkflow:
        coef_0: float
        coef_1: float

        def run(
            self,
            a: Vector = factory_load("a.txt"),
            b: Vector = factory_load("b.txt"),
            c: Vector = factory_load("c.txt"),
        ):
            return LinearCombination(self.coef_0, self.coef_1).apply(
                Add().apply(a, b),
                c,
            )

.. note::
    Similar to steps workflow itself is also a ``pydantic.BaseModel``, so you may configure it in a similar fashion.


Workflow's logic needs to be defined in the ``run`` function. However, the workflow is the topmost
piece of structure; hence, it needs to specify the way to obtain inputs.
For example, if a workflow has the following ``run`` function, then it loads three vectors from files
``a.txt``, ``b.txt``, and ``c.txt``, respectively and perform computation on them.

.. code-block:: python
    :lineno-start: 39
    :emphasize-lines: 8-10
    :caption: workflows/example_workflow/workflow.py

    @qflow.workflow
    class ExampleWorkflow:
        coef_0: float
        coef_1: float

        def run(
            self,
            a: Vector = factory_load("a.txt"),
            b: Vector = factory_load("b.txt"),
            c: Vector = factory_load("c.txt"),
        ):
            return LinearCombination(self.coef_0, self.coef_1).apply(
                Add().apply(a, b),
                c,
            )

Finally, similarly to steps, workflows may have parameters.

.. code-block:: python
    :lineno-start: 39
    :emphasize-lines: 3,4
    :caption: workflows/example_workflow/workflow.py

    @qflow.workflow
    class ExampleWorkflow:
        coef_0: float
        coef_1: float

        def run(
            self,
            a: Vector = factory_load("a.txt"),
            b: Vector = factory_load("b.txt"),
            c: Vector = factory_load("c.txt"),
        ):
            return LinearCombination(self.coef_0, self.coef_1).apply(
                Add().apply(a, b),
                c,
            )


Executing workflows
------------------------

When workflow is written, one may run or visualise it using ``qflow`` CLI.

.. code-block:: bash

    # to visualise the workflow using Mermaid syntax
    qflow visualise --workflow-name example_workflow

    # to run the workflow
    qflow run --workflow-name example_workflow


Additionally you may want to render report about your run with some information that could be useful when comparing the runs on CI.

.. code-block:: bash

    qflow run --workflow-name example_workflow --report logs

This will generate a Markdown report file ``logs/report.md`` along with some images and metrics generated during the run.

Execute workflows from GitHub PR and issues
------------------------

We encourage use of GitFlow-like process for ML projects.
For incremental workflow improvements checks you may use pre-defined action to execute workflows directly form GitHub.

Use ``> LAUNCH: <workflow(s) to run split using ','>`` trigger word in PR description or issue comments in PRs to execute specified workflows.

Example:

.. code-block:: text

    This PR increases random forrest depth parameter to learn more complex relationships
    > LAUNCH: random-forrest-workflow

This will trigger a CI job to execute workflow with parameters modified by current PR.

Export essential run information and metrics through report
------------------------

In order to make most of reports generated on CI and be able to compare runs efficiently you should export useful run information from workflows.
Consider the following example:

.. code-block:: python

    @qflow.workflow
    class GradientBoostingClassifier:
        max_depth: int
        n_estimators: int
        learning_rate: float

        def run(
            self,
            train_data: Data = providers.factory_load("train_point_cloud"),
            train_labels: Labels = providers.factory_load("resources/train_labels"),
            test_data: Data = providers.factory_load("resources/test_point_cloud"),
        ) -> Generator[qflow.RuntimeInfo, None, Labels]:
            model = yield from qflow.label_info(
                FitGradientBoosting(
                    n_estimators=self.n_trees,
                    max_depth=self.max_depth,
                    learning_rate=self.learning_rate,
                ),
                train_loss="loss",
                train_accuracy="accuracy",
            ).apply(train_data, train_labels)

            return Predict().apply(model, test_data)

Here we make use of runtime information provided by the ``FitGradientBoosting`` step, it exports both loss and accuracy over training iterations.
We might use this information to compare different runs as these metrics would be re-exported from run as ``train_loss`` and ``train_accuracy``.
Moreover if exported runtime information is a series than we will be able to display line plot with values changing over time.
