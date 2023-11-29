module ThreadedDenseSparseMul

import SparseArrays
import SparseArrays: SparseMatrixCSC, SparseVector, nonzeroinds, nonzeros, findnz
import Polyester: @batch

export fastdensesparsemul!, fastdensesparsemul_threaded!
export fastdensesparsemul_outer!, fastdensesparsemul_outer_threaded!

const VecOrView{T} = Union{Vector{T}, SubArray{T, 1, Matrix{T}}}
const MatOrView{T} = Union{Matrix{T}, SubArray{T, 2, Matrix{T}}}

"""
    fastdensesparsemul!(C, A, B, α, β)

BLAS like interface, computing `C .= β*C + α*A*B`, but way faster than Base would.

Also see `fastdensesparsemul_threaded!` for a multi-threaded version using `Polyester.jl`.
"""
function fastdensesparsemul!(C::MatOrView{T}, A::MatOrView{T}, B::SparseMatrixCSC{T}, α::Number, β::Number) where T
    for j in axes(B, 2)
        C[:, j] .*= β
        C[:, j] .+= A * (α.*B[:, j])
    end
    return C
end

"""
    fastdensesparsemul!(C, A, B, α, β)

Threaded, BLAS like interface, computing `C .= β*C + α*A*B`, but way faster than Base would.
Also see `fastdensesparsemul!` for a single-threaded version.
"""
function fastdensesparsemul_threaded!(C::MatOrView{T}, A::MatOrView{T}, B::SparseMatrixCSC{T}, α::Number, β::Number) where T
    @batch for j in axes(B, 2)
        C[:, j] .*= β
        C[:, j] .+= A * (α.*B[:, j])
    end
    return C
end

"""
    fastdensesparsemul_outer!(C, a, b, α, β)

Fast outer product when computing `C .= β*C + α * a*b'`, but way faster than Base would.
- `a` is a dense vector (or view), `b` is a sparse vector, `C` is a dense matrix (or view).
Also see `fastdensesparsemul_outer_threaded!` for a multi-threaded version using `Polyester.jl`.
"""
function fastdensesparsemul_outer!(C::MatOrView{T}, a::VecOrView{T}, b::SparseVector{T}, α::Number, β::Number) where T
    C[:, nonzeroinds(b)] .*=  β
    C[:, nonzeroinds(b)] .+=  a * (α.*nonzeros(b))'
    return C
end

"""
    fastdensesparsemul_outer_threaded!(C, a, b, α, β)

Threaded, fast outer product when computing `C .= β*C + α * a*b'`, but way faster than Base would, using `Polyester.jl`.
- `a` is a dense vector (or view), `b` is a sparse vector, `C` is a dense matrix (or view).

Also see `fastdensesparsemul_outer!` for a single-threaded version.
"""
function fastdensesparsemul_outer_threaded!(C::MatOrView{T}, a::VecOrView{T}, b::SparseVector{T}, α::Number, β::Number) where T
    inds = nonzeroinds(b)
    nzs = nonzeros(b)
    @batch for i in axes(nzs, 1)
        C[:, inds[i]] .*=  β
        C[:, inds[i]] .+=  (α.*nzs[i]).*a
    end
    return C
end

end # module ThreadedDenseSparseMul
