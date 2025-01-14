rule ngv:
    input:
        "ngv_config.json",
        ctx.nodes_neurons_file,
        ctx.edges_neurons_neurons_file(connectome_type="functional"),
        ctx.nodes_astrocytes_file,
        ctx.nodes_vasculature_file,
        ctx.nodes_astrocytes_microdomains_file,
        ctx.edges_neurons_astrocytes_file,
        ctx.edges_astrocytes_vasculature_file,
        ctx.edges_astrocytes_vasculature_endfeet_meshes_file,
        ctx.edges_astrocytes_astrocytes_file,
        ctx.nodes_astrocytes_morphologies_dir,
        ctx.refined_tetrahedral_mesh_file,


rule ngv_config:
    output:
        "ngv_config.json",
    log:
        ctx.log_path("ngv_config"),
    run:
        with write_with_log(output[0], log[0]) as out:
            ctx.write_network_ngv_config(out)


rule build_sonata_vasculature:
    input:
        ctx.conf.get(["ngv", "common", "vasculature"]),
    output:
        ctx.nodes_vasculature_file,
    log:
        ctx.log_path("build_sonata_vasculature"),
    shell:
        ctx.bbp_env(
            "ngv",
            [
                "vascpy morphology-to-sonata",
                "{input} {output}",
            ],
        )


rule place_glia:
    input:
        ctx.nodes_vasculature_file,
    output:
        ctx.paths.auxiliary_path("astrocytes.somata.h5"),
    log:
        ctx.log_path("place_glia"),
    shell:
        ctx.bbp_env(
            "ngv",
            [
                "ngv cell-placement",
                f"--config {ctx.paths.bioname_path('MANIFEST.yaml')}",
                f"--atlas {ctx.conf.get(['ngv', 'common', 'atlas'])}",
                "--atlas-cache .atlas",
                "--vasculature {input}",
                f"--population-name {ctx.nodes_astrocytes_name}",
                "--output {output}",
                f"--seed {ctx.conf.get(['ngv', 'common', 'seed'])}",
            ],
        )


rule assign_glia_emodels:
    input:
        ctx.paths.auxiliary_path("astrocytes.somata.h5"),
    output:
        ctx.paths.auxiliary_path("astrocytes.emodels.h5"),
    log:
        ctx.log_path("assign_glia_emodels"),
    shell:
        ctx.bbp_env(
            "ngv",
            [
                "ngv assign-emodels",
                "--input {input}",
                "--output {output}",
                f"--hoc {ctx.conf.get(['ngv', 'assign_emodels', 'hoc_template'])}",
            ],
        )


rule finalize_glia:
    input:
        somata=ctx.paths.auxiliary_path("astrocytes.somata.h5"),
        emodels=ctx.paths.auxiliary_path("astrocytes.emodels.h5"),
    output:
        ctx.nodes_astrocytes_file,
    log:
        ctx.log_path("finalize_glia"),
    shell:
        ctx.bbp_env(
            "ngv",
            [
                "ngv finalize-astrocytes",
                "--somata-file {input[somata]}",
                "--emodels-file {input[emodels]}",
                "--output {output}",
            ],
        )


rule build_glia_microdomains:
    input:
        ctx.nodes_astrocytes_file,
    output:
        ctx.nodes_astrocytes_microdomains_file,
    log:
        ctx.log_path("build_glia_microdomains"),
    shell:
        ctx.bbp_env(
            "ngv",
            [
                "ngv microdomains",
                f"--config {ctx.paths.bioname_path('MANIFEST.yaml')}",
                "--astrocytes {input}",
                f"--atlas {ctx.conf.get(['ngv', 'common', 'atlas'])}",
                "--atlas-cache .atlas",
                "--output-file-path {output}",
                f"--seed {ctx.conf.get(['ngv', 'common', 'seed'])}",
            ],
        )


rule build_gliovascular_connectivity:
    input:
        astrocytes=ctx.nodes_astrocytes_file,
        microdomains=ctx.nodes_astrocytes_microdomains_file,
        vasculature=ctx.nodes_vasculature_file,
    output:
        ctx.paths.auxiliary_path("gliovascular.connectivity.h5"),
    log:
        ctx.log_path("gliovascular_connectivity"),
    shell:
        ctx.bbp_env(
            "ngv",
            [
                "ngv gliovascular-connectivity",
                f'--config {ctx.paths.bioname_path("MANIFEST.yaml")}',
                "--astrocytes {input[astrocytes]}",
                "--microdomains {input[microdomains]}",
                "--vasculature {input[vasculature]}",
                f"--seed {ctx.conf.get(['ngv', 'common', 'seed'])}",
                f"--population-name {ctx.edges_astrocytes_vasculature_name}",
                "--output {output}",
            ],
        )


