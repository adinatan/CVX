function y = prod( x, dim )
error( nargchk( 1, 2, nargin ) );

%
% Basic argument check
%

sx = size( x );
if nargin < 2,
    dim = cvx_default_dimension( sx );
elseif ~cvx_check_dimension( dim ),
    error( 'Second argument must be a positive integer.' );
end

%
% Determine sizes
%

sx = [ sx, ones( 1, dim - length( sx ) ) ];
nx = sx( dim );
sy = sx;
sy( dim ) = 1;

%
% Quick exit for empty arrays
%

if any( sx == 0 ),
    y = ones( sy );
    return
end

%
% Type check
%

persistent remap_1 remap_2 remap_3 remap_0
if isempty( remap_3 ),
    remap_0 = cvx_remap( 'zero' );
    remap_1 = cvx_remap( 'constant' );
    remap_2 = cvx_remap( 'log-convex' );
    remap_3 = cvx_remap( 'log-concave' );
end
vx = cvx_reshape( cvx_classify( x ), sx );
t0 = any( reshape( remap_0( vx ), sx ), dim );
t1 = all( reshape( remap_1( vx ), sx ), dim );
t2 = all( reshape( remap_2( vx ), sx ), dim ) | ...
     all( reshape( remap_3( vx ), sx ), dim );
t3 = t2 & t0;
ta = ( t1 | t3 ) + 2 * ( t2 & ~t3 );
nu = unique( ta( : ) );
nk = length( nu );

%
% Quick exit for easy case
%

if nx == 1 & nu(1) > 0,
    y = x;
    return
end

%
% Permute and reshape, if needed
%

perm = [];
if nk > 1 | ( any( nu > 1 ) & nx > 1 ),
    if dim > 1 & any( sx( 1 : dim - 1 ) > 1 ),
        perm = [ dim, 1 : dim - 1, dim + 1 : length( sx ) ];
        x    = permute( x,  perm );
        sx   = permute( sx, perm );
        sy   = permute( sy, perm );
        ta   = permute( ta, perm );
        dim  = 1;
    end
    nv = prod( sy );
    x  = reshape( x, nx, nv );
end

%
% Perform the computations
%

if nk > 1,
    y = cvx( [ 1, nv ], [] );
end
for k = 1 : nk,

    if nk == 1,
        xt = x;
    else
        tt = ta == nu( k );
        xt = cvx_subsref( x, ':', tt );
    end

    switch nu( k ),
        case 0,
            error( sprintf( 'Disciplined convex programming error:\n   Invalid computation: prod( {%s} )', cvx_class( xt, true, true ) ) );
        case 1,
            yt = prod( cvx_constant( xt ), dim );
        case 2,
            yt = exp( sum( log( xt ), dim ) );
        otherwise,
            error( 'Shouldn''t be here.' );
    end

    if nk == 1,
        y = yt;
    else
        y = cvx_subsasgn( y, tt, yt );
    end

end

%
% Reverse the reshaping and permutation steps
%

y = reshape( y, sy );
if ~isempty( perm ),
    y = ipermute( y, perm );
end

% Copyright 2007 Michael C. Grant and Stephen P. Boyd.
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.