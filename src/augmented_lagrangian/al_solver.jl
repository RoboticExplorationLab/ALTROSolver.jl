
@doc raw""" ```julia
struct AugmentedLagrangianSolver <: ConstrainedSolver{T}
```
Augmented Lagrangian (AL) is a standard tool for constrained optimization. For a trajectory optimization problem of the form:
```math
\begin{aligned}
  \min_{x_{0:N},u_{0:N-1}} \quad & \ell_f(x_N) + \sum_{k=0}^{N-1} \ell_k(x_k, u_k, dt) \\
  \textrm{s.t.}            \quad & x_{k+1} = f(x_k, u_k), \\
                                 & g_k(x_k,u_k) \leq 0, \\
                                 & h_k(x_k,u_k) = 0.
\end{aligned}
```
AL methods form the following augmented Lagrangian function:
```math
\begin{aligned}
    \ell_f(x_N) + &λ_N^T c_N(x_N) + c_N(x_N)^T I_{\mu_N} c_N(x_N) \\
           & + \sum_{k=0}^{N-1} \ell_k(x_k,u_k,dt) + λ_k^T c_k(x_k,u_k) + c_k(x_k,u_k)^T I_{\mu_k} c_k(x_k,u_k)
\end{aligned}
```
This function is then minimized with respect to the primal variables using any unconstrained minimization solver (e.g. iLQR).
    After a local minima is found, the AL method updates the Lagrange multipliers λ and the penalty terms μ and repeats the unconstrained minimization.
    AL methods have superlinear convergence as long as the penalty term μ is updated each iteration.
"""
struct AugmentedLagrangianSolver{T,S<:AbstractSolver} <: ConstrainedSolver{T}
    opts::SolverOptions{T}
    stats::SolverStats{T}
    solver_uncon::S
end


"""$(TYPEDSIGNATURES)
Form an augmented Lagrangian cost function from a Problem and AugmentedLagrangianSolver.
    Does not allocate new memory for the internal arrays, but points to the arrays in the solver.
"""
function AugmentedLagrangianSolver(
        prob::Problem{T}, 
        opts::SolverOptions=SolverOptions(), 
        stats::SolverStats=SolverStats(parent=solvername(AugmentedLagrangianSolver));
        solver_uncon=iLQRSolverOldOld,
        kwarg_opts...
    ) where {T}
    set_options!(opts; kwarg_opts...)

    # Build Augmented Lagrangian Objective
    alobj = ALObjectiveOld(prob)
    prob_al = Problem(prob.model, alobj, ConstraintList(dims(prob)...),
        prob.x0, prob.xf, prob.Z, prob.N, prob.t0, prob.tf)

    # Instantiate the unconstrained solver
    solver_uncon = solver_uncon(prob_al, opts, stats)
    rollout!(solver_uncon)

    # Build solver
    solver = AugmentedLagrangianSolver(opts, stats, solver_uncon)
    reset!(solver)
    # set_options!(solver; opts...)
    return solver
end

# Getters
RD.dims(solver::AugmentedLagrangianSolver) = RD.dims(solver.solver_uncon)
import Base.size
@deprecate size(solver::AugmentedLagrangianSolver) dims(solver)
@inline TO.cost(solver::AugmentedLagrangianSolver) = TO.cost(solver.solver_uncon)
@inline TO.get_trajectory(solver::AugmentedLagrangianSolver) = get_trajectory(solver.solver_uncon)
@inline TO.get_objective(solver::AugmentedLagrangianSolver) = get_objective(solver.solver_uncon)
@inline TO.get_model(solver::AugmentedLagrangianSolver) = get_model(solver.solver_uncon)
@inline get_initial_state(solver::AugmentedLagrangianSolver) = get_initial_state(solver.solver_uncon)
solvername(::Type{<:AugmentedLagrangianSolver}) = :AugmentedLagrangian
get_ilqr(solver::AugmentedLagrangianSolver) = solver.solver_uncon

function TO.get_constraints(solver::AugmentedLagrangianSolver{T}) where T
    obj = get_objective(solver)::ALObjectiveOld{T}
    obj.constraints
end

# Options methods
function set_verbosity!(solver::AugmentedLagrangianSolver)
    llevel = log_level(solver) 
    if is_verbose(solver)
        set_logger()
        Logging.disable_logging(LogLevel(llevel.level-1))
        logger = global_logger()
        if is_verbose(solver.solver_uncon) 
            freq = 1
        else
            freq = 5
        end
        logger.leveldata[llevel].freq = freq
    else
        Logging.disable_logging(llevel)
    end
end


function reset!(solver::AugmentedLagrangianSolver)
    reset_solver!(solver)
    reset!(solver.solver_uncon)
end