rule build_neuroglial_connectivity:
    input:
        astrocytes=ctx.nodes_astrocytes_file,
        microdomains=ctx.nodes_astrocytes_microdomains_file,
        neurons=ctx.nodes_neurons_file,
        neuronal_synapses=ctx.edges_neurons_neurons_file("functional"),
        spatial_synapse_index_dir=ctx.edges_spatial_index_dir,
    output:
        ctx.paths.auxiliary_path("neuroglial.connectivity.h5"),
    log:
        ctx.log_path("neuroglial_connectivity"),
    shell:
        ctx.bbp_env(
            "ngv",
            [
                "ngv neuroglial-connectivity",
                "--neurons-path {input[neurons]}",
                "--spatial-synapse-index-dir {input[spatial_synapse_index_dir]}",
                "--astrocytes-path {input[astrocytes]}",
                "--microdomains-path {input[microdomains]}",
                "--neuronal-connectivity-path {input[neuronal_synapses]}",
                "--population-name {ctx.edges_neurons_astrocytes_name}",
                "--output-path {output}",
                f"--seed {ctx.conf.get(['ngv', 'common', 'seed'])}",
            ],
        )


rule build_endfeet_surface_meshes:
    input:
        ctx.paths.auxiliary_path("gliovascular.connectivity.h5"),
    output:
        ctx.edges_astrocytes_vasculature_endfeet_meshes_file,
    log:
        ctx.log_path("endfeet_area"),
    shell:
        ctx.bbp_env(
            "ngv",
            [
                "ngv endfeet-area",
                f"--config-path {ctx.paths.bioname_path('MANIFEST.yaml')}",
                f"--vasculature-mesh-path {ctx.conf.get(['ngv', 'common', 'vasculature_mesh'])}",
                "--gliovascular-connectivity-path {input}",
                "--output-path {output}",
                f"--seed {ctx.conf.get(['ngv', 'common', 'seed'])}",
            ],
        )


rule synthesize_glia:
    input:
        astrocytes=ctx.nodes_astrocytes_file,
        microdomains=ctx.nodes_astrocytes_microdomains_file,
        gliovascular_connectivity=ctx.paths.auxiliary_path("gliovascular.connectivity.h5"),
        neuroglial_connectivity=ctx.paths.auxiliary_path("neuroglial.connectivity.h5"),
        endfeet_meshes=ctx.edges_astrocytes_vasculature_endfeet_meshes_file,
        neuronal_synapses=ctx.edges_neurons_neurons_file("functional"),
    output:
        morphologies_dir=directory(ctx.nodes_astrocytes_morphologies_dir),
    log:
        ctx.log_path("synthesis"),
    shell:
        ctx.bbp_env(
            "synthesize-glia",
            [
                f"ngv -v synthesis",
                f'--config-path {ctx.paths.bioname_path("MANIFEST.yaml")}',
                f'--tns-distributions-path {ctx.paths.bioname_path("tns_distributions.json")}',
                f'--tns-parameters-path {ctx.paths.bioname_path("tns_parameters.json")}',
                f'--tns-context-path {ctx.paths.bioname_path("tns_context.json")}',
                f'--er-data-path {ctx.paths.bioname_path("er_data.json")}',
                "--astrocytes-path {input[astrocytes]}",
                "--microdomains-path {input[microdomains]}",
                "--gliovascular-connectivity-path {input[gliovascular_connectivity]}",
                "--neuroglial-connectivity-path {input[neuroglial_connectivity]}",
                "--endfeet-meshes-path {input[endfeet_meshes]}",
                "--out-morph-dir {output[morphologies_dir]}",
                "--neuronal-connectivity-path {input[neuronal_synapses]}",
                ("--parallel" if ctx.conf.get(["ngv", "common", "parallel"]) else ""),
                f"--seed {ctx.conf.get(['ngv', 'common', 'seed'])}",
            ],
            slurm_env="synthesize_glia",
        )


rule finalize_gliovascular_connectivity:
    input:
        astrocytes=ctx.nodes_astrocytes_file,
        connectivity=ctx.paths.auxiliary_path("gliovascular.connectivity.h5"),
        endfeet_meshes=ctx.edges_astrocytes_vasculature_endfeet_meshes_file,
        morphologies_dir=ctx.nodes_astrocytes_morphologies_dir,
        vasculature_sonata=ctx.nodes_vasculature_file,
    output:
        ctx.edges_astrocytes_vasculature_file,
    log:
        ctx.log_path("finalize_gliovascular_connectivity"),
    shell:
        ctx.bbp_env(
            "ngv",
            [
                "ngv attach-endfeet-info-to-gliovascular-connectivity",
                "--input-file {input[connectivity]}",
                "--output-file {output}",
                "--astrocytes {input[astrocytes]}",
                "--endfeet-meshes-path {input[endfeet_meshes]}",
                "--vasculature-sonata {input[vasculature_sonata]}",
                "--morph-dir {input[morphologies_dir]}",
                ("--parallel" if ctx.conf.get(["ngv", "common", "parallel"]) else ""),
                f"--seed {ctx.conf.get(['ngv', 'common', 'seed'])}",
            ],
        )


