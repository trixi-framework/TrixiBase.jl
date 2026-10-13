module TrixiBaseEnzymeCoreExt

using EnzymeCore: EnzymeCore, Const
using EnzymeCore.EnzymeRules: EnzymeRules
using TimerOutputs: TimerOutput, TimerOutputs
using TrixiBase: TrixiBase, TimeitState, timeit_begin, timeit_end

# Timers are never differentiated
EnzymeRules.inactive_type(::Type{<:TimerOutput}) = true
EnzymeRules.inactive_type(::Type{<:TimerOutputs.Section}) = true
EnzymeRules.inactive_type(::Type{<:TimeitState}) = true

# `@trixi_timeit` under reverse-mode AD with Enzyme.jl:
# - The augmented forward pass is timed in the section `label`, like the primal code.
# - The reverse pass is timed in the section "`label` (reverse)". The reverse pass runs
#   `timeit_end` before `timeit_begin`, so the reverse of `timeit_end` opens the section
#   and the reverse of `timeit_begin` closes it. Since sections are closed in the reverse
#   order of opening, the reverse sections nest like the forward ones.
#
# The augmented forward pass of `timeit_begin` puts a new box into the field `reverse` of
# the state and into its tape. `timeit_end` gets this state as an argument and puts the box
# into its tape. Thus, both reverse rules get the same box from their tapes: the reverse of
# `timeit_end` puts the state of the reverse section into the box, and the reverse of
# `timeit_begin` takes it from the box.

reverse_label(label) = string(label, " (reverse)")

function EnzymeRules.augmented_primal(config, ::Const{typeof(timeit_begin)},
                                      ::Type{<:Const}, to::Const, label::Const)
    state = timeit_begin(to.val, label.val)
    box = Ref{Any}()
    state = TimeitState(state.enabled, state.accumulated_data, state.gc0, state.b0,
                        state.t0, box)
    primal = EnzymeRules.needs_primal(config) ? state : nothing
    return EnzymeRules.AugmentedReturn(primal, nothing, box)
end

function EnzymeRules.reverse(config, ::Const{typeof(timeit_begin)}, ::Type{<:Const},
                             box, to::Const, label::Const)
    timeit_end(to.val, reverse_label(label.val), box[])
    return (nothing, nothing)
end

function EnzymeRules.augmented_primal(config, ::Const{typeof(timeit_end)},
                                      ::Type{<:Const}, to::Const, label::Const,
                                      state::Const)
    timeit_end(to.val, label.val, state.val)
    return EnzymeRules.AugmentedReturn(nothing, nothing, state.val.reverse)
end

function EnzymeRules.reverse(config, ::Const{typeof(timeit_end)}, ::Type{<:Const},
                             box, to::Const, label::Const, state::Const)
    box[] = timeit_begin(to.val, reverse_label(label.val))
    return (nothing, nothing, nothing)
end

end # module
