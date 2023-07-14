#=
macro Name(arg)
    return string(:($arg))
end

macro name(x)
    quote
        ($(esc(x)), $(string(x)))
    end
end

macro name2(name)
    return println(name)
end
=#

function model_solution(model)

    @show termination_status(model)
    @show primal_status(model)
    @show dual_status(model)
    @show objective_value(model)

end

function show_dual_lhs(dual)
# Show the LHS values of a solved primal
    var_con = all_constraints(dual, VariableRef, MOI.GreaterThan{Float64})
    profit_con = all_constraints(dual, AffExpr, MOI.LessThan{Float64})

    p_len = length(dual[:p])

    p = var_con[1:p_len]
    r = var_con[p_len+1:end]

    @show value.(p)
    @show value.(r)
    @show value.(profit_con)

end

function show_primal_lhs(primal)
# Show the LHS values of a solved primal
    var_con = all_constraints(primal, VariableRef, MOI.GreaterThan{Float64})
    demand_con = all_constraints(primal, AffExpr, MOI.GreaterThan{Float64})
    demand_con_nosurp = all_constraints(primal, AffExpr, MOI.EqualTo{Float64})
    factor_con = all_constraints(primal, AffExpr, MOI.LessThan{Float64})

    @show value.(var_con)
    !isempty(demand_con) && @show value.(demand_con)
    !isempty(demand_con_nosurp) && @show value.(demand_con_nosurp)
    @show value.(factor_con)

end

function sensitivities(model_name; type::String)
    #=
    This function is based on the documentation at:
    https://jump.dev/JuMP.jl/stable/tutorials/linear/lp_sensitivity/#Sensitivity-analysis-of-a-linear-program
    
    Use e.g. as:
    sensitivities(primal,type="constraint")
    =#
    report = lp_sensitivity_report(model_name)
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
                for (F, S) in list_of_constraint_types(model_name) for
                    c in all_constraints(model_name, F, S) if F == AffExpr
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
                obj_coefficient = coefficient(objective_function(model_name), v),
                allowed_decrease = report[v][1],
                allowed_increase = report[v][2])
                for v in all_variables(model_name)
            )
        )
    end     
end

function allequal_multi(su_io, tuple_list::Vararg{Tuple})
    #=
    Checks the sizes of the tuple elements provided.
    For example:

    allequal_multi(sut, ("V", "U"), ("F", "S"))
    ... checks if V and U as well  as F and S have the same dimensions
    ... returns "false" because the make and use matrices have different dimensions.

    allequal_multi(sut, ("V'", "U"), ("F", "S"))
    ... returns, however, "true".

    =#

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
                size_element = size(dict_value')
            else
                dict_value = su_io_dict[tup[j]]
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