rule finalize_neuroglial_connectivity:
    input:
        astrocytes=ctx.nodes_astrocytes_file,
        microdomains=ctx.nodes_astrocytes_microdomains_file,
        connectivity=ctx.paths.auxiliary_path("neuroglial.connectivity.h5"),
        morphologies_dir=ctx.nodes_astrocytes_morphologies_dir,
        neuronal_synapses=ctx.edges_neurons_neurons_file("functional"),
    output:
        ctx.edges_neurons_astrocytes_file,
    log:
        ctx.log_path("finalize_neuroglial_connectivity"),
    shell:
        ctx.bbp_env(
            "ngv",
            [
                "ngv attach-morphology-info-to-neuroglial-connectivity",
                "--input-file-path {input[connectivity]}",
                "--output-file-path {output}",
                "--astrocytes-path {input[astrocytes]}",
                "--microdomains-path {input[microdomains]}",
                "--morph-dir {input[morphologies_dir]}",
                "--synaptic-data-path {input[neuronal_synapses]}",
                ("--parallel" if ctx.conf.get(["ngv", "common", "parallel"]) else ""),
                f"--seed {ctx.conf.get(['ngv', 'common', 'seed'])}",
            ],
        )


rule glial_gap_junctions:
    input:
        astrocytes=ctx.nodes_astrocytes_file,
        morphologies_dir=ctx.nodes_astrocytes_morphologies_dir,
        circuit_config="ngv_config.json",
    output:
        touches_dir=directory(ctx.tmp_edges_astrocytes_glialglial_touches_dir),
    log:
        ctx.log_path("glial_gap_junctions"),
    shell:
        ctx.bbp_env(
            "ngv-touchdetector",
            [
                "touchdetector",
                "--modern",
                "--circuit-config {input.circuit_config}",
                "--output {output[touches_dir]}",
                f"--from {ctx.nodes_astrocytes_name}",
                f"--to {ctx.nodes_astrocytes_name}",
                "--recipe",
                ctx.paths.bioname_path("astrocyte_gap_junction_recipe.xml"),
            ],
            slurm_env="ngv-touchdetector",
        )


rule glialglial_connectivity:
    input:
        astrocytes=ctx.nodes_astrocytes_file,
        touches_dir=ctx.tmp_edges_astrocytes_glialglial_touches_dir,
    output:
        glialglial_connectivity=ctx.edges_astrocytes_astrocytes_file,
    log:
        ctx.log_path("glialglial_connectivity"),
    shell:
        ctx.bbp_env(
            "ngv-pytouchreader",
            [
                "ngv glialglial-connectivity",
                "--astrocytes {input[astrocytes]}",
                "--population-name {ctx.edges_astrocytes_astrocytes_name}",
                "--touches-dir {input[touches_dir]}",
                f"--population-name {ctx.edges_astrocytes_astrocytes_name}",
                "--output-connectivity {output[glialglial_connectivity]}",
                f"--seed {ctx.conf.get(['ngv', 'common', 'seed'])}",
            ],
        )


rule prepare_tetrahedral:
    # generates a mesh file and a gmsh script for the next step
    output:
        mesh=ctx.prepared_tetrahedral_mesh_file,
        script=ctx.tetrahedral_gmsh_script_file,
    log:
        ctx.log_path("prepare_tetrahedral"),
    shell:
        ctx.bbp_env(
            "ngv-prepare-tetrahedral",
            [
                f"ngv refined-surface-mesh",
                f"--config-path {ctx.paths.bioname_path('MANIFEST.yaml')}",
                f"--atlas {ctx.conf.get(['ngv', 'common', 'atlas'])}",
                "--atlas-cache .atlas",
                "--output-path {output.mesh}",
            ],
        )


rule build_tetrahedral:
    input:
        mesh_file=ctx.prepared_tetrahedral_mesh_file,
        script_file=ctx.tetrahedral_gmsh_script_file,
    output:
        ctx.tetrahedral_mesh_file,
    log:
        ctx.log_path("build_tetrahedral"),
    shell:
        ctx.bbp_env(
            "ngv-build-tetrahedral",
            [
                "gmsh",
                "{input.script_file}",  # input.mesh_file is already set in the input.script_file
                "-3",  #  Perform mesh generation from 2d (surface) to 3d (tetrahedral).
                "-o {output}",
                "-algo initial3d",
            ],
        )


rule refine_tetrahedral:
    # this loop refines the provided tetrahedral mesh by subdividing its edges,
    # i.e. at every iteration every edge is split in two sub-edges
    input:
        ctx.tetrahedral_mesh_file,
    output:
        ctx.refined_tetrahedral_mesh_file,
    log:
        ctx.log_path("refine_tetrahedral"),
    shell:
        ctx.bbp_env(
            "ngv-refine-tetrahedral",
            [
                (
                    "cp -v {input} tmp.msh && "
                    f"for (( c=1; c<={ctx.refinement_subdividing_steps}; c++ )); "
                    "do gmsh -refine tmp.msh -o tmp.msh; done && "
                    "mv -v tmp.msh {output}"
                )
            ],
        )
