clc;
clear;
close all;

%% SYSTEM'S DEFINITION

%Number of agents
m = 2;
%Number of state variables
n = 2;
%Overall dimension of the system         
v = m*n;
%Dimension of the dynamic compensator
l = m-1;
%Number of positions iteraction
STEPS = 10;


%State Matrices
A = zeros(n,n);
B = eye(n);

E = [-1  1; 1  -1];                             % Incidence graph matrix

%Check the strongly connected components
GraphE = digraph(E);
%plot(GraphE)
s = conncomp(GraphE);

if s == ones(1,m)
    disp("Graph is strongly connected")
else
    disp("Graph is weakly connected")
end

%% POSITIONS 

% Random position generation
init_pos = randi([-10,10], n,n);
target_pos = randi([-10,10],1,n);
positions = zeros(STEPS*n,n);

% Random position generation 
C = zeros(m,n);
C_tot = zeros(STEPS*m,n);

for i = 1:STEPS
    % Updating positions of drones and the output matrix C
    if (i == 1)
        [C, positions(i:m,:)] = random_positions(init_pos, n, m);
        % Store the value of matrix C
        C_tot(i:m,:) = C;
    else
        [C, positions((1+(i-1)*m):(m+(i-1)*m),:)] = random_positions(positions((1+(i-1)*m):(m+(i-1)*m),:), n, m);
        % Store the value of matrix C
        C_tot((1+(i-1)*m):(m+(i-1)*m),:) = C;
    end
    
    %Check the Jointly Observability
    O = obsv(A,C);

    if n == rank(O) 
        disp("System is Jointly Observable")

        % Definition of matrices for observers

        [H,Kgain] = distributed_observer(A,C,E,n,m);

        [Hdyn,Bbar,Dbar] = decentralized_control(H,C,n,m);  

        B_obs = [ Kgain(1,:) zeros(1,n+l); [zeros(1,n) Kgain(2,:)]-Dbar' -Bbar]';

        obs_dyn = ss(Hdyn,B_obs,eye(v+l),zeros(v+l,2));

    else
        disp("System is not Jointly Observable")
    end
    
end


%% SIMULATIONs

T = 15;
dt = 0.01;
t = 0:dt:T; 

plant = ss(A,B,eye(n),zeros(2,2));
u = [0; 0]*t;
x0 = target_pos';
x = lsim(plant,u,t,x0);

y = C*x';        

z = lsim(obs_dyn, y,t,zeros(5,1));

error1 = x - z(:,1:2);
error2 = x - z(:,3:4);


figure('Name','First Observer(red) and plant(black)')
plot(t,x,'k')
hold on
plot(t,z(:,1:2), 'r')

figure('Name','Second Observer(red), plant(black) and compensator dynamic(green)')
plot(t,x,'k')
hold on
plot(t,z(:,3:4), 'r')
plot(t,z(:,5), 'g')

figure('Name', 'Error of first observer')
plot(t, error1)
grid on

figure('Name', 'Error of second observer')
plot(t, error2)
grid on

fprintf('Target Position: X: %i, Y: %i \n', x(1,1), x(1,2));










