clear all;close all;clc

N = 16;

M = 4;

X = ones(1, N);

x = zeros(1, N);

n = 1;

    for k=0:1:N-1

        f = exp((1i.*2.*pi.*k.*n)/(N/M));
        
        aux = X(k+1).*f;

        x(n+1) = x(n+1) + ((1/N).*aux);
    
    end



stem(0:1:N-1, real(x))