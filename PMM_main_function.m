
function [Rsum,Tsum, M, gammaminus] =...
        PMM_main_function(figure_shape, dispersion, lambda_full, theta_full, phi_full, delta,...
        h, L, N_FMM, epsilon, refIndices, La, tau_x, tau_y, alpha_ref, beta_ref,...
        b_x, b_y, N_basis_x, N_basis_y, N_intervals_x, N_intervals_y, ellipse_parameters,...
        n_points, eta, f1, verbose)
    
    %%%%%%%%%here starts the program
    
    [nx,Nx,N_total_x,N_total_x3] = PMM_number_of_basis_functions(N_intervals_x,N_basis_x);
    [ny,Ny,N_total_y,N_total_y3] = PMM_number_of_basis_functions(N_intervals_y,N_basis_y);
    N_total_3 = N_total_x3*N_total_y3;
    
    %for now
    
    b_x1 = b_x;
    b_x2 = b_y;
    
    eps_total = zeros(N_total_3,N_total_3,5,L);
    mu_total = zeros(N_total_3,N_total_3,5,L);
    
    %first compute coefficients [a] from boundary conditions
    %continuity and periodicity conditions are handled by sparse [a]
    
    if (verbose>5)
        title = 'enter boundary conditions'
    end
    ax = PMM_boundary_conditions(La, tau_x, N_intervals_x, N_basis_x, Nx, nx);
    ay = PMM_boundary_conditions(La, tau_y, N_intervals_y, N_basis_y, Ny, ny);
    if (verbose>5)
        title = 'escape boundary conditions'
    end
    %compute derivative matrices
    if (verbose>5)
        title = 'enter derivatives'
    end
    [Dx, hx] = PMM_new_derivatives(La, N_intervals_x, N_basis_x, nx, Nx, ax, b_x1);
    [Dy, hy] = PMM_new_derivatives(La, N_intervals_y, N_basis_y, ny, Ny, ay, b_x2);
    if (verbose>5)
        title = 'escape derivatives'
    end
    %%%%%%%%%%%%%%%for ellipse%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if strcmp (figure_shape,'ellipse')==1
        if (verbose>5)
            title = 'coordinates and derivatives for ellipse'
        end
        uni=1;
        
        %%%%%%%%%%last right
        [dx_x1,dx_x2,dy_x1,dy_x2] =...
            ellipse_coordinates_and_derivatives(ellipse_parameters,n_points,uni);
        
        if (verbose>5)
            title = 'integrals with metric tensor for eps and mu for ellipse'
        end
        
        
        [int_Ez_sqrt_g_full,int_Dz_unity_full,int_Dx_sqrt_g_full,int_Dy_sqrt_g_full,...
            int_Ex_g_down22_full,int_Ey_g_down12_full,int_Ex_g_down21_full,int_Ey_g_down11_full] =...
            PMM_metric_integral_polyfit_matrices(N_basis_x,N_basis_y,Nx,nx,Ny,ny,...
            N_intervals_x,N_intervals_y,n_points,La,ax,ay,hx,hy,dx_x1,dx_x2,dy_x1,dy_x2,uni,b_x1,b_x2);
        
    end
    
    if strcmp (figure_shape,'ellipse')==1 && strcmp (dispersion,'no')==1
        for nlayer=1:L
            
            [eps_total_t, mu_total_t] =...
                PMM_epsilon_ellipse_matrices(N_basis_x,N_basis_y,Nx,nx,Ny,ny,...
                N_intervals_x,N_intervals_y,La,epsilon(nlayer,:),...
                int_Ez_sqrt_g_full,int_Dz_unity_full,int_Dx_sqrt_g_full,int_Dy_sqrt_g_full,...
                int_Ex_g_down22_full,int_Ey_g_down12_full,int_Ex_g_down21_full,int_Ey_g_down11_full);
            
            eps_total(:,:,:,nlayer) = eps_total_t;
            mu_total(:,:,:,nlayer) = mu_total_t;
            
        end
    end
    
    %%%%%%%%%%%%%%%for rectangle%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if strcmp(figure_shape, 'rectangle')==1
        if (verbose>5)
            title = 'epsilon for rectangle'
        end
        %usual thing that works
        for i=1:L
            [eps_total_t, mu_total_t] =...
                PMM_epsilon_rectangle(N_basis_x,N_basis_y,Nx,nx,Ny,ny,...
                N_intervals_x,N_intervals_y,epsilon(:,:,i));
            eps_total(:,:,:,i) = eps_total_t;
            mu_total(:,:,:,i) = mu_total_t;
        end
        
    end
    if (verbose>5)
        title = 'incident integral for P0, Q0'
    end
    %precise solution that works
    [int_P1_Q1, int_P1_Q2] = incident_integral(La, b_x1, b_x2, alpha_ref, beta_ref,...
        N_basis_x, N_basis_y, N_intervals_x, N_intervals_y, Nx, Ny, nx, ny);
    
    if (verbose>5)
        title = 'derive matrix of transition from PMM to FMM'
    end
    N = N_FMM;
    NN = (2*N_FMM+1)*(2*N_FMM+1);
    
    %precise solution that works
    [fx_coef,fy_coef] = PMM_to_FMM_RT_La05_one_integral(N, NN, La, alpha_ref, beta_ref,...
        b_x1, b_x2, N_intervals_x, N_intervals_y, N_basis_x, N_basis_y, Nx, nx, Ny, ny,...
        ax, ay);
    
    
    
    [Nll,Nlambda_perturb] = size(lambda_full);
    [Ntt,Ntheta_perturb] = size(theta_full);
    [Npp,Nphi] = size(phi_full);
    
    Rsum = zeros(Nlambda_perturb, Ntheta_perturb);
    Tsum = zeros(Nlambda_perturb, Ntheta_perturb);
    gzero = zeros(Nlambda_perturb,Ntheta_perturb);
    gzero_norm = zeros(Nlambda_perturb,Ntheta_perturb);
    gamma_num = zeros(Ntheta_perturb,1);
    gammaminus = zeros(2*N_total_3,L);
    L_EH = zeros(2*N_total_3,2*N_total_3,L,Nlambda_perturb);
    L_EH = zeros(2*N_total_3,2*N_total_3,L,Nlambda_perturb);
    
    n1 = refIndices(1);
    for i_lambda=1:Nlambda_perturb
        for j_theta=1:Ntheta_perturb
            for k_phi=1:Nphi_perturb
                if strcmp (figure_shape,'ellipse')==1 &&...
                        strcmp (dispersion,'yes')==1
                    refIndices_lambda = zeros(1,2);
                    for nlayer=1:L
                        
                        [eps_total_t, mu_total_t] =...
                            PMM_epsilon_ellipse_matrices(N_basis_x,N_basis_y,Nx,nx,Ny,ny,...
                            N_intervals_x,N_intervals_y,La,epsilon(nlayer,:,i_lambda),...
                            int_Ez_sqrt_g_full,int_Dz_unity_full,int_Dx_sqrt_g_full,int_Dy_sqrt_g_full,...
                            int_Ex_g_down22_full,int_Ey_g_down12_full,...
                            int_Ex_g_down21_full,int_Ey_g_down11_full);
                        
                        eps_total(:,:,:,nlayer) = eps_total_t;
                        mu_total(:,:,:,nlayer) = mu_total_t;
                        refIndices_lambda(1) = refIndices(i_lambda,1);
                        refIndices_lambda(2) = refIndices(i_lambda,2);
                        n1 = refIndices_lambda(1);
                    end
                end
                lambda = lambda_full(i_lambda)
                theta = theta_full(j_theta)
                phi = phi_full(k_phi);
                
                [alpha0,beta0,gamma0,k0,Ex0,Ey0] =...
                    PMM_incident_wave_vector_and_field(lambda,theta,phi,delta,n1);
                
                %title = 'enter eigenvalue solver and S-matrix'
                
                if strcmp (dispersion,'no')==1
                    rrefIndices = refIndices;
                else
                    rrefIndices = refIndices_lambda;
                end
                for nlayer=1:L
                    [L_HE(:,:,nlayer,i_lambda), L_EH(:,:,nlayer,i_lambda)]= ...
                        PMM_Maxwell_matrix(alpha_ref, beta_ref, k0, alpha0, beta0,...
                        N_intervals_x, N_intervals_y, N_basis_x, N_basis_y,...
                        Dx, Dy, hx, hy, eps_total(:,:,:,nlayer), mu_total(:,:,:,nlayer));
                end
            end
        end
    end
    
    for i=1:N_lambda_eig
        for j=1:N_theta_eig
            
            [H_1_4,gamma_sqr_1_4]= ...
                PMM_eig_for_Maxwell(L_HE,L_EH);
            
            for i_perturb = -(n_lambda_extra_perturb-1)/2:(n_lambda_extra_perturb-1)/2
                if i_perturb ~=0
                    lambda = lambda_eig(i) + i_perturb*d_lambda_perturb;
                    num_lambda_perturb = (n_lambda_extra_perturb-1)/2 + i_perturb +...
                        (i-1)*n_lambda_extra_perturb;
                end
            end
        end
    end
    
    [H_perturb, gammasqr_perturb] = ...
        PMM_perturbation(Lfull_eig, H_eig, gammasqr_eig, Lfull_perturb
    
    
    [eta_R, eta_T, M,...
        gzero_t,gzero_norm_t,gamma_num_t,gammaminus] =...
        PMM_multi(int_P1_Q1,int_P1_Q2, fx_coef, fy_coef,...
        Ex0, Ey0, alpha0,beta0,gamma0,k0,...
        N_FMM, h, L, rrefIndices, alpha_ref, beta_ref,...
        b_x1, b_x2, N_intervals_x, N_intervals_y, N_basis_x, N_basis_y,...
        Dx, Dy, hx, hy, eps_total, mu_total,verbose);
    
    %we can pack
    %alpha_ref,b_x1,N_intervals_x,N_basis_x,Dx,hx into one
    %x_object and analogous varibles into y_object
    
    %title = 'escape eigenvalue solver and S-matrix'
    
    Rsum(i,j) = sum(eta_R);
    Tsum(i,j) = sum(eta_T);
    gzero(i,j) = gzero_t;
    gzero_norm(i,j) = gzero_norm_t;
    gamma00(j)=gamma0;
    gamma_num(j)=gamma_num_t;
    
end
end
end


figure(2)
theta = theta_full*180/pi;
plot(theta,gamma00,'r',theta,gamma_num,'g',theta,gzero,'m','Linewidth', 2)
%plot(theta,gamma00,'r',theta,gzero,'m','Linewidth', 2)
ylabel('abs(min(kz0-gamma(i)))')
xlabel('theta')
hold off

%{
            figure(3)
            pcolor(lambda_full,theta_full*180/pi,transpose(gzero))
            %pcolor(XI,YI*180/pi,ZI)
            xlabel('lambda for gzero');
            ylabel('theta');
            shading flat
            colorbar
            
            figure(2)
            pcolor(lambda_full,theta_full*180/pi,transpose(gzero_norm))
            %pcolor(XI,YI*180/pi,ZI)
            xlabel('lambda for gzero_norm');
            ylabel('theta');
            shading flat
            colorbar
%}
hold off
if (verbose>5)
    title = 'escape eigenvalue solver and S-matrix'
end
