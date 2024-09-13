#=
This file contains a range of helper functions called in the other .jl files as well as in the .ipynb notebooks.
=#

"""
    model_solution(model::JuMP.Model)

Returns solution parameters of an RCOT model after optimisation.

### Input

- model -- a JuMP model.

### Output

The TerminationStatusCode object, the ResultStatusCode of primal and dual, as well as the objective value of the optimisation model.

### Notes

This function is used to call the output of multiple JuMP-native functions to describe the output of an optimisation model.
"""
function model_solution(model)
    @show termination_status(model)
    @show primal_status(model)
    @show dual_status(model)
    @show objective_value(model)

end

"""
    show_dual_lhs(dual::JuMP.Model)

Returns the left-hand side values of a solved RCOT dual.

### Input

- `dual` -- a JuMP model.

### Output

The commodity prices, scarcity rents, and the left-hand side values of the no-profit condition.

### Notes

The input needs to be the RCOT dual, not the primal.
"""
function show_dual_lhs(dual)
    # Variable solution
    var_con = all_constraints(dual, VariableRef, MOI.GreaterThan{Float64})
    # Solved no-profit constraint
    profit_con = all_constraints(dual, AffExpr, MOI.LessThan{Float64})

    p_len = length(dual[:p])

    p = var_con[1:p_len]
    r = var_con[p_len+1:end]

    @show value.(p)
    @show value.(r)
    @show value.(profit_con)

end

"""
    show_primal_lhs(primal::JuMP.Model)

Returns the left-hand side values of a solved RCOT primal.

### Input

- `primal` -- a JuMP model.

### Output

The left-hand side values of the market balance and factor cosntraints.

### Notes

The input needs to be the RCOT primal, not the dual.
"""
function show_primal_lhs(primal)
    # Variable solution
    var_con = all_constraints(primal, VariableRef, MOI.GreaterThan{Float64})
    # Solved supply-demand constraint (if inequality)
    demand_con = all_constraints(primal, AffExpr, MOI.GreaterThan{Float64})
    # Solved suppy-demand constraint (if equality)
    demand_con_nosurp = all_constraints(primal, AffExpr, MOI.EqualTo{Float64})
    # Solved factor constraint
    factor_con = all_constraints(primal, AffExpr, MOI.LessThan{Float64})

    @show value.(var_con)
    !isempty(demand_con) && @show value.(demand_con)
    !isempty(demand_con_nosurp) && @show value.(demand_con_nosurp)
    @show value.(factor_con)

end

"""
    sensitivities(model::JuMP.Model; type::String)

Returns the sensitivity analysis of the constraints or variables of a solved RCOT model.

### Input

- `model` -- a JuMP model; either primal or dual.
- `type` -- either `constraint` or `variable`.

### Output

A dataframe detailing the sensitivities of the optimisation model in terms of its constraints or variables.

### Notes

This function is based on the documentation at:
https://jump.dev/JuMP.jl/stable/tutorials/linear/lp_sensitivity/#Sensitivity-analysis-of-a-linear-program
"""
function sensitivities(model; type::String)
    report = lp_sensitivity_report(model)
    if type == "constraint"
        return (
            DataFrames.DataFrame(
                (name = name(c),
                value = value(c),
                rhs = normalized_rhs(c),
                slack = normalized_rhs(c) - value(c),
                shadow_price = shadow_price(c),
                allowed_decrease = report[c][1],
                allowed_increase = report[c][2])
                for (F, S) in list_of_constraint_types(model) for
                    c in all_constraints(model, F, S) if F == AffExpr
            )
        )
    elseif type == "variable"
        return (
            DataFrames.DataFrame(
                (name = name(v),
                lower_bound = has_lower_bound(v) ? lower_bound(v) : -Inf,
                value = value(v),
                upper_bound = has_upper_bound(v) ? upper_bound(v) : Inf,
                reduced_cost = reduced_cost(v),
                obj_coefficient = coefficient(objective_function(model), v),
                allowed_decrease = report[v][1],
                allowed_increase = report[v][2])
                for v in all_variables(model)
            )
        )
    end     
end

"""
    allequal_multi(su_io; tuple_list::Vararg{Tuple})

Checks the sizes of the tuple elements provided. This is to check if the given matrices can be used to arrive at an inversion-based model.

### Input

- `su_io` -- a data structure containing various SUT or IOT matrices (::SUT.structure or ::Cosntructs.construct).
- `tuple_list` -- a list of tuples of strings where the strings are the names of chosen SUT matrices, e.g. ("V'", "U").

### Output

True or False.

### Notes

Checks the sizes of the tuple elements provided.
For example:

    allequal_multi(sut, ("V", "U"), ("F", "S"))
    ... checks if V and U as well  as F and S have the same dimensions
    ... returns "false" because V and U have different dimensions.

    allequal_multi(sut, ("V'", "U"), ("F", "S"))
    ... returns, however, "true".
"""
function allequal_multi(su_io, tuple_list::Vararg{Tuple})
    su_io_names = propertynames(su_io)
    name_len = length(su_io_names[1:end-1])
    su_io_dict = Dict(String(su_io_names[k]) => getfield(su_io, su_io_names[k]) for k =1:name_len)
    check_list = BitArray(undef,0)

    # iterate through list of tuples
    for i in eachindex(tuple_list)
        tup = tuple_list[i]
        tup_list = Vector[]

        # iterate through individual tuples
        for j in eachindex(tup)
            
            if contains.(tup[j],"'")
                tup_strip = replace(tup[j], "'" => "")
                dict_value = su_io_dict[tup_strip]
                (isnothing(dict_value)) && (dict_value = 0)
                size_element = size(dict_value')
            else
                dict_value = su_io_dict[tup[j]]
                (isnothing(dict_value)) && (dict_value = 0)
                size_element = size(dict_value)
            end
            push!(tup_list, [size_element])
        end        
        
        # check if sizes of elements of individual tuple are equal
        check = allequal(tup_list)
        push!(check_list, check)
    end

    # check if all size checks are successful
    if allequal(check_list) && false in check_list # no tuple matches
        return false
    elseif allequal(check_list) && true in check_list # each tuple works
        return true
    else
        return false # >1 tuple fails
    end
end