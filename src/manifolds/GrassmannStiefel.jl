#
# Default implementation for the matrix type, i.e. as congruence class Stiefel matrices
#
"""
    StiefelPoint <: AbstractManifoldPoint

A point on a [`Stiefel`](@ref) manifold.
This point is mainly used for representing points on the [`Grassmann`](@ref) where this
is also the default representation and hence equivalent to using `AbstractMatrices` thereon.
they can also used be used as points on Stiefel.
"""
struct StiefelPoint{T<:AbstractMatrix} <: AbstractManifoldPoint
    value::T
end

"""
    StiefelTVector <: TVector

A tangent vector on the [`Grassmann`](@ref) manifold represented by a tangent vector from
the tangent space of a corresponding point from the [`Stiefel`](@ref) manifold,
see [`StiefelPoint`](@ref).
This is the default representation so is can be used interchangeably with just abstract matrices.
"""
struct StiefelTVector{T<:AbstractMatrix} <: AbstractManifoldPoint
    value::T
end

ManifoldsBase.@manifold_element_forwards StiefelPoint value
ManifoldsBase.@manifold_vector_forwards StiefelTVector value
ManifoldsBase.@default_manifold_fallbacks Stiefel StiefelPoint StiefelTVector value value
ManifoldsBase.@default_manifold_fallbacks (Stiefel{<:Any,ℝ}) StiefelPoint StiefelTVector value value
ManifoldsBase.@default_manifold_fallbacks Grassmann StiefelPoint StiefelTVector value value

function default_vector_transport_method(::Grassmann, ::Type{<:AbstractArray})
    return ProjectionTransport()
end
default_vector_transport_method(::Grassmann, ::Type{<:StiefelPoint}) = ProjectionTransport()

@doc raw"""
    distance(M::Grassmann, p, q)

Compute the Riemannian distance on [`Grassmann`](@ref) manifold `M```= \mathrm{Gr}(n,k)``.

The distance is given by
````math
d_{\mathrm{Gr}(n,k)}(p,q) = \operatorname{norm}(\log_p(q)).
````
"""
function distance(::Grassmann, p, q)
    z = p' * q
    S = svd(q / z - p).S
    return norm(map(atan, S))
end

embed(::Grassmann, p) = p
embed(::Grassmann, p, X) = X
embed!(::Grassmann, q, p) = copyto!(q, p)
embed!(::Grassmann, Y, p, X) = copyto!(Y, X)
embed!(::Grassmann, q, p::StiefelPoint) = copyto!(q, p.value)
embed!(::Grassmann, Y, p::StiefelPoint, X::StiefelTVector) = copyto!(Y, X.value)
embed(::Grassmann, p::StiefelPoint) = p.value
embed(::Grassmann, p::StiefelPoint, X::StiefelTVector) = X.value
embed!(::Stiefel, q, p::StiefelPoint) = copyto!(q, p.value)
embed!(::Stiefel, Y, p::StiefelPoint, X::StiefelTVector) = copyto!(Y, X.value)
embed(::Stiefel, p::StiefelPoint) = p.value
embed(::Stiefel, p::StiefelPoint, X::StiefelTVector) = X.value

@doc raw"""
    exp(M::Grassmann, p, X)

Compute the exponential map on the [`Grassmann`](@ref) `M` ``= \mathrm{Gr}(n,k)`` starting in
`p` with tangent vector (direction) `X`. Let ``X = USV`` denote the SVD decomposition of ``X``.
Then the exponential map is written using

````math
z = p V\cos(S)V^\mathrm{H} + U\sin(S)V^\mathrm{H},
````

where ``⋅^{\mathrm{H}}`` denotes the complex conjugate transposed or Hermitian and the
cosine and sine are applied element wise to the diagonal entries of ``S``. A final QR
decomposition ``z=QR`` is performed for numerical stability reasons, yielding the result as

````math
\exp_p X = Q.
````
"""
exp(::Grassmann, ::Any...)

