function vout = paramsel_hokrls(X,y,opt)
% paramsel_siglam(X,y, OPT)
% Performs parameter selection when the dual formulation of RLS is used.
% The hold-out approach is used.
% It selects both the regularization parameter lambda and the kernel parameter sigma.
%
% INPUTS:
% -OPT: struct of options with the following fields:
%   fields that need to be set through previous gurls tasks:
%		- kernel.K (set by the kernel_* routines)
%   fields with default values set through the defopt function:
%       - nsigma
%		- kernel.type
%		- nlambda
%       - hoperf
%
%   For more information on standard OPT fields
%   see also defopt
% 
% OUTPUT: structure with the following fields:
% -lambdas: value of the regularization parameter lambda
%           minimizing the validation error, replicated in a TX1 array 
%           where T is the number of classes
% -sigma: value of the kernel parameter minimizing the validation error


if isprop(opt,'paramsel')
	vout = opt.paramsel; % lets not overwrite existing parameters.
			      		 % unless they have the same name
else
    opt.newprop('paramsel', struct());
end

[~,T]  = size(y);

opt.kernel.init = 1;
opt.kernel = opt.kernel.func(X,y,opt);
nsigma = numel(opt.kernel.kerrange);

nlambda = numel(opt.paramsel.guesses);
PERF = zeros(nsigma, nlambda,T);

for i = 1:nsigma
	opt.paramsel.sigmanum = i;
	opt.kernel = opt.kernel.func(X,y,opt);
	paramsel = paramsel_bfdual(X,y,opt);
	nh = numel(paramsel.perf);
	PERF(i,:,:) = reshape(median(reshape(cell2mat(paramsel.perf')',nlambda*T,nh),2),T,nlambda)';
	guesses(i,:) = opt.paramsel.guesses;
end
% The lambda axis is redefined each time but
% it is the same for all classes as it depends
% only on K so we can still sum and minimize.
%
% We have to be a bit careful when minimizing.
%
% TODO: select a lambda for each class fixing sigma.

M = sum(PERF,3); % sum over classes

[dummy,i] = max(M(:));
[m,n] = ind2sub(size(M),i);

% opt sigma
vout.sigma = opt.kernel.kerrange(m);
% opt lambda
vout.lambdas = guesses(m,n)*ones(1,T);
