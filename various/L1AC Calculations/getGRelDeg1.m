function [G1,c0] = getGRelDeg1(F,G,B)
% L1 Adaptive Control book, Lemma A.12.1 using Corollary A.11.1
% F should be strictly proper, then program find c0T s.t. c0T.G(s) has
% relative degree one, and c0T G(s) has all its zeros in the left half plane.
% If G and be is specified, then G is treated as A, as in xdot = Ax+Bu


s = tf('s') ;
% keyboard
if nargin < 3
    a = cell2mat(get(G,'num')) ;
    b = cell2mat(get(G,'den'))  ;
    b = b(1,:) ; % Since one common den for all tf's (for different outputs)
    [A,B,C,D] = tf2ss(a,b) ;
     
elseif nargin == 3
    A = G ;
end


n = size(A,1) ;

% Check controllability of G
Co = ctrb(A,B) ;
unco=length(A)-rank(Co) ;

if unco>0
    warning(['G is not controllable, number of uncontrollable states: '...
        num2str(unco)])
end

G0 = ((s*eye(n)-A)^-1)*B ;
G0_N = cell2mat(get(G0,'num')) ;
G0_D = cell2mat(get(G0,'den')) ;
G0_D = G0_D(1,:) ; % Since one common den for all tf's (for different outputs)

N = G0_N(1:n,size(G0_N,2)-n+1:size(G0_N,2));
W = N(:,n:-1:1) ; % Form in the book, but I'm not sure..

cbar = ones(n,1) ;
c0 = (W^-1)'*cbar ;
G1 = F*tf(G0_D,c0'*G0_N)*c0' ;















