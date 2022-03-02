"""
    Problems
        Collection of trajectory optimization problems
"""
module Problems

using Altro
using TrajectoryOptimization  # import the API
using LinearAlgebra
using StaticArrays
using RobotZoo
using RobotDynamics
using Rotations
const Dynamics = RobotDynamics
const TO = TrajectoryOptimization

include("../problems/doubleintegrator.jl")
include("../problems/pendulum.jl")
include("../problems/acrobot.jl")
include("../problems/parallel_park.jl")
include("../problems/cartpole.jl")
include("../problems/dubins_car.jl")
include("../problems/bicycle.jl")
include("../problems/quadrotor.jl")
include("../problems/airplane.jl")

export
    doubleintegrator,
    pendulum,
    parallel_park,
    cartpole,
    doublependulum,
    acrobot,
    car_escape,
    car_3obs,
    quadrotor,
    quadrotor_maze,
    kuka_obstacles

export
    plot_escape,
    plot_car_3obj,
    quadrotor_maze_objects,
    kuka_obstacles_objects

end
