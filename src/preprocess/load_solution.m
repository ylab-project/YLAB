function x = load_solution(filename)
x = readmatrix(filename)';
x = reshape(x(:), 1, []);
x = x(isfinite(x));
end

