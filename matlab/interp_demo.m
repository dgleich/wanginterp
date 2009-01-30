n=16;
x = linspace(-5,5,n);
y = linspace(-5,5,250);
f = @(x) 1./(1+x.^2); % Runge's function
fx = f(x);
I = Interp1d(x,fx);
fy = I.interp(y);

plot(y,fy,'r-',x,fx,'b.');