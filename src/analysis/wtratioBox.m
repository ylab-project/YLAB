function [bt, conwt] = wtratioBox(D, t, F, rank)
  %WTRATIOBOX ...
  %   ...

  if nargin == 3
    rank = 2;
  end
  
  % 列ベクトルに整形
  D = D(:);
  t = t(:);
  F = F(:);

  switch rank
    case PRM.COLUMN_RANK_FA
      % FA材
      r = 33*sqrt(235./F);
    case PRM.COLUMN_RANK_FB
      % FB材
      r = 37*sqrt(235./F);
    case PRM.COLUMN_RANK_FC
      % FC材
      r = 48*sqrt(235./F);
    otherwise
      r = 100;
  end

  % 幅厚比
  bt = D./t;
  conwt = bt./r-1;
end
