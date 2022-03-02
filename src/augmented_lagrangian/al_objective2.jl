struct ALObjective{T,O<:AbstractObjective} <: TO.AbstractObjective
    obj::O
    conset::ALConstraintSet{T}
    alcost::Vector{T}
    function ALObjective{T}(obj::AbstractObjective) where T
        new{T,typeof(obj)}(obj, ALConstraintSet{T}(), zeros(T, length(obj)))
    end
end

function TO.cost(alobj::ALObjective, Z::SampledTrajectory)
    # Calculate unconstrained cost
    J = TO.cost(alobj.obj, Z)

    # Calculate constraints
    # TODO: update trajectory if Z is not the cached one
    evaluate_constraints!(alobj.conset, Z)

    # Calculate AL penalty
    alobj.alcost .= 0
    alcost(alobj.conset)    
    J += sum(alobj.alcost)

    return J
end

function cost_expansion!(alobj::ALObjective, E::CostExpansion, Z)
    # Calculate expansion of original cost
    cost_expansion!(alobj.obj, E, Z)

    # Calculate constraint Jacobians
    constraint_jacobians!(alobj.conset, Z)

    # Calculate expansion of AL penalty
    algrad!(alobj.conset)
    alhess!(alobj.conset)

    # Add to existing expansion
    # each ALConstraint has local alias to ilqr.Efull
    # this is a hack to avoid an allocation for each constraint
    # due to type instability
    @assert E === alobj.conset.Eref[]
    add_alcost_expansion!(alobj.conset, E)

    return nothing
end
