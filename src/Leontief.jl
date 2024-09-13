"""
A module for running an impact or imputation analysis based on the Leontief-calculus, either as a price or quantity model. Mind that here potentially more production factors are considered than is typical in IO. That is, any production factor with a non-zero factor price is considered as integral part of the IOT, not just as a satellite matrix.

Depending on if the underlying data was modified, either an impact or imputation analysis is performed.

The function leontief() initialises the Leontief models. The actual Leontief quantity and price models are realised as separate functions below. The "leontief-object" is then exported.
"""
module Leontief

    using LinearAlgebra
    using ..SUT # from SUT_structure.jl
    using ..Constructs # from Constructs.jl    
    using ..Model_data # from Model_data.jl
    # and calls functions from Auxiliary.jl
    include("../src/Auxiliary.jl")

    export leontief

    mutable struct leontief
        # Creates an undefined struct

        net_out::Matrix{Float64} # Net output matrix
        net_out_inv::Matrix{Float64} # Net output inverse
        output::Matrix{Float64} # Total output
        output_disagg::Matrix{Float64} # Total output disaggregated by demand
        factor_use::Matrix{Float64} # Total factor use
        factor_use_disagg_by_out::Matrix{Float64} # Total factor use disaggregated by output
        factor_use_disagg_by_demand::Matrix{Float64} # Total factor use disaggregated by demand
        priced_factors::Matrix{Float64} # Total priced factors
        priced_factors_disagg::Matrix{Float64} # Priced factors disaggregated by factor type
        com_price::Matrix{Float64} # Commodity prices
        com_price_disagg_by_factors::Matrix{Float64} # Commodity prices disaggregated by factor
        com_price_disagg_by_sectors::Matrix{Float64} # Commodity prices disaggregated by sector

        isActive

        function leontief()
            this = new()
            @info "You are about to perform an inversion-based imputation or impact analysis. Keep in mind that input variables are treated independently, thus potentially resulting in different results for a model in absolute or relative form."
            return this
        end
    end

    """
        quantity(sut::SUT.structure, format::String)

    Solves the unconstrained Leontief quantity model in absolute or relative <format> using <sut> data.

    ### Input

    - `sut` -- the SUT data to be used.
    - `format` -- denotes if absolute ("abs") or relative ("rel") formulation is to be used.

    ### Output

    Returns the Leontief quantity model object with its respective variables: net-output ("net_out"), its inverse ("net_out_inv"), total output ("output"), and factor use ("factor_use"). The latter two are also provided in disaggregated form.

    ### Example
    include("Leontief.jl")

    # to calculate the total output using the SUT data <sut> via the Leontief calculus in coefficient form.

    su_model_data = Model_data.SU(sut)
    leo_su_rel = Leontief.quantity(su_model_data, "rel")
    leo_su_rel.output
    """
    function quantity(sut::SUT.structure, format::String)
        if allequal_multi(sut, ("V'", "U"), ("C", "B")) == false
            @error "The SUT-system is rectangular and cannot be inverted!"
        elseif format == "abs"

            try
            
            # Initialise the leontief model
            leo = leontief()

            # Calculate the elements of the quantity model
            leo.net_out = sut.V'-sut.U
            leo.net_out_inv = inv(leo.net_out)
            leo.output = leo.net_out_inv*sut.e
            leo.output_disagg = leo.net_out_inv*Diagonal(vec(sut.e))
            leo.factor_use = sut.F*leo.output
            leo.factor_use_disagg_by_out = sut.F*Diagonal(vec(leo.output))
            leo.factor_use_disagg_by_demand = sut.F*leo.output_disagg

            return leo
                
            catch e
                rethrow()
            end
        elseif format == "rel"
            
            try
            # Initialise the leontief model
            leo = leontief()

            # Calculate elements of the quantity model
            leo.net_out = sut.C-sut.B
            leo.net_out_inv = inv(leo.net_out)
            leo.output = inv(leo.net_out_rel)*sut.e
            leo.output_disagg = leo.net_out_inv*Diagonal(vec(sut.e))
            leo.factor_use = sut.S*leo.output
            leo.factor_use_disagg_by_out = sut.S*Diagonal(vec(leo.output))
            leo.factor_use_disagg_by_demand = sut.S*leo.output_disagg

            return leo

            catch e
                @error("The relative SUT-based Leontief calculus can only be applied to monetary data. Make also sure that no other error persists.")
            end
        end
    end

    """
        price(sut::SUT.structure, format::String)

    Solves the unconstrained Leontief price model in absolute or relative <format> using <sut> data.

    ### Input

    - `sut` -- the SUT data to be used.
    - `format` -- denotes if absolute ("abs") or relative ("rel") formulation is to be used.

    ### Output

    Returns the Leontief price model object with its respective variables: net-output ("net_out"), priced factors ("priced_factors"), and commodity prices ("com_price"). The latter variable is also provided in disaggregated form.

    ### Example
    include("Leontief.jl")

    # to calculate the commodity prices (values) disaggregated by sector using the SUT data in absolute form (starting off from SUT data <sut>)

    su_model_data = Model_data.SU(sut)
    leo_sut_abs = Leontief.price(su_model_data, "abs")
    leo_sut_abs.com_price_disagg_by_sectors
    """
    function price(sut::SUT.structure, format::String)
        #=
        Calculates the unconstrained price model in absolute or relative <format> using <sut> data
        =#

        if allequal_multi(sut, ("V'", "U"), ("C", "B")) == false
            @error "The SUT-system is rectangular and cannot be inverted!"
        elseif format == "abs"

            # Initialise the leontief model
            leo = leontief()

            # Calculate elements of the quantity model
            leo.net_out = sut.V'-sut.U
            leo.priced_factors = sut.F'*sut.pii
            leo.priced_factors_disagg = sut.F'*Diagonal(vec(sut.pii))
            leo.com_price = inv(leo.net_out')*leo.priced_factors
            leo.com_price_disagg_by_factors = inv(leo.net_out')*leo.priced_factors_disagg
            leo.com_price_disagg_by_sectors = inv(leo.net_out')*Diagonal(vec(leo.priced_factors))

            return leo
        elseif format == "rel"
            
            try
            # Initialise the leontief model
            leo = leontief()

            # Calculate the elements of the quantity model
            leo.net_out = sut.C-sut.B
            leo.priced_factors = sut.S'*sut.pii
            leo.priced_factors_disagg = sut.S'*Diagonal(vec(sut.pii))
            leo.com_price = inv(leo.net_out')*leo.priced_factors
            leo.com_price_disagg_by_factors = inv(leo.net_out')*leo.priced_factors_disagg
            leo.com_price_disagg_by_sectors = inv(leo.net_out')*Diagonal(vec(leo.priced_factors))

            return leo

            catch e
                @error("The relative SUT-based Leontief calculus can only be applied to monetary data. Make also sure that no other error persists.")
            end
        end
    end

    """
        quantity(con::Constructs.construct, format::String)

    Solves the unconstrained Leontief quantity model in absolute or relative <format> using <con> data (i.e. an IOT derived from an SUT via constructs).

    ### Input

    - `con` -- the IOT data to be used.
    - `format` -- denotes if absolute ("abs") or relative ("rel") formulation is to be used.

    ### Output

    Returns the Leontief quantity model object with its respective variables: net-output ("net_out"), its inverse ("net_out_inv"), total output ("output"), and factor use ("factor_use"). The latter two are also provided in disaggregated form.

    ### Example
    include("Leontief.jl")

    # to calculate the total output using the CTC via the Leontief calculus in coefficient form (starting off from given SUT data <sut>).

    ctc = Constructs.CTC(sut)
    io_model_data = Model_data.IO(ctc)
    leo_ctc_rel = Leontief.quantity(io_model_data, "rel")
    leo_ctc_rel.output
    """
    function quantity(con::Constructs.construct, format::String)
        #=
        Calculates the unconstrained quantity model in absolute or relative <format> using <construct> data
        =#

        if allequal_multi(con, ("xhat", "Z"), ("I_mod", "A")) == false
            @error "The IOT-system is rectangular and cannot be inverted!"
        elseif format == "abs"

            # Initialise the leontief model
            leo = leontief()

            # Calculate the elements of the quantity model
            leo.net_out = con.xhat-con.Z
            leo.net_out_inv = inv(leo.net_out)
            leo.output = leo.net_out_inv*con.y
            leo.output_disagg = leo.net_out_inv*Diagonal(vec(con.y))
            leo.factor_use = con.G*leo.output
            leo.factor_use_disagg_by_out = con.G*Diagonal(vec(leo.output))
            leo.factor_use_disagg_by_demand = con.G*leo.output_disagg

            return leo

        elseif format == "rel"
            
            # Initialise the leontief model
            leo = leontief()

            # Calculate elements of the quantity model
            leo.net_out = con.I_mod-con.A
            leo.net_out_inv = inv(leo.net_out)
            leo.output = inv(leo.net_out)*con.y
            leo.output_disagg = leo.net_out_inv*Diagonal(vec(con.y))
            leo.factor_use = con.R*leo.output
            leo.factor_use_disagg_by_out = con.R*Diagonal(vec(leo.output))
            leo.factor_use_disagg_by_demand = con.R*leo.output_disagg

            return leo

        end
    end

    """
        price(con::Constructs.construct, format::String)

    Solves the unconstrained Leontief price model in absolute or relative <format> using <con> data (i.e. an IOT derived from an SUT via constructs).

    ### Input

    - `con` -- the IOT data to be used.
    - `format` -- denotes if absolute ("abs") or relative ("rel") formulation is to be used.

    ### Output

    Returns the Leontief price model object with its respective variables: net-output ("net_out"), priced factors ("priced_factors"), and commodity prices ("com_price"). The latter variable is also provided in disaggregated form.

    ### Example
    include("Leontief.jl")

    # to calculate the commodity prices (values) disaggregated by sector using the CTC-based IOT data in absolute form (starting off from CTC data <ctc>)

    ctc_model_data = Model_data.IO(ctc)
    leo_ctc_abs = Leontief.price(ctc_model_data, "abs")
    leo_ctc_abs.com_price_disagg_by_sectors
    """
    function price(con::Constructs.construct, format::String)
        #=
        Calculates the unconstrained quantity model in absolute or relative <format> using <construct> data
        =#

        if allequal_multi(con, ("xhat", "Z"), ("I_mod", "A")) == false
            @error "The IOT-system is rectangular and cannot be inverted!"
        elseif format == "abs"
            # Initialise the leontief model
            leo = leontief()

            # Calculate elements of the quantity model
            leo.net_out = con.xhat-con.Z
            leo.priced_factors = con.G'*con.pii
            leo.priced_factors_disagg = con.G'*Diagonal(vec(con.pii))
            leo.com_price = inv(leo.net_out')*leo.priced_factors
            leo.com_price_disagg_by_factors = inv(leo.net_out')*leo.priced_factors_disagg
            leo.com_price_disagg_by_sectors = inv(leo.net_out')*Diagonal(vec(leo.priced_factors))

            return leo
        elseif format == "rel"
            
            # Initialise the leontief model
            leo = leontief()

            # Calculate the elements of the quantity model
            leo.net_out = con.I_mod-con.A
            leo.priced_factors = con.R'*con.pii
            leo.priced_factors_disagg = con.R'*Diagonal(vec(con.pii))
            leo.com_price = inv(leo.net_out')*leo.priced_factors
            leo.com_price_disagg_by_factors = inv(leo.net_out')*leo.priced_factors_disagg
            leo.com_price_disagg_by_sectors = inv(leo.net_out')*Diagonal(vec(leo.priced_factors))

            return leo
        end
    end
end