function exp!(M::Grassmann, q, p, X)
    norm(M, p, X) ≈ 0 && return copyto!(q, p)
    d = svd(X)
    z = (p * (d.V .* cos.(d.S')) + d.U .* sin.(d.S')) * d.Vt
    return copyto!(q, Array(qr(z).Q))
end

function get_embedding(::Grassmann{TypeParameter{Tuple{n,k}},𝔽}) where {n,k,𝔽}
    return Stiefel(n, k, 𝔽)
end
function get_embedding(M::Grassmann{Tuple{Int,Int},𝔽}) where {𝔽}
    n, k = get_parameter(M.size)
    return Stiefel(n, k, 𝔽; parameter=:field)
end

@doc raw"""
    inner(M::Grassmann, p, X, Y)

Compute the inner product for two tangent vectors `X`, `Y` from the tangent space
of `p` on the [`Grassmann`](@ref) manifold `M`. The formula reads

````math
g_p(X,Y) = \operatorname{tr}(X^{\mathrm{H}}Y),
````

where ``⋅^{\mathrm{H}}`` denotes the complex conjugate transposed or Hermitian.
"""
inner(::Grassmann, p, X, Y) = dot(X, Y)

@doc raw"""
    inverse_retract(M::Grassmann, p, q, ::PolarInverseRetraction)

Compute the inverse retraction for the [`PolarRetraction`](https://juliamanifolds.github.io/ManifoldsBase.jl/stable/retractions.html#ManifoldsBase.PolarRetraction), on the
[`Grassmann`](@ref) manifold `M`, i.e.,

````math
\operatorname{retr}_p^{-1}q = q*(p^\mathrm{H}q)^{-1} - p,
````

where ``⋅^{\mathrm{H}}`` denotes the complex conjugate transposed or Hermitian.
"""
inverse_retract(::Grassmann, ::Any, ::Any, ::PolarInverseRetraction)

function inverse_retract_polar!(::Grassmann, X, p, q)
    X .= q / (p' * q) .- p
    return X
end

@doc raw"""
    inverse_retract(M, p, q, ::QRInverseRetraction)

Compute the inverse retraction for the [`QRRetraction`](https://juliamanifolds.github.io/ManifoldsBase.jl/stable/retractions.html#ManifoldsBase.QRRetraction), on the
[`Grassmann`](@ref) manifold `M`, i.e.,

````math
\operatorname{retr}_p^{-1}q = q(p^\mathrm{H}q)^{-1} - p,
````
where ``⋅^{\mathrm{H}}`` denotes the complex conjugate transposed or Hermitian.
"""
inverse_retract(::Grassmann, ::Any, ::Any, ::QRInverseRetraction)

function inverse_retract_qr!(::Grassmann, X, p, q)
    X .= q / (p' * q) .- p
    return X
end

@doc raw"""
    log(M::Grassmann, p, q)

Compute the logarithmic map on the [`Grassmann`](@ref) `M` `` = \mathcal M=\mathrm{Gr}(n,k)``,
i.e. the tangent vector `X` whose corresponding [`geodesic`](https://juliamanifolds.github.io/ManifoldsBase.jl/stable/functions.html#ManifoldsBase.geodesic-Tuple{AbstractManifold,%20Any,%20Any}) starting from `p`
reaches `q` after time 1 on `M`. The formula reads

````math
\log_p q = V⋅ \operatorname{atan}(S) ⋅ U^\mathrm{H},
````

where ``⋅^{\mathrm{H}}`` denotes the complex conjugate transposed or Hermitian.
The matrices ``U`` and ``V`` are the unitary matrices, and ``S`` is the diagonal matrix
containing the singular values of the SVD-decomposition

````math
USV = (q^\mathrm{H}p)^{-1} ( q^\mathrm{H} - q^\mathrm{H}pp^\mathrm{H}).
````

In this formula the ``\operatorname{atan}`` is meant elementwise.
"""
log(::Grassmann, ::Any...)

function log!(M::Grassmann, X, p, q)
    inverse_retract_polar!(M, X, p, q)
    d = svd(X)
    mul!(X, d.U, atan.(d.S) .* d.Vt)
    return X
end

@doc raw"""
    project(M::Grassmann, p)

Project `p` from the embedding onto the [`Grassmann`](@ref) `M`, i.e. compute `q`
as the polar decomposition of ``p`` such that ``q^{\mathrm{H}}q`` is the identity,
where ``⋅^{\mathrm{H}}`` denotes the Hermitian, i.e. complex conjugate transposed.
"""
project(::Grassmann, ::Any)

function project!(::Grassmann, q, p)
    s = svd(p)
    mul!(q, s.U, s.Vt)
    return q
end

@doc raw"""
    project(M::Grassmann, p, X)

Project the `n`-by-`k` `X` onto the tangent space of `p` on the [`Grassmann`](@ref) `M`,
which is computed by

````math
\operatorname{proj_p}(X) = X - pp^{\mathrm{H}}X,
````

where ``⋅^{\mathrm{H}}`` denotes the complex conjugate transposed or Hermitian.
"""
project(::Grassmann, ::Any...)

function project!(::Grassmann, Y, p, X)
    copyto!(Y, X)
    mul!(Y, p, p' * X, -1, 1)
    return Y
end

@doc raw"""
    rand(M::Grassmann; σ::Real=1.0, vector_at=nothing)

When `vector_at` is `nothing`, return a random point `p` on [`Grassmann`](@ref) manifold `M`
by generating a random (Gaussian) matrix with standard deviation `σ` in matching
size, which is orthonormal.

When `vector_at` is not `nothing`, return a (Gaussian) random vector from the tangent space
``T_p\mathrm{Gr}(n,k)`` with mean zero and standard deviation `σ` by projecting a random
Matrix onto the tangent space at `vector_at`.
"""
rand(M::Grassmann; σ::Real=1.0)

function Random.rand!(
    rng::AbstractRNG,
    M::Grassmann{<:Any,𝔽},
    pX;
    σ::Real=one(real(eltype(pX))),
    vector_at=nothing,
) where {𝔽}
    if vector_at === nothing
        n, k = get_parameter(M.size)
        V = σ * randn(rng, 𝔽 === ℝ ? Float64 : ComplexF64, (n, k))
        pX .= qr(V).Q[:, 1:k]
    else
        Z = σ * randn(rng, eltype(pX), size(pX))
        project!(M, pX, vector_at, Z)
        pX ./= norm(pX)
    end
    return pX
end

@doc raw"""
    representation_size(M::Grassmann)

Return the representation size or matrix dimension of a point on the [`Grassmann`](@ref)
`M`, i.e. ``(n,k)`` for both the real-valued and the complex value case.
"""
representation_size(M::Grassmann) = get_parameter(M.size)

@doc raw"""
    retract(M::Grassmann, p, X, ::PolarRetraction)

Compute the SVD-based retraction [`PolarRetraction`](https://juliamanifolds.github.io/ManifoldsBase.jl/stable/retractions.html#ManifoldsBase.PolarRetraction) on the
[`Grassmann`](@ref) `M`. With ``USV = p + X`` the retraction reads
````math
\operatorname{retr}_p X = UV^\mathrm{H},
````

where ``⋅^{\mathrm{H}}`` denotes the complex conjugate transposed or Hermitian.
"""
retract(::Grassmann, ::Any, ::Any, ::PolarRetraction)

function retract_polar!(M::Grassmann, q, p, X, t::Number)
    q .= p .+ t .* X
    project!(M, q, q)
    return q
end

@doc raw"""
    retract(M::Grassmann, p, X, ::QRRetraction )

Compute the QR-based retraction [`QRRetraction`](https://juliamanifolds.github.io/ManifoldsBase.jl/stable/retractions.html#ManifoldsBase.QRRetraction) on the
[`Grassmann`](@ref) `M`. With ``QR = p + X`` the retraction reads
````math
\operatorname{retr}_p X = QD,
````
where D is a ``m×n`` matrix with
````math
D = \operatorname{diag}\left( \operatorname{sgn}\left(R_{ii}+\frac{1}{2}\right)_{i=1}^n \right).
````
"""
retract(::Grassmann, ::Any, ::Any, ::QRRetraction)

function retract_qr!(::Grassmann, q, p, X, t::Number)
    q .= p .+ t .* X
    qrfac = qr(q)
    d = diag(qrfac.R)
    q .= Array(qrfac.Q) .* sign.(transpose(d) .+ 1 // 2)
    return q
end

@doc raw"""
    riemannian_Hessian(M::Grassmann, p, G, H, X)

The Riemannian Hessian can be computed by adopting Eq. (6.6) [Nguyen:2023](@cite),
where we use for the [`EuclideanMetric`](https://juliamanifolds.github.io/ManifoldsBase.jl/stable/manifolds.html#ManifoldsBase.EuclideanMetric) ``α_0=α_1=1`` in their formula.
Let ``\nabla f(p)`` denote the Euclidean gradient `G`,
``\nabla^2 f(p)[X]`` the Euclidean Hessian `H`. Then the formula reads

```math
    \operatorname{Hess}f(p)[X]
    =
    \operatorname{proj}_{T_p\mathcal M}\Bigl(
        ∇^2f(p)[X] - X p^{\mathrm{H}}∇f(p)
    \Bigr).
```

Compared to Eq. (5.6) also the metric conversion simplifies to the identity.
"""
riemannian_Hessian(M::Grassmann, p, G, H, X)

function riemannian_Hessian!(M::Grassmann, Y, p, G, H, X)
    project!(M, Y, p, H - X * p' * G)
    return Y
end

@doc raw"""
    riemann_tensor(::Grassmann{<:Any,ℝ}, p, X, Y, Z)

Compute the value of Riemann tensor on the real [`Grassmann`](@ref) manifold.
The formula reads [Rentmeesters:2011](@cite)
``R(X,Y)Z = (XY^\mathrm{T} - YX^\mathrm{T})Z + Z(Y^\mathrm{T}X - X^\mathrm{T}Y)``.
"""
riemann_tensor(::Grassmann{<:Any,ℝ}, p, X, Y, Z)

function riemann_tensor!(::Grassmann{<:Any,ℝ}, Xresult, p, X, Y, Z)
    XYᵀ = X * Y'
    YXᵀ = XYᵀ'
    YᵀX = Y' * X
    XᵀY = YᵀX'
    Xresult .= (XYᵀ - YXᵀ) * Z .- Z * (YᵀX - XᵀY)
    return Xresult
end

function Base.show(io::IO, ::Grassmann{TypeParameter{Tuple{n,k}},𝔽}) where {n,k,𝔽}
    return print(io, "Grassmann($(n), $(k), $(𝔽))")
end
function Base.show(io::IO, M::Grassmann{Tuple{Int,Int},𝔽}) where {𝔽}
    n, k = get_parameter(M.size)
    return print(io, "Grassmann($(n), $(k), $(𝔽); parameter=:field)")
end
Base.show(io::IO, p::StiefelPoint) = print(io, "StiefelPoint($(p.value))")
Base.show(io::IO, X::StiefelTVector) = print(io, "StiefelTVector($(X.value))")

"""
    uniform_distribution(M::Grassmann{<:Any,ℝ}, p)

Uniform distribution on given (real-valued) [`Grassmann`](@ref) `M`.
Specifically, this is the normalized Haar measure on `M`.
Generated points will be of similar type as `p`.

The implementation is based on Section 2.5.1 in [Chikuse:2003](@cite);
see also Theorem 2.2.2(iii) in [Chikuse:2003](@cite).
"""
function uniform_distribution(M::Grassmann{<:Any,ℝ}, p)
    n, k = get_parameter(M.size)
    μ = Distributions.Zeros(n, k)
    σ = one(eltype(p))
    Σ1 = Distributions.PDMats.ScalMat(n, σ)
    Σ2 = Distributions.PDMats.ScalMat(k, σ)
    d = MatrixNormal(μ, Σ1, Σ2)

    return ProjectedPointDistribution(M, d, (M, q, p) -> (q .= svd(p).U), p)
end

@doc raw"""
    vector_transport_to(M::Grassmann, p, X, q, ::ProjectionTransport)

compute the projection based transport on the [`Grassmann`](@ref) `M` by
interpreting `X` from the tangent space at `p` as a point in the embedding and
projecting it onto the tangent space at q.
"""
vector_transport_to(::Grassmann, ::Any, ::Any, ::Any, ::ProjectionTransport)

@doc raw"""
    zero_vector(M::Grassmann, p)

Return the zero tangent vector from the tangent space at `p` on the [`Grassmann`](@ref) `M`,
which is given by a zero matrix the same size as `p`.
"""
zero_vector(::Grassmann, ::Any...)

zero_vector!(::Grassmann, X, p) = fill!(X, 0)
