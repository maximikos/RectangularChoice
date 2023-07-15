[_metadata_:author]:- "Maximilian Koslowski"
[_metadata_:affiliation]:- "NTNU, Norway"
[_metadata_:contact]:- "maximilian.koslowski at ntnu.no"
[_metadata_:date]:- "2023-07-14 23:55:28"

# Rectangular choice
This project contains code and spreadsheet files to illustrate the models shown in the research manuscript entitled "From single to joint production under rectangular technology choice" submitted for review at the journal [*Economic Systems Research*](https://www.tandfonline.com/journals/cesr20).

In that article, we start from the rectangular-choice-of-technology (RCOT) model described by [Duchin & Levine (2011)](https://doi.org/10.1080/09535314.2011.571238), a linear programming model used for scenario analysis within the field of input-output (IO) analysis. That model is based on square IO tables, some elements of which can then be augmented along their column dimension to allow for the choice among multiple alternative technologies to produce a homogeneous output.

We have identified potential caveats concerning the units and shape of the underlying data as well as the method of reallocating secondary products when converting supply-use tables (SUTs) into IO tables. Based on these insights, we argue to opt for a model generalisation, SU-RCOT, that is not (or only to a limited degree) subject to the described limitations of the original IO-RCOT model. Essentially, we move thus from a model artifically based on pseudo-single production to a model that covers joint production.

While most of the arguments made in the manuscript are comprehensible by simply examining the formulas in the main text and PDF appendix, we want to illustrate the use of the generalised RCOT model here.


## Structure
This project uses the [Julia](https://julialang.org/) programming language in combination with the Julia-based algebraic modelling language [JuMP](https://jump.dev/JuMP.jl/stable/). The documentation for Julia's latest release is available [here](https://docs.julialang.org/en/v1/).

The directory tree of the project is as follows:

```bash
RectangularChoice/
│   Manifest.toml
│   Project.toml
│   README.md
│
├───.vscode
│       settings.json
│
├───data
│       SUT_c+i-.xlsx
│       SUT_c-i+.xlsx
│       SUT_c=i.xlsx
│
├───notebooks
│       SU-RCOT_c+i-.ipynb
│       SU_RCOT_c+i-.html
│       SU-RCOT_c-i+.ipynb
│       SU_RCOT_c-i+.html
│       SU-RCOT_c=i.ipynb
│       SU_RCOT_c=i.html
│
└───src
        Auxiliary.jl
        Constructs.jl
        RCOT_data.jl
        RCOT_model.jl
        RectangularChoice.jl
        SUT_structure.jl
```

Specifically, this project contains:
- this ``README.md`` file.
- the ``Manifest.toml`` and ``Project.toml`` files included for reproducibility (see below). For background see [here](https://pkgdocs.julialang.org/v1/toml-files/).
- an empty ``settings.json`` file, created by default.
- in ``data``, Excel files containing illustrative data that are imported into the three Jupyter notebooks.
- in ``notebooks``, Jupyter notebooks that explore the three cases of commodity-industry (c-i) dimensions, i.e. when [c>i](./notebooks/SU-RCOT_c+i-.ipynb), [c<i](./notebooks/SU-RCOT_c-i+.ipynb), and [c=i](./notebooks/SU-RCOT_c=i.ipynb). (These Jupyter notebooks have also been included in html format for accessibility - if the reader/user has no Jupyter environment.)
- in ``src``, Julia code files that are called from within the Jupyter notebooks. Specifically:
    - ``SUT_structure.jl`` organises the SUT data imported into the Jupyter notebooks.
    - ``Constructs.jl`` uses these SUT structures and converts them through reallocation of secondary products into structures based on single production.
    - ``RCOT_data.jl`` is the data structure to be used for RCOT modelling; it is based on the above structures and can be modified.
    - ``RCOT_model.jl`` a wrapper for the RCOT models that solves them.
    - ``Auxiliary.jl`` contains helper functions.
    - ``RectangularChoice.jl``, a legacy file from when creating the project.

To explore the model, start with the [c>i](./notebooks/SU-RCOT_c+i-.ipynb) notebook, as this is the most detailed one. The two other notebooks are kept shorter while still highlighting basic properties of the model.

Please note that the anonymised version of the repository may not display all text correctly (e.g. cutting off lines). In that case, downloading the material directly allows to view and interact with it appropriately.

## Reproducibility
While the included Jupyter notebooks in html format already show the output, one may easily reproduce this output and/ or modify the files. This can be done in various settings. At time of writing, a convenient choice is to install Julia, VS Code, and the respective Julia extension as per [here](https://www.julia-vscode.org/docs/dev/gettingstarted/); moreover, the [Jupyter extension](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter) for VS Code must be installed. As described in ``Manifest.toml``, Julia version 1.9.0 was used in this project.

Following this basic setup, make this environment locally available as described [here](https://pkgdocs.julialang.org/v1/environments/#Using-someone-else's-project). A restart of VS Code may then be required. Then, when in the project directory, select the environment and select the new Julia kernel (like [here](https://code.visualstudio.com/docs/datascience/jupyter-kernel-management), provided that the Julia kernel installation succeeded) and execute the notebook of choice.

> **_NOTE:_** If the Julia kernel installation does not succeed and/or if required packages are not installed automatically, please add manually the relevant packages (listed in ``Project.toml``) as described [here](https://pkgdocs.julialang.org/v1/managing-packages/#Adding-registered-packages). If the kernel can still not be found, try to run ``IJulia.installkernel("RectangularChoice", "--project=$(Base.active_project())")`` in the active project ``RectangularChoice`` in the REPL (as described [here](https://julialang.github.io/IJulia.jl/stable/manual/usage/#Julia-projects)). 

Note that if the SUT data in the Excel files is modified, e.g. to include more commodities, adjustments in the Jupyter notebooks are necessary as additional technologies are added manually *within* these notebooks. If these additional technologies are not modified accordingly, a dimension mismatch will disrupt the code execution.


---

*by* Maximilian Koslowski (with Edgar Hertwich and Richard Wood)\
2023-07-15