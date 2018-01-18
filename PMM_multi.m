function [eta_R, eta_T, M,...
        gzero,gzero_norm, gamma0,gamma_num,gammaminus] =...
        PMM_multi(int_P1_Q1,int_P1_Q2, fx_coef, fy_coef, Ex0, Ey0, lambda, theta, phi,...
        N_FMM, h, L, refIndices, alpha_ref, beta_ref,...
        b_x1, b_x2, N_intervals_x, N_intervals_y, N_basis_x, N_basis_y,...
        Dx, Dy, hx, hy, eps_total, mu_total,verbose)
    
    
    N_total_x = sum(N_basis_x);  %total number of basis functions
    N_total_y = sum(N_basis_y);  %total number of basis functions
    N_total_x3 = N_total_x - N_intervals_x;  %number of basis functions in "third" basis
    N_total_y3 = N_total_y - N_intervals_y;
    N_total_3 = N_total_x3*N_total_y3;
    
    
    n1 = refIndices(1);
    n2 = refIndices(2);
    k0 = 2*pi/lambda;
    alpha0 = k0*n1*sin(theta)*cos(phi);
    beta0  = k0*n1*sin(theta)*sin(phi);
    gamma0 = k0*n1*cos(theta);
    
    %title = 'plot things'
    %{
x_full = PMM_graph(E_PMM, La, alpha0, beta0, alpha_ref, beta_ref,...
   b_x1, b_x2, N_intervals_x, N_intervals_y, N_basis_x, N_basis_y, Nx, nx, Ny, ny,...
   ax, ay);
    %}
    gammaminus = zeros(2*N_total_3, L);
    
    
    pplus = zeros(2*N_total_3, 2*N_total_3, L);
    pminus = zeros(2*N_total_3, 2*N_total_3, L);
    
    M = zeros(4*N_total_3, 4*N_total_3,L);
    W = zeros(4*N_total_3, 4*N_total_3, L);
    
    for i=1:L
        %{
            [Wt, pplust, pminust, gammaminus_t] = ...
            PMM_gamma(alpha_ref, beta_ref, k0, alpha0, beta0, h(i),...
            N_intervals_x, N_intervals_y, N_basis_x, N_basis_y, Dx, Dy, hx, hy,...
            eps_total(:,:,:,i), mu_total(:,:,:,i),verbose);
        %}
        [L_HE, L_EH]= ...
            PMM_Maxwell_matrix(alpha_ref, beta_ref, k0, alpha0, beta0,...
            N_intervals_x, N_intervals_y, N_basis_x, N_basis_y,...
            Dx, Dy, hx, hy, eps_total(:,:,:,i), mu_total(:,:,:,i),verbose);
        [Wt, pplust, pminust, gammaminus_t]= ...
            PMM_eig_for_Maxwell(L_HE,L_EH,h(i),N_total_3,verbose);
        
        
        gammaminus(:,i) = gammaminus_t;
        W(:,:,i) = Wt;
        pplus(:,:,i) = pplust;
        pminus(:,:,i) = pminust;
    end
    
    
    %S-matrix propagation
    
    Smin1 = eye(4*N_total_3,4*N_total_3);
    Stemp = Smin1;
    for i=1:(L-1)
        Si = new_recursion(Stemp, W(:,:,i), W(:,:,i+1), pplus(:,:,i), pminus(:,:,i+1));
        Stemp = Si;
    end
    Stotal = Stemp;
    
    if (verbose>5)
        title = 'derive incident coefficients'
    end
    
    gamma00 = gamma0;
    %size_gammaminus = size(gammaminus)
    gammaminus_new = sort(gammaminus(:,L));
    %size_gammaminus_new = size(gammaminus_new(:,L))
    [diff_gamma,numbers_diff_gamma] = sort(abs(gammaminus(:,L)+gamma0));
    
    q01 = numbers_diff_gamma(1);
    q02 = numbers_diff_gamma(2);
    %{
    min = abs(gammaminus(1,L)+gamma0);
    q01 = 1;
    for q2 = 1:2*N_total_3
        if abs(gammaminus(q2,L)+gamma0)<min %&&...
            %(abs(imag(gammaminus(q2,L))/real(gammaminus(q2,L)))<0.001)
            min = abs(gammaminus(q2,L)+gamma0);
            q01 = q2;
        end
    end
    gammaminus(q01,L) = gammaminus(q01,L)+100;
    
    q02 = 1;
    min = abs(gammaminus(1,L)+gamma0);
    for q2 = 1:2*N_total_3
        if abs(gammaminus(q2,L)+gamma0)<min %&& (q2~=q01) %&&...
            %(abs(imag(gammaminus(q2,L))/real(gammaminus(q2,L)))<0.001)
            min = abs(gammaminus(q2,L)+gamma0);
            q02 = q2;
        end
    end
    gammaminus(q01,L) = gammaminus(q01,L)-100;
    %}
    
    gg1 = gammaminus(q01,L);
    gg2 = gammaminus(q02,L);
    gkz0 = gamma0;
    gzero_norm = abs((gamma0+gg2)/gamma0);
    gzero = abs(gamma0+gg2);
    gamma_num=-real(gg2);
    
    u0_1 = zeros(N_total_3,1);
    u0_2 = zeros(N_total_3,1);
    d2_1 = zeros(N_total_3,1);
    d2_2 = zeros(N_total_3,1);
    
    %WL = W(:,:,L);
    %maxW = max(WL(:))
    N2 = 2*N_total_3;
    MW = [W(1,N2+q01,L), W(1,N2+q02,L); W(N_total_3+2,N2+q01,L), W(N_total_3+2,N2+q02,L)];
    Isigma = [Ex0*int_P1_Q1; Ey0*int_P1_Q2]*exp(-1j*gamma0*sum(h));
    
    dq = MW\Isigma;
    dlast = zeros(2*N_total_3,1);
    dlast(q01) = dq(1);
    dlast(q02) = dq(2);
    delta_inc = cat(1,u0_1,u0_2,dlast);
    delta_max = max(delta_inc);
    
    ud_PMM = Stotal*delta_inc;
    %ud_PMM_1=max(ud_PMM);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %we have made all calculations in the Gegenbauer basis
    %now we have to go back to the Fourier basis
    
    N = N_FMM;
    NN = (2*N_FMM+1)*(2*N_FMM+1);
    
    %gamma = zeros(4*NN,4*NN,L);
    
    k1 = k0*n1;
    k2 = k0*n2;
    alpha_v = zeros(2*N+1,1);
    beta_v = zeros(2*N+1,1);
    
    [Nxx, NNxx] = size(b_x1);
    [Nyy, NNyy] = size(b_x2);
    periodx = b_x1(NNxx)-b_x1(1);
    periody = b_x2(NNyy)-b_x2(1);
    
    for m=1:(2*N+1)
        alpha_v(m) = (alpha0 + (m-N-1)*2*pi/periodx);
        beta_v(m) = (beta0 + (m-N-1)*2*pi/periody);
    end
    alpha = zeros(NN,NN);
    beta = zeros(NN,NN);
    
    for i = 1:(2*N+1)
        for j=1:(2*N+1)
            m = i+(2*N+1)*(j-1);
            beta(m,m) = beta_v(i);
            alpha(m,m) = alpha_v(j);
        end
    end
    
    kz1v = zeros(NN,1);
    kz2v = zeros(NN,1);
    A1 = zeros(NN,NN);
    B1 = zeros(NN,NN);
    C1 = zeros(NN,NN);
    A2 = zeros(NN,NN);
    B2 = zeros(NN,NN);
    C2 = zeros(NN,NN);
    
    
    for i = 1:(2*N+1)
        for j=1:(2*N+1)
            m = i+(2*N+1)*(j-1);
            kz1v(m) = ( k1^2 - (alpha_v(j))^2 - (beta_v(i))^2 )^(1/2);
            kz2v(m) = ( k2^2 - (alpha_v(j))^2 - (beta_v(i))^2 )^(1/2);
            A1(m,m) = ( k1^2 - (alpha_v(j))^2)/(k0*kz1v(m));
            A2(m,m) = ( k2^2 - (alpha_v(j))^2)/(k0*kz2v(m));
            B1(m,m) = ( k1^2 - (beta_v(i))^2)/(k0*kz1v(m));
            B2(m,m) = ( k2^2 - (beta_v(i))^2)/(k0*kz2v(m));
            C1(m,m) = alpha_v(j)*beta_v(i)/(k0*kz1v(m));
            C2(m,m) = alpha_v(j)*beta_v(i)/(k0*kz2v(m));
        end
    end
    
    u2_PMM = ud_PMM(1:2*N_total_3);
    d0_PMM = ud_PMM(2*N_total_3+1:4*N_total_3);
    
    u2_1_FMM = fx_coef*W(1:N_total_3, 1:2*N_total_3, L)*u2_PMM;
    u2_2_FMM = fy_coef*W(N_total_3+1:2*N_total_3, 1:2*N_total_3, L)*u2_PMM;
    d0_1_FMM = fx_coef*W(1:N_total_3, 2*N_total_3+1:4*N_total_3, 1)*d0_PMM;
    d0_2_FMM = fy_coef*W(N_total_3+1:2*N_total_3, 2*N_total_3+1:4*N_total_3, 1)*d0_PMM;
    
    R1 = zeros(NN,1);
    R2 = zeros(NN,1);
    T1 = d0_1_FMM;
    T2 = d0_2_FMM;
    
    for i=1:NN
        R1(i) = u2_1_FMM(i)/exp(1j*kz1v(i)*(sum(h)-h(L-1)));
        R2(i) = u2_2_FMM(i)/exp(1j*kz1v(i)*(sum(h)-h(L-1)));
    end
    
    u2d0_FMM=cat(2,R1,R2,T1,T2);
    
    eta_R = zeros(NN,1);
    eta_T = zeros(NN,1);
    
    for i=1:NN
        if imag(kz1v(i))==0
            eta_R(i) = A1(i,i)*(abs(R2(i)))^2 + B1(i,i)*(abs(R1(i)))^2 +...
                C1(i,i)*( R1(i)*conj(R2(i))+R2(i)*conj(R1(i)) );
        end
        if imag(kz2v(i))==0
            eta_T(i) = A2(i,i)*(abs(T2(i)))^2 + B2(i,i)*(abs(T1(i)))^2 +...
                C2(i,i)*( T1(i)*conj(T2(i))+T2(i)*conj(T1(i)) );
        end
    end
    
    %{
title = 'plot R1'
[x_full] = PMM_graph_output(ud_FMM, ud_PMM, La, alpha0, beta0, alpha_ref, beta_ref,...
   b_x1, b_x2, N_intervals_x, N_intervals_y, N_basis_x, N_basis_y, Nx, nx, Ny, ny,...
   N_FMM, ax, ay)
    %}