function [vector, isTransposed] = reshapeRowVector(vector)
  %reshapeRowVector - Reshape to a row vector if necessary.

  [m, n] = size(vector);
  if (m > 1 && n == 1)
    isTransposed = true;
    vector = vector';
  else
    isTransposed = false;
  end
  return
end
