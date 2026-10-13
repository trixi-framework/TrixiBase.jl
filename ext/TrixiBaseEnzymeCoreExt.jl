module TrixiBaseEnzymeCoreExt

using EnzymeCore: EnzymeCore, Const
using EnzymeCore.EnzymeRules: EnzymeRules
using TimerOutputs: TimerOutput, TimerOutputs
using TrixiBase: TrixiBase, timeit_begin, timeit_end

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
# The states of the open reverse sections are kept on a stack, since the reverse of
# `timeit_begin` cannot access the tape of the reverse of `timeit_end`. Like `TimerOutput`s
# themselves, this is not thread-safe.
const REVERSE_STATES = Any[]

reverse_label(label) = string(label, " (reverse)")

function EnzymeRules.augmented_primal(config, ::Const{typeof(timeit_begin)},
                                      ::Type{<:Const}, to::Const, label::Const)
    state = timeit_begin(to.val, label.val)
    primal = EnzymeRules.needs_primal(config) ? state : nothing
    return EnzymeRules.AugmentedReturn(primal, nothing, nothing)
end

function EnzymeRules.reverse(config, ::Const{typeof(timeit_begin)}, ::Type{<:Const},
                             tape, to::Const, label::Const)
    timeit_end(to.val, reverse_label(label.val), pop!(REVERSE_STATES))
    return (nothing, nothing)
end

function EnzymeRules.augmented_primal(config, ::Const{typeof(timeit_end)},
                                      ::Type{<:Const}, to::Const, label::Const,
                                      state::Const)
    timeit_end(to.val, label.val, state.val)
    return EnzymeRules.AugmentedReturn(nothing, nothing, nothing)
end

function EnzymeRules.reverse(config, ::Const{typeof(timeit_end)}, ::Type{<:Const},
                             tape, to::Const, label::Const, state::Const)
    push!(REVERSE_STATES, timeit_begin(to.val, reverse_label(label.val)))
    return (nothing, nothing, nothing)
end

end # module
