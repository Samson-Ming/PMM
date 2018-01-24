function [delta_lambda_new,delta_phi_new] =...
    eig_iteration(delta_K,K1,phi0,delta_phi,lambda0,delta_lambda,N_total_3)

    %step 4
    phi1 = phi0 + delta_phi;
    delta_lambda_new = diag(diag(transpose(phi0)*delta_K*phi1))./diag(diag(transpose(phi0)*phi1));
    lambda1 = lambda0 + delta_lambda_new;
    
    %step 5
    
            E = eye(2*N_total_3,2*N_total_3);
            Fnl = phi0*delta_lambda - delta_K*phi0;
            %delta_phi = zeros(2*N_total_3,2*N_total_3);
            V = zeros(2*N_total_3,2*N_total_3);
            for i=1:2*N_total_3
                D1 = K1 - lambda1(i,i)*E;
                [max_phi,n_max_phi] = max(abs(phi0(:,i)));
                j1 = n_max_phi;
                D1(j1,:) = zeros(1,2*N_total_3);
                D1(:,j1) = zeros(2*N_total_3,1);
                D1(j1,j1) = 1;
                Fnl(j1,:) = zeros(1,2*N_total_3);
                V(:,i)=D1\Fnl(:,i);
                V(j1,i) = phi0(j1,i);
            end
            
            %step 6
            ksi = 2*diag(diag(transpose(phi0)*V))+diag(diag(transpose(V)*V));
            c = 1 - (1+ksi).^0.5;
            
            %step 7
            delta_phi_new = phi0*(c/(1-c)) + V/(1-c);
            
