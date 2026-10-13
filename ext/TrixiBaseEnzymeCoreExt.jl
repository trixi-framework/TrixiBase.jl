module TrixiBaseEnzymeCoreExt

using EnzymeCore: EnzymeCore, Annotation, Const, Duplicated, BatchDuplicated
using EnzymeCore.EnzymeRules: EnzymeRules
using TimerOutputs: TimerOutput, TimerOutputs
using TrixiBase: TrixiBase, TimeitState, timeit_begin, timeit_end

# Timers are never differentiated
EnzymeRules.inactive_type(::Type{<:TimerOutput}) = true
EnzymeRules.inactive_type(::Type{<:TimerOutputs.Section}) = true

# `@trixi_timeit` under reverse-mode AD with Enzyme.jl:
# - The augmented forward pass is timed in the section `label`, like the primal code.
# - The reverse pass is timed in the section "`label` (reverse)". The reverse pass runs
#   `timeit_end` before `timeit_begin`, so the reverse of `timeit_end` opens the section
#   and the reverse of `timeit_begin` closes it. Since sections are closed in the reverse
#   order of opening, the reverse sections nest like the forward ones.
#
# Enzyme.jl duplicates the `TimeitState` (see its field `shadow_marker`). The augmented
# forward pass of `timeit_begin` makes the shadow and puts it into its tape. The reverse of
# `timeit_end` gets the same shadow as `state.dval` and writes the state of the reverse
# section into it. Then the reverse of `timeit_begin` reads the shadow from its tape.
# The shadow never holds differentiable data.
#
# Enzyme.jl decides the activity, so the rules also accept a `Const` state.
# Then the reverse pass is not timed.

reverse_label(label) = string(label, " (reverse)")

# Copy the state `src` into the shadow `dst`
function copy_state!(dst::TimeitState, src::TimeitState)
    dst.enabled = src.enabled
    dst.accumulated_data = src.accumulated_data
    dst.gc0 = src.gc0
    dst.b0 = src.b0
    dst.t0 = src.t0
    return dst
end

# The first shadow. In batch mode, all shadows are the same object.
first_shadow(state::Duplicated) = state.dval
first_shadow(state::BatchDuplicated) = first(state.dval)
first_shadow(state) = nothing

function EnzymeRules.augmented_primal(config, ::Const{typeof(timeit_begin)},
                                      RT::Type{<:Annotation}, to::Const, label::Const)
    state = timeit_begin(to.val, label.val)
    primal = EnzymeRules.needs_primal(config) ? state : nothing
    if !EnzymeRules.needs_shadow(config)
        return EnzymeRules.AugmentedReturn(primal, nothing, nothing)
    end
    shadow = copy_state!(TimeitState(state.enabled, state.accumulated_data, state.gc0,
                                     state.b0, state.t0, 0.0), state)
    width = EnzymeRules.width(config)
    shadows = width == 1 ? shadow : ntuple(Returns(shadow), Val(width))
    return EnzymeRules.AugmentedReturn(primal, shadows, shadow)
end

function EnzymeRules.reverse(config, ::Const{typeof(timeit_begin)}, RT::Type{<:Annotation},
                             shadow, to::Const, label::Const)
    if shadow !== nothing
        timeit_end(to.val, reverse_label(label.val), shadow)
    end
    return (nothing, nothing)
end

function EnzymeRules.augmented_primal(config, ::Const{typeof(timeit_end)},
                                      ::Type{<:Const}, to::Const, label::Const,
                                      state::Annotation{<:TimeitState})
    timeit_end(to.val, label.val, state.val)
    return EnzymeRules.AugmentedReturn(nothing, nothing, nothing)
end

function EnzymeRules.reverse(config, ::Const{typeof(timeit_end)}, ::Type{<:Const},
                             tape, to::Const, label::Const,
                             state::Annotation{<:TimeitState})
    shadow = first_shadow(state)
    if shadow !== nothing
        copy_state!(shadow, timeit_begin(to.val, reverse_label(label.val)))
    end
    return (nothing, nothing, nothing)
end

end # module
