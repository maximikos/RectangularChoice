#=
Solves the IO/SU RCOT model. GLPK is used as solver.

<type> defines if the primal or dual should be solved explicitly.
<format> denotes if absolute or relative RCOT formulation is to be used.
<data> denotes the data to be used; either the SUT or from a construct.
<surplus> defines for SU-RCOT if a commodity surplus may exist or not; only to be used in primal.

---

# usage as for example:

include("RCOT_model.jl")

### run the primal IO-RCOT model in its absolute form using the data contained in <io_rcot_data>
io_rcot_model = io_rcot("primal", "abs", io_rcot_data)

### show the mathematical model
latex_formulation(io_rcot_model)

### show a solution summary of the solved model
solution_summary(io_rcot_model)

...

=#

using LinearAlgebra

using ..SUT # from SUT_structure.jl
using ..Constructs # from Constructs.jl
using ..RCOT_data # from RCOT_data.jl
# and calls functions from Auxiliary.jl

function su_rcot(type::String, format::String, data::SUT.structure; surplus::Bool=true)
    # Define the optimisation model
    model = Model(GLPK.Optimizer)

    if type == "primal" && format == "abs"
        try
            @variable(model, z_star[1:size(data.V,1)] >= 0, base_name = "z*")
            @objective(model, Min, sum(data.pii'*data.F*z_star))
            if surplus
                @constraint(model, c1, (data.V'-data.U)*(z_star) .>= data.e)
            else
                @constraint(model, c1, (data.V'-data.U)*(z_star) .== data.e)
            end
            @constraint(model, c2, data.F*z_star .<= data.f)
            optimize!(model)
            model_solution(model)
            show_primal_lhs(model)
        catch
            rethrow()
        end

    elseif type == "primal" && format == "rel"
        try
           @variable(model, g_star[1:size(data.C,2)] >= 0, base_name = "g*")
            @objective(model, Min, sum(data.pii'*data.S*g_star))
            if surplus
                @constraint(model, c1, (data.C-data.B)*(g_star) .>= data.e)
            else
                @constraint(model, c1, (data.C-data.B)*(g_star) .== data.e)
            end
            @constraint(model, c2, data.S*g_star .<= data.f)
            optimize!(model)
            model_solution(model)
            show_primal_lhs(model)
        catch e
            println("The relative primal SU-RCOT can only be applied to monetary data. Make also sure that no other error persists")
        end
    
    elseif type == "dual" && format == "abs"
        try
            @variable(model, p[1:size(data.V,2)] >= 0)
            @variable(model, r[1:size(data.F,1)] >= 0)
            @objective(model, Max, sum(p'*data.e - r'*data.f))
            @constraint(model, c1d, (data.V'-data.U)'*(p) - data.F'*r .<= data.F'*data.pii)
            optimize!(model)
            model_solution(model)
            show_dual_lhs(model)
        catch
            rethrow()
        end
    
    elseif type == "dual" && format == "rel"
        try
            @variable(model, p[1:size(data.C,1)] >= 0)
            @variable(model, r[1:size(data.S,1)] >= 0)
            @objective(model, Max, sum(p'*data.e - r'*data.f))
            @constraint(model, c1d, (data.C-data.B)'*(p) - data.S'*r .<= data.S'*data.pii)
            optimize!(model)
            model_solution(model)
            show_dual_lhs(model)
        catch e
            println("The relative primal SU-RCOT can only be applied to monetary data. Make also sure that no other error persists.")
        end
    end

    return model
end


function io_rcot(type::String, format::String, data::Constructs.construct)
    # Define the optimisation model
    model = Model(GLPK.Optimizer)

    try
        if type == "primal" && format == "abs"
            @variable(model, s_star[1:size(data.Z,2)] >= 0, base_name = "s*")
            @objective(model, Min, sum(data.pii'*data.G*s_star))
            @constraint(model, c1, (data.xhat-data.Z)*(s_star) .>= data.y)
            @constraint(model, c2, data.G*s_star .<= data.f)
            optimize!(model)
            model_solution(model)
            show_primal_lhs(model)

        elseif type == "primal" && format == "rel"
            @variable(model, x_star[1:size(data.A,2)] >= 0, base_name = "x*")
            @objective(model, Min, sum(data.pii'*data.R*x_star))
            @constraint(model, c1, (data.I_mod-data.A)*(x_star) .>= data.y)
            @constraint(model, c2, data.R*x_star .<= data.f)
            optimize!(model)
            model_solution(model)
            show_primal_lhs(model)
        
        elseif type == "dual" && format == "abs"
            @variable(model, p[1:size(data.Z,2)] >= 0)
            @variable(model, r[1:size(data.G,1)] >= 0)
            @objective(model, Max, sum(p'*data.y - r'*data.f))
            @constraint(model, c1d, (data.xhat-data.Z)'*(p) - data.G'*r .<= data.G'*data.pii)
            optimize!(model)
            model_solution(model)
            show_dual_lhs(model)
        
        elseif type == "dual" && format == "rel"
            @variable(model, p[1:size(data.A,2)] >= 0)
            @variable(model, r[1:size(data.R,1)] >= 0)
            @objective(model, Max, sum(p'*data.y - r'*data.f))
            @constraint(model, c1d, (data.I_mod-data.A)'*(p) - data.R'*r .<= data.R'*data.pii)
            optimize!(model)
            model_solution(model)
            show_dual_lhs(model)
        end

        return model

    catch e
        println("Ensure that the right model and construct were chosen, given the dimensions and units of the underlying data.")
    end

end