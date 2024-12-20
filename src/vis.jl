using .Makie

@doc raw"""
    show_embedding( Y [, L] )

Visualization of 2D embedding coordinates $Y$ using Makie. If the $n
\times 1$ vector $L$ of vertex memberships is provided, points are
colored accroding to the labels.

## Requirements

This function is provided only if the user already has Makie installed
in their Julia environment. Otherwise, the function will not be
defined.

## Notes

You need to install and select a backend for Makie. See
[instructions by Makie](http://makie.juliaplots.org/stable/backends_and_output.html)
for more details. For example, to show figures in an interactive window,
issue

```
] add GLMakie
using GLMakie
GLMakie.activate!()
```

## Optional arguments (for experts)

- `A=nothing`: adjacency matrix; if provided, edges are shown
- `cmap`: the colormap to use (default to distinguishable colors)
- `res=(800,800)`: figure resolution
- `lwd_in=0.5`: line width for internal edges
- `lwd_out=0.3`: line width for external edges
- `edge_alpha=0.2`: the alpha channel for the edges
- `clr_in=nothing`: set color for all intra-cluster edges (if nothing, color by `cmap`)
- `clr_out=colorant"#aabbbbbb"`: the color of inter-cluster edges
- `mrk_size=4`: marker size
- `size_label:24`: legend label size

"""
function show_embedding(
  Y, L::Vector{Int} = zeros( Int, size(Y,1) );
  cmap = distinguishable_colors(
    maximum(L) - minimum(L) + 1,
    [RGB(1,1,1), RGB(0,0,0)], dropseed=true),
  A = nothing,
  res  = (800, 800),
  lwd_in  = 0.5,
  lwd_out = 0.3,
  edge_alpha = 0.2,
  clr_out = colorant"#aabbbbbb",
  clr_in = nothing,
  mrk_size = 4,
  size_label = 24 )


  function _plot_lines!( ax, Y, i, j, idx, color, lwd )
    ii = vec( [reshape( Y[ vcat( i[idx], j[idx] ), 1 ], (Int32.(sum(idx)), 2) ) NaN*zeros(sum(idx))]' )
    jj = vec( [reshape( Y[ vcat( i[idx], j[idx] ), 2 ], (Int32.(sum(idx)), 2) ) NaN*zeros(sum(idx))]' )

    lines!( ax, ii, jj, color = color, linewidth = lwd )

  end


  n = size( Y, 1 )

  L .= L .- minimum( L )
  L_u = sort( unique( L ) )
  nc  = length( L_u )

  f = Figure(size = res)
  ax = (nc>1) ? Axis(f[2, 1]) : Axis(f[1, 1])


  if !isnothing( A )
    i,j = findnz( tril(A) )
    for kk ∈ L_u
      idx_inner = map( (x,y) -> x == y && x == kk, L[i], L[j] )
      if isnothing( clr_in )  # use cmap
        _plot_lines!( ax, Y, i, j, idx_inner, RGBA(cmap[kk+1], edge_alpha), lwd_in )
      else
        _plot_lines!( ax, Y, i, j, idx_inner, clr_in, lwd_in )
      end
    end
    idx_cross = map( (x,y) -> x != y, L[i], L[j] )
    _plot_lines!( ax, Y, i, j, idx_cross, clr_out, lwd_out )
  end

  scatter!(ax, Y[:,1], Y[:,2], color = L, colormap = cmap,
           markersize = mrk_size);
  ax.aspect = DataAspect();

  lgnd_elem = [MarkerElement(color = cmap[i+1],
                             marker = :circle,
                             markersize = 20,
                             strokecolor = :black) for i = L_u];


  if nc > 1
    Legend(f[1, 1], lgnd_elem, string.( sort( unique(L) ) ),
           orientation = :horizontal, tellwidth = false, tellheight = true,
           labelsize = size_label);
  end

  f

end


@doc raw"""
    neighbor_recall(X, Y[; k = 10])

Histogram of the stochastic k-neighbors recall values at all vertices.

```math
{\rm recall}(v) = \sum_j \mathbf{P}_{j|i} b_{ij},
```

where ``\mathbf{B}_k = [b_{ij}]`` is the adjacency matrix of the kNN graph of
the embedded points ``\mathbf{Y}`` in Euclidean distance,
and ``\mathbf{P}_{j|i}`` is the neighborhood probability matrix in the
high-dimensional space ``\mathbf{X}``.

See Fig.4 in https://arxiv.org/pdf/1906.05582.pdf for more details.

"""
function neighbor_recall(X, Y; k = 10, resolution = (800,600))

  X = permutedims(X)
  Y = permutedims(Y)

  idx_high, _ = NearestNeighbors.knn(BruteTree(X), X, k, true)
  idx_low , _ = NearestNeighbors.knn(BruteTree(Y), Y, k, true)

  sd = Vector{Float64}(undef, length(idx_low))
  for i = 1 : length(sd)
    sd[i] = length( intersect( idx_low[i], idx_high[i] ) ) / k
  end

  f = Figure(;resolution)

  ax = Axis(f[1, 1], limits = (0, 1, 0, nothing),
            xlabel = "neighborhood recall",
            ylabel = "relative frequency")
  hist!( ax, sd, normalization = :pdf )

  f

end
