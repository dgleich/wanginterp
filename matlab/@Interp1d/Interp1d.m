classdef Interp1d < handle
    properties
        xv
        fxv
        safety
        N
        n
        l
        beta
        gamma
        nv
        ng
        verbose 
        dfxv
    end
    methods
        function I=Interp1d(xv, fxv, varargin)
            I.xv = xv;
            I.fxv = fxv;
            assert(numel(xv) == numel(fxv));
            % handle optional args
            handle_opts(I,struct(varargin{:}));
            I.nv = numel(xv);
            I.ng = 0;
            I.n = I.nv;
            if isempty(I.beta), calc_beta(I); end
            if isempty(I.gamma), calc_gamma(I); end
        end
        
        function handle_opts(I,optsu)
            I.safety = 1; 
            I.l = 1;
            I.verbose = 3;
            I.N = min(numel(I.xv),200);
            
            for f=fieldnames(optsu)'
                f=char(f);
                I.(f) = optsu.(f);
            end
        end
        
        function calc_beta(I)
            if isempty(I.dfxv), I.beta = 1; return; end
            % add Qiqi's ratio computation
            f_bar = mean(I.fxv);
            % ratio = ...
            I.beta = norm(I.fxv - f_bar)/sqrt(I.nv - 1);
        end
        
        function [gmin,gmax]=calc_gamma_bounds(I)
            sxv = sort(I.xv);
            delta_max = max(I.xv)-min(I.xv);
            delta_min = min(sxv(2:end)-sxv(1:end-1));
            gmin = 1/delta_max;
            gmax = pi/delta_min;
        end
        function calc_gamma(I)
            [gmin,gmax]=calc_gamma_bounds(I);
            while gmax/gmin > 1.1
                if I.verbose
                    fprintf('bisecting [%g , %g] for gamma\n', gmin,gmax);
                end
                gmid = sqrt(gmin*gmax);
                resid = 0;
                for i=1:I.nv,
                    mask = 1:I.nv; mask(i)=[];
                    I2 = Interp1d(I.xv(mask), I.fxv(mask), ...
                        'gamma',gmid,'beta',I.beta,'N',I.N);
                    [av,ag,er2] = I2.interp_coef(I.xv(i));
                    ri = dot(av,I.fxv(mask)) - I.fxv(i);
                    % TODO add gradient
                    ri = ri^2/(er2)*I.safety;
                    resid = resid + ri;
                end
                res_ratio = resid/I.nv;
                if res_ratio < 1
                    gmax = gmid;
                else
                    gmin = gmid;
                end
            end
            I.gamma = sqrt(gmax*gmin);
        end
        function [av, ag, er2]=interp_coef(I,x)
            [minval,minind] = min(abs(I.xv-x));
            if minval < 1e-12,
                av = zeros(I.nv,1);
                av(minind) = 1;
                ag = zeros(I.ng,1);
                er2 = 0;
                return;
            end
            [X,E,C] = interp_matrices(I,x);
            D = sum(X.^2) + E'.^2;
            finite = isfinite(D);
            %D = (X**2).sum(0) + E**2
            %finite = 
            % solve with lsqr wang
            XE = [X(:,finite);diag(E(finite))];
            [Q,R] = qr(XE,0);
            a = zeros(size(C,2),1);
            a(finite) = R\(R'\C(finite)');
            a = a/(C*a);
            av = a;
            ag = [];
            finite = (a ~= 0);
            Xa = X(:,finite)*a(finite);
            Ea = E(finite).*a(finite);
            er2 = norm(Xa,'fro')^2 + norm(Ea,'fro')^2;
        end
        function [X,e,C] = interp_matrices(I,x)
            N = I.N;
            n = I.n;
            gamma = I.gamma;
            beta = I.beta;
            
            X = zeros(n,N);
            for i=1:N
                X(:,i) = gamma.^(i) ./ factorial(i) * (I.xv(:) - x).^(i);
                % add contribution from gradient
                % fix ratio of gamma^i/factorial
            end
            X = beta*X';
            
            er = gamma^(N+1) ./ factorial(N+1) * (I.xv(:) - x).^(N+1);
            e = er;
            C = zeros(n,I.l);
            C(:,1) = 1;
            % add contrib from gradient
            for i=2:I.l
                C(:,i) = (I.xv-x).^(i-1);
            end
            C = C';
        end
        function fx=interp(I,x)
            % TODO return dfx
            if isscalar(x)
                [av,ag,er2]=interp_coef(I,x);
                fx = dot(av, I.fxv); % TODO add gradient
                dfx = sqrt(er2);
            else
                fx = zeros(size(x));
                for i=1:numel(x)
                    xi=x(i);
                    [av,ag,er2]=interp_coef(I,xi);
                    fxi = dot(av, I.fxv); % TODO add gradient
                    dfx = sqrt(er2);
                    fx(i)=fxi;
                end
            end
        end
    end
end

