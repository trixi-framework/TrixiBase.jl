module TrixiBasePolyesterExt

using TrixiBase: TrixiBase, PolyesterBackend
using Polyester: Polyester

# Use `Polyester.@batch`
@inline function TrixiBase.parallel_foreach(f::F, iterator, ::PolyesterBackend) where {F}
    Polyester.@batch for i in iterator
        @inline f(i)
    end
end

end # module TrixiBasePolyesterExt
